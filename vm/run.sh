#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo "Starting dev VM..."
echo "  Project: $PROJECT_DIR"

cd "$SCRIPT_DIR"

# Bring up VM with project and optional Claude config mounted
export PROJECT_DIR
if [ -n "${CLAUDE_CONFIG_DIR:-}" ] && [ -d "$CLAUDE_CONFIG_DIR" ]; then
  echo "  Claude config: $CLAUDE_CONFIG_DIR"
  export CLAUDE_CONFIG_DIR
fi

vagrant up

# Copy Claude OAuth credentials into VM if specified
CLAUDE_AUTH="${CLAUDE_AUTH:-}"
if [ -n "$CLAUDE_AUTH" ] && [ -f "$CLAUDE_AUTH" ]; then
  echo "  Claude auth: $CLAUDE_AUTH"
  vagrant ssh -c "cat > /tmp/.claude.json" < "$CLAUDE_AUTH"
fi

# Copy git config into VM if available
if [ -f "${HOME}/.gitconfig" ]; then
  echo "  Git config: ${HOME}/.gitconfig"
  vagrant ssh -c "cat > /tmp/.gitconfig" < "${HOME}/.gitconfig"
fi

# Build docker run command
DOCKER_ARGS="-ti -e TERM=xterm-256color"
DOCKER_ARGS="$DOCKER_ARGS ${ANTHROPIC_API_KEY:+-e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY}"
DOCKER_ARGS="$DOCKER_ARGS -v /var/run/docker.sock:/var/run/docker.sock"

# Mount project — use /vagrant if PROJECT_DIR is the same as SCRIPT_DIR
if [ "$(realpath "$PROJECT_DIR")" = "$(realpath "$SCRIPT_DIR")" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v /vagrant:/work/project"
else
  DOCKER_ARGS="$DOCKER_ARGS -v /project:/work/project"
fi

if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v /claude-config:/work/.claude"
fi

if [ -n "${CLAUDE_AUTH:-}" ] && [ -f "$CLAUDE_AUTH" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v /tmp/.claude.json:/work/.claude.json"
fi

if [ -f "${HOME}/.gitconfig" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v /tmp/.gitconfig:/work/.gitconfig:ro"
fi

vagrant ssh -c "docker run $DOCKER_ARGS nemanjan00/dev zsh -ic 'cd project ; tmux'"
