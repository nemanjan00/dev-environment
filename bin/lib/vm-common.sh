# Shared helpers for the VM launcher (dev-vm). Sourced after common.sh.
# Functions mutate the globals DOCKER_ARGS / PROJECT_DIR and export the env
# vars the Vagrantfile reads (PROJECT_DIR, CLAUDE_CONFIG_DIR, OPENCODE_*).
#
# DOCKER_ARGS is a bash ARRAY. dev_vm_run serializes it into the remote command
# with dev_shq (one quoted token per element), so the `docker run` that executes
# inside the VM is immune to spaces/globs in a path (e.g. a project slug derived
# from a host path containing a space) — the same guarantee the docker path gets
# from "${DOCKER_ARGS[@]}".

# Per-invocation VM id + dotfile path so several VMs run in parallel, plus the
# cleanup trap that destroys the VM on any exit (error or Ctrl-C).
dev_vm_init() {
  PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
  export PROJECT_DIR
  export VM_ID="dev-$(head -c 4 /dev/urandom | xxd -p)"
  export VAGRANT_DOTFILE_PATH="/tmp/vagrant-${VM_ID}"
  trap 'vagrant destroy -f 2>/dev/null || true; rm -rf "$VAGRANT_DOTFILE_PATH"' EXIT

  DOCKER_ARGS=(-ti -e TERM=xterm-256color)
  # The Docker socket here is the VM's daemon (root-on-VM, NOT root-on-host) —
  # that is why this is the stronger isolation boundary and why this mount must
  # NEVER migrate into docker-common.sh, where the daemon is the host's. The
  # matching --group-add is added by dev_vm_resolve_docker_gid after boot.
  DOCKER_ARGS+=(-v /var/run/docker.sock:/var/run/docker.sock)
}

# Resolve the docker group id from inside the booted VM and grant it, so the
# unprivileged container user can talk to the VM's docker socket. Runs AFTER
# `vagrant up` (the socket only exists once the VM is up); the literal gid is
# safe to embed, unlike an in-VM $(stat) that array quoting would neutralize.
dev_vm_resolve_docker_gid() {
  local gid
  gid="$(vagrant ssh -c "stat -c '%g' /var/run/docker.sock" 2>/dev/null | tr -dc '0-9')"
  [ -n "$gid" ] && DOCKER_ARGS+=(--group-add "$gid")
}

# Mount the project: /vagrant when it is the repo root, /project otherwise
# (the Vagrantfile maps the host PROJECT_DIR to /project).
dev_vm_mount_project() {
  local script_dir="$1"
  if [ "$(realpath "$PROJECT_DIR")" = "$(realpath "$script_dir")" ]; then
    VM_PROJECT_SRC="/vagrant"
  else
    VM_PROJECT_SRC="/project"
  fi
  DOCKER_ARGS+=(-v "$VM_PROJECT_SRC:/work/project")
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    DOCKER_ARGS+=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
  fi
}

# Resolve + export CLAUDE_CONFIG_DIR / CLAUDE_AUTH from env or the usual ~ paths.
# The Vagrantfile turns CLAUDE_CONFIG_DIR / OPENCODE_*_DIR into synced folders,
# so these must be exported *before* `vagrant up`.
dev_vm_resolve_claude() {
  # CLAUDE_HOME is the base dir the Claude config is discovered under; defaults
  # to $HOME, --home points it elsewhere. An explicit CLAUDE_CONFIG_DIR /
  # CLAUDE_AUTH in the env still wins over the derived paths.
  local home="${CLAUDE_HOME:-$HOME}"
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "${home}/.claude" ]; then
    CLAUDE_CONFIG_DIR="${home}/.claude"
  fi
  [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "$CLAUDE_CONFIG_DIR" ] && export CLAUDE_CONFIG_DIR

  CLAUDE_AUTH="${CLAUDE_AUTH:-}"
  if [ -z "$CLAUDE_AUTH" ] && [ -f "${home}/.claude.json" ]; then
    CLAUDE_AUTH="${home}/.claude.json"
  fi
}

# Resolve + export opencode config/state dirs (created if absent) so the
# Vagrantfile synced folders exist. State (auth.json, sessions) lives in the
# data dir; config (opencode.json) in the config dir.
dev_vm_resolve_opencode() {
  export OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
  export OPENCODE_DATA_DIR="${OPENCODE_DATA_DIR:-${HOME}/.local/share/opencode}"
  mkdir -p "$OPENCODE_CONFIG_DIR" "$OPENCODE_DATA_DIR"
}

# Copy host credentials into the running VM (after `vagrant up`).
dev_vm_push_auth() {
  if [ -n "${CLAUDE_AUTH:-}" ] && [ -f "$CLAUDE_AUTH" ]; then
    vagrant ssh -c "cat > /tmp/.claude.json" < "$CLAUDE_AUTH"
  fi
  if [ -f "${HOME}/.gitconfig" ]; then
    vagrant ssh -c "cat > /tmp/.gitconfig" < "${HOME}/.gitconfig"
  fi
}

