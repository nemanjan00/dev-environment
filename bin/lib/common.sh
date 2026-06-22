# Shared helpers for the dev-* launchers (dev-docker, dev-vm) and their
# compatibility shims. This file is *sourced*, never executed.

# Portable single-quote shell-quoting: wrap $1 in single quotes, escaping any
# embedded single quote as '\''. Output is ONE safe token for any POSIX shell
# (works on the Alpine VM's busybox ash too, unlike bash's `printf %q`). Used to
# serialize argv across the shell layers the launchers cross (host -> zsh -ic ->
# tmux -> sh, and host -> `vagrant ssh -c` -> VM sh) without word-splitting or
# letting spaces/quotes/globs in a path or prompt break the command.
dev_shq() {
  local s=$1
  # Substitute in an unquoted assignment first: inside "..." the backslashes in
  # the replacement would be taken literally and double-escape the quote.
  s=${s//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

# shq-join argv ($@) into a single space-separated POSIX command line, each
# element quoted exactly once. Empty argv -> empty string.
dev_join_cmd() {
  local out='' a
  for a in "$@"; do out="${out:+$out }$(dev_shq "$a")"; done
  printf '%s' "$out"
}

# Self-update: fast-forward the wrappers/profiles on launch so everyone runs the
# latest, then re-exec so this very launch uses the new version. Best-effort — a
# missing network, local commits, or a dirty tree all just skip it; a launch is
# never blocked. Opt out with DEV_NO_UPDATE=1. DEV_UPDATED guards the re-exec
# loop. Must run before any container/VM is created so re-exec is safe.
#
# TRUST: this fetches and re-execs code from the install clone's git remote on
# the HOST, with your privileges, before any sandbox exists. The install clone
# (~/.dev) must therefore NEVER be bind-mounted into a sandbox — if the agent
# could rewrite the launcher or its `origin` URL, the change would auto-exec on
# the host at the next launch. Set DEV_NO_UPDATE=1 to pin to the checked-out
# version. See README "self-update" for the full trust note.
#
# Call as: dev_self_update "${BASH_SOURCE[0]}" "$@"
dev_self_update() {
  local self="$1"; shift
  [ "${DEV_NO_UPDATE:-0}" = "1" ] && return 0
  [ -n "${DEV_UPDATED:-}" ] && return 0
  local dir
  dir="$(cd "$(dirname "$self")/.." && pwd)"
  [ -d "$dir/.git" ] || return 0

  local before after
  before="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"
  git -C "$dir" pull --ff-only --quiet 2>/dev/null || true
  after="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"
  if [ -n "$before" ] && [ "$before" != "$after" ]; then
    echo "dev-environment: updated to $(git -C "$dir" rev-parse --short HEAD), relaunching..." >&2
    exec env DEV_UPDATED=1 "$self" "$@"
  fi
}
