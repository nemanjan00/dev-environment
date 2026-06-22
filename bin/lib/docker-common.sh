# Shared helpers for the local-Docker launcher (dev-docker). Sourced after
# common.sh. Functions mutate the globals DOCKER_ARGS / INIT_CMDS /
# TMPDIR_CONFIG / PROJECT_DIR — shell's idiom for "module state".

# Base docker args: throwaway container, project mount, host-path display for
# the tmux status line, API-key passthrough, and a temp dir for config files
# (single-file bind mounts break on macOS when the file is replaced).
dev_docker_init() {
  PROJECT_DIR="$(pwd)"
  DOCKER_ARGS="-ti --rm --pull always -e TERM=xterm-256color"
  DOCKER_ARGS="$DOCKER_ARGS -v $PROJECT_DIR:/work/project"

  local disp="$PROJECT_DIR"
  case "$PROJECT_DIR" in
    "$HOME") disp="~" ;;
    "$HOME"/*) disp="~${PROJECT_DIR#$HOME}" ;;
  esac
  DOCKER_ARGS="$DOCKER_ARGS -e HOST_PROJECT_DIR=$disp"

  [ -n "${ANTHROPIC_API_KEY:-}" ] && DOCKER_ARGS="$DOCKER_ARGS -e ANTHROPIC_API_KEY"

  TMPDIR_CONFIG="$(mktemp -d /tmp/dev-docker.XXXXXX)"
  trap 'rm -rf "$TMPDIR_CONFIG"' EXIT
  DOCKER_ARGS="$DOCKER_ARGS -v $TMPDIR_CONFIG:/tmp/claude-config"
  INIT_CMDS=""
}

dev_docker_host_network() {
  DOCKER_ARGS="$DOCKER_ARGS --network host"
}

dev_docker_mount_git() {
  if [ -f "${HOME}/.gitconfig" ]; then
    cp "${HOME}/.gitconfig" "$TMPDIR_CONFIG/gitconfig"
    INIT_CMDS="$INIT_CMDS ln -sf /tmp/claude-config/gitconfig /work/.gitconfig ;"
  fi
}

# Anthropic auth + Claude config: OAuth creds, the ~/.claude dir (settings,
# memory, commands), and a per-host-path project bucket so each host project
# keeps its own memory/sessions while the container always sees -work-project.
dev_docker_mount_claude() {
  if [ -f "${HOME}/.claude.json" ]; then
    cp "${HOME}/.claude.json" "$TMPDIR_CONFIG/claude.json"
    INIT_CMDS="$INIT_CMDS ln -sf /tmp/claude-config/claude.json /work/.claude.json ;"
  fi
  if [ -d "${HOME}/.claude" ]; then
    DOCKER_ARGS="$DOCKER_ARGS -v ${HOME}/.claude:/work/.claude"
    # Also mount at the host's absolute path so plugin entries that record
    # absolute paths resolve inside the container without rewriting.
    if [ "${HOME}/.claude" != "/work/.claude" ]; then
      DOCKER_ARGS="$DOCKER_ARGS -v ${HOME}/.claude:${HOME}/.claude"
    fi
    local slug bucket
    slug="$(echo "$PROJECT_DIR" | tr / -)"
    bucket="${HOME}/.claude/projects/${slug}"
    mkdir -p "$bucket"
    DOCKER_ARGS="$DOCKER_ARGS -v $bucket:/work/.claude/projects/-work-project"
  fi
}

# opencode auth + state. opencode keeps credentials and sessions under
# ~/.config/opencode and ~/.local/share/opencode; bind both from the host
# (created if absent) so logins survive the throwaway container.
dev_docker_mount_opencode() {
  local cfg="${HOME}/.config/opencode" data="${HOME}/.local/share/opencode"
  mkdir -p "$cfg" "$data"
  DOCKER_ARGS="$DOCKER_ARGS -v $cfg:/work/.config/opencode -v $data:/work/.local/share/opencode"
}

# Optional: point opencode at the host's Ollama. The container reaches the host
# over host.docker.internal (mapped explicitly for Linux, where it is not
# automatic). The provider config is baked at /work/opencode-ollama.json —
# outside every mounted dir so it is never shadowed — and selected via
# OPENCODE_CONFIG, which opencode *merges* over any user opencode.json.
dev_docker_enable_ollama() {
  DOCKER_ARGS="$DOCKER_ARGS --add-host=host.docker.internal:host-gateway"
  DOCKER_ARGS="$DOCKER_ARGS -e OPENCODE_CONFIG=/work/opencode-ollama.json"
}

# Profile hook: profiles/<name>/docker-args.sh emits extra docker args on stdout.
dev_docker_apply_profile_hook() {
  local hook="$1/profiles/$2/docker-args.sh"
  if [ -x "$hook" ]; then
    DOCKER_ARGS="$DOCKER_ARGS $("$hook")"
  fi
}

# Append an arbitrary bind mount. Spec: SRC[:DST][:ro] (SRC may use ~).
#   SRC          -> SRC:SRC      (rw, same path in container)
#   SRC:DST       -> DST          (rw)
#   SRC:ro        -> SRC:SRC      (ro)
#   SRC:DST:ro    -> DST          (ro)
dev_docker_add_mount() {
  local spec="$1"
  local -a f
  IFS=':' read -r -a f <<< "$spec"
  local src="${f[0]}" dst mode
  case "${#f[@]}" in
    1) dst="$src"; mode="rw" ;;
    2) if [ "${f[1]}" = "ro" ] || [ "${f[1]}" = "rw" ]; then dst="$src"; mode="${f[1]}"; else dst="${f[1]}"; mode="rw"; fi ;;
    *) dst="${f[1]}"; mode="${f[2]}" ;;
  esac
  if [ "$mode" = "ro" ]; then
    DOCKER_ARGS="$DOCKER_ARGS -v $src:$dst:ro"
  else
    DOCKER_ARGS="$DOCKER_ARGS -v $src:$dst"
  fi
}

# Optional .dev/config.json in the project root: extra mounts + read-only
# carve-outs. Parsed with jq (the project's documented JSON tool). Absent file
# (or absent jq) -> no-op, so the default sandbox is unchanged. Read-only
# carve-outs are DIRECTORIES (file-level bind permissions don't hold on macOS).
# The config lives in a .dev/ DIRECTORY precisely so we can lock it: re-mounting
# the whole dir :ro works on macOS (a single-file :ro mount does not), so the
# sandboxed agent can't loosen its own sandbox for the next launch.
#
# Schema (.dev/config.json):
#   { "mounts":  [ { "path": "~/x", "at": "/work/x", "mode": "ro" } ],
#     "project": { "readonly": [ "tests", "migrations" ] } }
dev_docker_apply_config() {
  local proj="$1" cfg="$1/.dev/config.json"
  [ -f "$cfg" ] || return 0
  if ! command -v jq >/dev/null 2>&1; then
    echo "dev-docker: .dev/config.json present but jq not found on host; ignoring config" >&2
    return 0
  fi

  local path at mode
  while IFS=$'\t' read -r path at mode; do
    [ -n "$path" ] || continue
    [ -n "$at" ] || at="$path"
    local spec="$path:$at"
    [ "$mode" = "ro" ] && spec="$spec:ro"
    dev_docker_add_mount "$spec"
  done < <(jq -r '(.mounts // [])[] | [.path, (.at // ""), (.mode // "rw")] | @tsv' "$cfg")

  local sub
  while read -r sub; do
    [ -n "$sub" ] || continue
    sub="${sub%/}"
    DOCKER_ARGS="$DOCKER_ARGS -v $proj/$sub:/work/project/$sub:ro"
  done < <(jq -r '(.project.readonly // [])[]' "$cfg")

  # Lock the whole .dev/ dir read-only (dir-level → enforced on macOS too).
  DOCKER_ARGS="$DOCKER_ARGS -v $proj/.dev:/work/project/.dev:ro"
}

# The in-tmux command for an agent. `shell` returns empty → bare tmux session.
dev_docker_launch_cmd() {
  case "$1" in
    claude)   echo "claude --dangerously-skip-permissions --add-dir /work/skills --mcp-config /work/.config/claude/mcp.d/*.json $2" ;;
    opencode) echo "opencode $2" ;;
    shell)    echo "" ;;
  esac
}

# Run the container. No exec — we copy OAuth back after exit. mcp.d/*.json
# expands inside the container's zsh. --add-dir /work/skills auto-loads
# build-time skills. An empty $cmd opens a bare tmux session.
dev_docker_run() {
  local image="$1" cmd="$2"
  if [ -n "$cmd" ]; then
    docker run $DOCKER_ARGS "$image" zsh -ic "$INIT_CMDS cd project ; tmux new-session '$cmd'"
  else
    docker run $DOCKER_ARGS "$image" zsh -ic "$INIT_CMDS cd project ; tmux new-session"
  fi
}

# Persist refreshed OAuth credentials back to the host after the container exits.
dev_docker_persist_oauth() {
  if [ -f "$TMPDIR_CONFIG/claude.json" ]; then
    cp "$TMPDIR_CONFIG/claude.json" "${HOME}/.claude.json"
  fi
}