dev_vm_mount_git() {
  if [ -f "${HOME}/.gitconfig" ]; then
    DOCKER_ARGS+=(-v /tmp/.gitconfig:/work/.gitconfig:ro)
  fi
}

# Claude config + per-host project bucket inside the VM (synced at /claude-config).
dev_vm_mount_claude() {
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    DOCKER_ARGS+=(-v /claude-config:/work/.claude)
    local slug
    slug="$(echo "$PROJECT_DIR" | tr / -)"
    mkdir -p "${CLAUDE_CONFIG_DIR}/projects/${slug}"
    DOCKER_ARGS+=(-v "/claude-config/projects/${slug}:/work/.claude/projects/-work-project")
  fi
  if [ -n "${CLAUDE_AUTH:-}" ] && [ -f "$CLAUDE_AUTH" ]; then
    DOCKER_ARGS+=(-v /tmp/.claude.json:/work/.claude.json)
  fi
}

# opencode auth/state, synced into the VM at /opencode-config and /opencode-data.
dev_vm_mount_opencode() {
  DOCKER_ARGS+=(-v /opencode-config:/work/.config/opencode)
  DOCKER_ARGS+=(-v /opencode-data:/work/.local/share/opencode)
}

# Optional Ollama. NOTE: inside the VM, host.docker.internal resolves to the VM
# guest, not your real host — so Ollama must be reachable from the VM (running
# in it, or forwarded). See README. The baked config is still selected here.
dev_vm_enable_ollama() {
  DOCKER_ARGS+=(--add-host=host.docker.internal:host-gateway)
  DOCKER_ARGS+=(-e OPENCODE_CONFIG=/work/opencode-ollama.json)
}

# In-tmux command per agent. Mirrors dev_docker_launch_cmd so the VM agent gets
# the same MCP servers (shell-session-mcp + any profile mcp.d/*.json such as
# reversing's r2) — keep this in parity with the docker path. Passthrough argv is
# quoted per-element; the --mcp-config glob is left unquoted to expand in-container.
dev_vm_launch_cmd() {
  local preset="$1"; shift
  case "$preset" in
    claude)
      printf 'claude --dangerously-skip-permissions --add-dir /work/skills --mcp-config /work/.config/claude/mcp.d/*.json'
      if [ "$#" -gt 0 ]; then printf ' %s' "$(dev_join_cmd "$@")"; fi
      ;;
    opencode)
      printf 'opencode'
      if [ "$#" -gt 0 ]; then printf ' %s' "$(dev_join_cmd "$@")"; fi
      ;;
    shell) : ;;
  esac
}

# Optional .dev/config.json carve-outs inside the VM. Read-only project
# sub-paths work (they live under the already-synced project at $VM_PROJECT_SRC).
# External `mounts:` need a VM synced folder that doesn't exist, so they are
# docker-only here — warn and skip rather than silently dropping them.
dev_vm_apply_config() {
  local proj_host="$1" cfg="$1/.dev/config.json"
  [ -f "$cfg" ] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    echo "dev-vm: .dev/config.json present but jq not found on host; ignoring config" >&2
    return 0
  fi
  if [ "$(jq -r '(.mounts // []) | length' "$cfg" 2>/dev/null)" -gt 0 ] 2>/dev/null; then
    echo "dev-vm: .dev/config.json 'mounts:' are docker-only and ignored under dev-vm (the VM only syncs the project)." >&2
  fi
  local sub
  while read -r sub; do
    [ -n "$sub" ] || continue
    sub="${sub%/}"
    case "$sub" in
      /*|*..*|*[[:space:]]*)
        echo "dev-vm: skipping invalid .dev/config.json readonly carve-out: $sub" >&2
        continue ;;
    esac
    DOCKER_ARGS+=(-v "${VM_PROJECT_SRC}/$sub:/work/project/$sub:ro")
  done < <(jq -r '(.project.readonly // [])[]' "$cfg")
  DOCKER_ARGS+=(-v "${VM_PROJECT_SRC}/.dev:/work/project/.dev:ro")
}

# Run the container inside the VM. DOCKER_ARGS, the image, and the in-container
# command are each shq-serialized so the remote VM shell (busybox ash) parses
# every token exactly as intended — no word-splitting, and an apostrophe in a
# prompt can't break the nested `zsh -ic` / tmux quoting.
dev_vm_run() {
  local image="$1" cmd="$2" inner remote a
  if [ -n "$cmd" ]; then
    inner="cd project ; tmux new-session $(dev_shq "$cmd")"
  else
    inner="cd project ; tmux new-session"
  fi
  remote="docker run"
  for a in "${DOCKER_ARGS[@]}"; do remote="$remote $(dev_shq "$a")"; done
  remote="$remote $(dev_shq "$image") zsh -ic $(dev_shq "$inner")"
  vagrant ssh -c "$remote"
}
