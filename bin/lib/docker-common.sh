# Shared helpers for the local-Docker launcher (dev-docker). Sourced after
# common.sh. Functions mutate the globals DOCKER_ARGS / INIT_CMDS /
# TMPDIR_CONFIG / PROJECT_DIR — shell's idiom for "module state".
#
# DOCKER_ARGS is a bash ARRAY and is always expanded as "${DOCKER_ARGS[@]}", so
# every element survives intact — a project path, $HOME, or a --mount source
# containing spaces or glob characters is passed to `docker run` as one argv
# entry rather than being word-split.

# Base docker args: throwaway container, project mount, host-path display for
# the tmux status line, API-key passthrough, and a temp dir for config files
# (single-file bind mounts break on macOS when the file is replaced).
dev_docker_init() {
  PROJECT_DIR="$(pwd)"
  DOCKER_ARGS=(-ti --rm --pull always -e TERM=xterm-256color)
  DOCKER_ARGS+=(-v "$PROJECT_DIR:/work/project")

  local disp="$PROJECT_DIR"
  case "$PROJECT_DIR" in
    "$HOME") disp="~" ;;
    "$HOME"/*) disp="~${PROJECT_DIR#$HOME}" ;;
  esac
  DOCKER_ARGS+=(-e "HOST_PROJECT_DIR=$disp")

  [ -n "${ANTHROPIC_API_KEY:-}" ] && DOCKER_ARGS+=(-e ANTHROPIC_API_KEY)

  TMPDIR_CONFIG="$(mktemp -d /tmp/dev-docker.XXXXXX)"
  trap 'rm -rf "$TMPDIR_CONFIG"' EXIT
  DOCKER_ARGS+=(-v "$TMPDIR_CONFIG:/tmp/claude-config")
  INIT_CMDS=""
}

dev_docker_host_network() {
  # SECURITY: --network host removes network isolation — the unleashed agent can
  # then reach every service bound to the host's loopback/LAN (localhost-only
  # databases, admin UIs, metadata endpoints). Opt-in only; see README.
  DOCKER_ARGS+=(--network host)
}

dev_docker_mount_git() {
  if [ -f "${HOME}/.gitconfig" ]; then
    # Copied in (not bind-mounted), so host edits aren't reflected and the
    # container cannot write back. The agent CAN read it, so any [credential]
    # helper / core.sshCommand in it is visible inside the sandbox.
    cp "${HOME}/.gitconfig" "$TMPDIR_CONFIG/gitconfig"
    INIT_CMDS="$INIT_CMDS ln -sf /tmp/claude-config/gitconfig /work/.gitconfig ;"
  fi
}

# Anthropic auth + Claude config: OAuth creds, the ~/.claude dir (settings,
# memory, commands), and a per-host-path project bucket so each host project
# keeps its own memory/sessions while the container always sees -work-project.
#
# SECURITY / TRUST BOUNDARY: ~/.claude is mounted read-WRITE because Claude Code
# writes runtime state there (todos, shell snapshots, statsig, settings the user
# asks the agent to change). That means the untrusted agent can also read every
# other project's memory under projects/* and edit settings.json — whose hooks
# execute on the HOST the next time you run Claude outside the sandbox. We cannot
# safely lock this to read-only without breaking the agent's legitimate writes,
# so it is a documented trust boundary (see README "What gets mounted"): treat
# anything reachable from ~/.claude as exposed to the sandbox. The one host-code
# vector we DO neutralize is global mcpServers injection via ~/.claude.json — see
# dev_docker_persist_oauth.
dev_docker_mount_claude() {
  if [ -f "${HOME}/.claude.json" ]; then
    cp "${HOME}/.claude.json" "$TMPDIR_CONFIG/claude.json"
    INIT_CMDS="$INIT_CMDS ln -sf /tmp/claude-config/claude.json /work/.claude.json ;"
  fi
  if [ -d "${HOME}/.claude" ]; then
    DOCKER_ARGS+=(-v "${HOME}/.claude:/work/.claude")
    # Also mount at the host's absolute path so plugin entries that record
    # absolute paths resolve inside the container without rewriting.
    if [ "${HOME}/.claude" != "/work/.claude" ]; then
      DOCKER_ARGS+=(-v "${HOME}/.claude:${HOME}/.claude")
    fi
    local slug bucket
    slug="$(echo "$PROJECT_DIR" | tr / -)"
    bucket="${HOME}/.claude/projects/${slug}"
    mkdir -p "$bucket"
    DOCKER_ARGS+=(-v "$bucket:/work/.claude/projects/-work-project")
  fi
}

# opencode auth + state. opencode keeps credentials and sessions under
# ~/.config/opencode and ~/.local/share/opencode; bind both from the host
# (created if absent) so logins survive the throwaway container.
dev_docker_mount_opencode() {
  local cfg="${HOME}/.config/opencode" data="${HOME}/.local/share/opencode"
  mkdir -p "$cfg" "$data"
  DOCKER_ARGS+=(-v "$cfg:/work/.config/opencode" -v "$data:/work/.local/share/opencode")
}

# Optional: point opencode at the host's Ollama. The container reaches the host
# over host.docker.internal (mapped explicitly for Linux, where it is not
# automatic). The provider config is baked at /work/opencode-ollama.json —
# outside every mounted dir so it is never shadowed — and selected via
# OPENCODE_CONFIG, which opencode *merges* over any user opencode.json.
dev_docker_enable_ollama() {
  DOCKER_ARGS+=(--add-host=host.docker.internal:host-gateway)
  DOCKER_ARGS+=(-e OPENCODE_CONFIG=/work/opencode-ollama.json)
}

# Profile hook: profiles/<name>/docker-args.sh emits extra docker args on stdout
# as whitespace-separated tokens. They are split into array elements (the hook's
# documented contract is "emit docker args"; a token must not itself contain a
# space).
dev_docker_apply_profile_hook() {
  local hook="$1/profiles/$2/docker-args.sh"
  if [ -x "$hook" ]; then
    local out
    out="$("$hook")"
    # shellcheck disable=SC2206 # intentional split of the hook's arg tokens
    [ -n "$out" ] && DOCKER_ARGS+=($out)
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
  # Expand a leading ~ (docker does not; CLI ~ is already expanded by the shell,
  # but a ~ coming from .dev/config.json is literal).
  case "$src" in
    "~")   src="$HOME" ;;
    "~/"*) src="$HOME/${src#\~/}" ;;
  esac
  case "${#f[@]}" in
    1) dst="$src"; mode="rw" ;;
    2) if [ "${f[1]}" = "ro" ] || [ "${f[1]}" = "rw" ]; then dst="$src"; mode="${f[1]}"; else dst="${f[1]}"; mode="rw"; fi ;;
    *) dst="${f[1]}"; mode="${f[2]}" ;;
  esac
  if [ "$mode" = "ro" ]; then
    DOCKER_ARGS+=(-v "$src:$dst:ro")
  else
    DOCKER_ARGS+=(-v "$src:$dst")
  fi
}

# Refuse a mount SOURCE that resolves to a host credential store, the home-dir
# root, or a system root. .dev/config.json ships INSIDE the project and the agent
# can write it, so a malicious/compromised repo (or the agent priming the next
# launch) must not be able to bind ~/.ssh & co. into the sandbox. Returns 0 ok,
# 1 rejected (with a warning). Applied to config-sourced mounts only — an
# explicit --mount on the CLI is the user's own trusted choice.
dev_docker_safe_mount_src() {
  local src="$1" real
  case "$src" in
    "~")   src="$HOME" ;;
    "~/"*) src="$HOME/${src#\~/}" ;;
  esac
  real="$(cd "$src" 2>/dev/null && pwd -P || printf '%s' "$src")"
  case "$real" in
    "$HOME"|"$HOME"/.ssh|"$HOME"/.ssh/*|"$HOME"/.aws|"$HOME"/.aws/*|"$HOME"/.gnupg|"$HOME"/.gnupg/*|"$HOME"/.config/gh|"$HOME"/.config/gh/*|"$HOME"/.config/op|"$HOME"/.config/op/*|/|/etc|/etc/*|/root|/root/*)
      echo "dev-docker: refusing .dev/config.json mount of sensitive host path: $src" >&2
      return 1 ;;
  esac
  return 0
}

# Optional .dev/config.json in the project root: extra mounts + read-only
# carve-outs. Parsed with jq (the project's documented JSON tool). Absent file
# (or absent jq) -> no-op, so the default sandbox is unchanged. Read-only
# carve-outs are DIRECTORIES (file-level bind permissions don't hold on macOS).
# The config lives in a .dev/ DIRECTORY precisely so we can lock it: re-mounting
# the whole dir :ro works on macOS (a single-file :ro mount does not), so the
# sandboxed agent can't loosen its own sandbox for the next launch.
#
# Because this file is attacker-influenceable (it ships in the repo and the agent
# can write it), config-sourced `mounts:` are screened against a sensitive-path
# denylist, and `project.readonly` carve-outs are validated to stay inside the
# project tree (no absolute paths, no `..`, no whitespace).
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
    dev_docker_safe_mount_src "$path" || continue
    [ -n "$at" ] || at="$path"
    local spec="$path:$at"
    [ "$mode" = "ro" ] && spec="$spec:ro"
    dev_docker_add_mount "$spec"
  done < <(jq -r '(.mounts // [])[] | [.path, (.at // ""), (.mode // "rw")] | @tsv' "$cfg")

  local sub
  while read -r sub; do
    [ -n "$sub" ] || continue
    sub="${sub%/}"
    case "$sub" in
      /*|*..*|*[[:space:]]*)
        echo "dev-docker: skipping invalid .dev/config.json readonly carve-out: $sub" >&2
        continue ;;
    esac
    DOCKER_ARGS+=(-v "$proj/$sub:/work/project/$sub:ro")
  done < <(jq -r '(.project.readonly // [])[]' "$cfg")

  # Lock the whole .dev/ dir read-only (dir-level → enforced on macOS too).
  DOCKER_ARGS+=(-v "$proj/.dev:/work/project/.dev:ro")
}

# The in-tmux command for an agent. `shell` prints nothing → bare tmux session.
# Passthrough argv ($2..$N) is quoted per-element so spaces/quotes survive; the
# --mcp-config glob is left UNquoted so the container shell expands it.
dev_docker_launch_cmd() {
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

# Run the container. No exec — we copy OAuth back after exit. The agent command
# ($cmd) is wrapped with dev_shq so an apostrophe in a prompt can't break the
# `zsh -ic` / tmux quoting; the glob inside it still expands in tmux's shell.
# An empty $cmd opens a bare tmux session.
dev_docker_run() {
  local image="$1" cmd="$2" inner
  if [ -n "$cmd" ]; then
    inner="$INIT_CMDS cd project ; tmux new-session $(dev_shq "$cmd")"
  else
    inner="$INIT_CMDS cd project ; tmux new-session"
  fi
  docker run "${DOCKER_ARGS[@]}" "$image" zsh -ic "$inner"
}

# Persist refreshed OAuth credentials back to the host after the container exits.
# SECURITY: the agent edited the temp copy, not the host file, so the host
# ~/.claude.json is still the pre-launch original here. We persist the agent's
# changes (refreshed tokens, etc.) but force the global `mcpServers` back to the
# host's pre-launch value (or drop it if there was none) — a global stdio MCP
# server injected here would run as a HOST command the next time the user
# launches Claude outside the sandbox. Falls back to a full copy when jq is
# missing or either file isn't valid JSON, so token refresh never regresses.
dev_docker_persist_oauth() {
  local updated="$TMPDIR_CONFIG/claude.json" orig="${HOME}/.claude.json"
  [ -f "$updated" ] || return 0
  if command -v jq >/dev/null 2>&1 && [ -f "$orig" ] \
     && jq -e . "$updated" >/dev/null 2>&1 && jq -e . "$orig" >/dev/null 2>&1; then
    local merged="$TMPDIR_CONFIG/claude.merged.json"
    if jq -s '
        .[0] as $c | .[1] as $h
        | ($c + (if ($h | has("mcpServers")) then {mcpServers: $h.mcpServers} else {} end))
        | if ($h | has("mcpServers") | not) then del(.mcpServers) else . end
      ' "$updated" "$orig" > "$merged" 2>/dev/null; then
      cp "$merged" "$orig"
      return 0
    fi
  fi
  cp "$updated" "$orig"
}
