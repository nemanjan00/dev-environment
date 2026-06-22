# Shared helpers for the dev-* launchers (dev-docker, dev-vm) and their
# compatibility shims. This file is *sourced*, never executed.

# Self-update: fast-forward the wrappers/profiles on launch so everyone runs the
# latest, then re-exec so this very launch uses the new version. Best-effort — a
# missing network, local commits, or a dirty tree all just skip it; a launch is
# never blocked. Opt out with DEV_NO_UPDATE=1. DEV_UPDATED guards the re-exec
# loop. Must run before any container/VM is created so re-exec is safe.
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
