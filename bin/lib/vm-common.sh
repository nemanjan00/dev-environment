# Shared helpers for the VM launcher (dev-vm). Sourced after common.sh.
# Functions mutate the globals DOCKER_ARGS / PROJECT_DIR and export the env
# vars the Vagrantfile reads (PROJECT_DIR, CLAUDE_CONFIG_DIR, OPENCODE_*).

# Per-invocation VM id + dotfile path so several VMs run in parallel, plus the
# cleanup trap that destroys the VM on any exit (error or Ctrl-C).
dev_vm_init() {
  PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
  export PROJECT_DIR
  export VM_ID="dev-$(head -c 4 /dev/urandom | xxd -p)"
  export VAGRANT_DOTFILE_PATH="/tmp/vagrant-${VM_ID}"
  trap 'vagrant destroy -f 2>/dev/null || true; rm -rf "$VAGRANT_DOTFILE_PATH"' EXIT

  DOCKER_ARGS="-ti -e TERM=xterm-256color"
  DOCKER_ARGS="$DOCKER_ARGS -v /var/run/docker.sock:/var/run/docker.sock --group-add \$(stat -c '%g' /var/run/docker.sock)"
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
  DOCKER_ARGS="$DOCKER_ARGS -v $VM_PROJECT_SRC:/work/project"
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    DOCKER_ARGS="$DOCKER_ARGS -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
  fi
}

# Resolve + export CLAUDE_CONFIG_DIR / CLAUDE_AUTH from env or the usual ~ paths.
# The Vagrantfile turns CLAUDE_CONFIG_DIR / OPENCODE_*_DIR into synced folders,
# so these must be exported *before* `vagrant up`.
dev_vm_resolve_claude() {
  if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "${HOME}/.claude" ]; then
    CLAUDE_CONFIG_DIR="${HOME}/.claude"
  fi
  [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "$CLAUDE_CONFIG_DIR" ] && export CLAUDE_CONFIG_DIR

  CLAUDE_AUTH="${CLAUDE_AUTH:-}"
  if [ -z "$CLAUDE_AUTH" ] && [ -f "${HOME}/.claude.json" ]; then
    CLAUDE_AUTH="${HOME}/.claude.json"
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
    DOCKER_ARGS="$DOCKER_ARGS -v /tmp/.gitconfig:/work/.gitconfig:ro"
  fi
}

# Claude config + per-host project bucket inside the VM (synced at /claude-config).
dev_vm_mount_claude() {
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    DOCKER_ARGS="$DOCKER_ARGS -v /claude-config:/work/.claude"
    local slug
    slug="$(echo "$PROJECT_DIR" | tr / -)"
    mkdir -p "${CLAUDE_CONFIG_DIR}/projects/${slug}"
    DOCKER_ARGS="$DOCKER_ARGS -v /claude-config/projects/${slug}:/work/.claude/projects/-work-project"
  fi
  if [ -n "${CLAUDE_AUTH:-}" ] && [ -f "$CLAUDE_AUTH" ]; then
    DOCKER_ARGS="$DOCKER_ARGS -v /tmp/.claude.json:/work/.claude.json"
  fi
}

# opencode auth/state, synced into the VM at /opencode-config and /opencode-data.
dev_vm_mount_opencode() {
  DOCKER_ARGS="$DOCKER_ARGS -v /opencode-config:/work/.config/opencode"
  DOCKER_ARGS="$DOCKER_ARGS -v /opencode-data:/work/.local/share/opencode"
}

# Optional Ollama. NOTE: inside the VM, host.docker.internal resolves to the VM
# guest, not your real host — so Ollama must be reachable from the VM (running
# in it, or forwarded). See README. The baked config is still selected here.
dev_vm_enable_ollama() {
  DOCKER_ARGS="$DOCKER_ARGS --add-host=host.docker.internal:host-gateway"
  DOCKER_ARGS="$DOCKER_ARGS -e OPENCODE_CONFIG=/work/opencode-ollama.json"
}

# In-tmux command per agent. No --mcp-config here (the VM path never passed it).
dev_vm_launch_cmd() {
  case "$1" in
    claude)   echo "claude --dangerously-skip-permissions --add-dir /work/skills $2" ;;
    opencode) echo "opencode $2" ;;
    shell)    echo "" ;;
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
    DOCKER_ARGS="$DOCKER_ARGS -v ${VM_PROJECT_SRC}/$sub:/work/project/$sub:ro"
  done < <(jq -r '(.project.readonly // [])[]' "$cfg")
  DOCKER_ARGS="$DOCKER_ARGS -v ${VM_PROJECT_SRC}/.dev:/work/project/.dev:ro"
}

dev_vm_run() {
  local image="$1" cmd="$2" tmux
  if [ -n "$cmd" ]; then
    tmux="tmux new-session \"$cmd\""
  else
    tmux="tmux new-session"
  fi
  vagrant ssh -c "docker run $DOCKER_ARGS $image zsh -ic 'cd project ; $tmux'"
}
