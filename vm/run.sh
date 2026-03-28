#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Claude config directory
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo "Starting dev VM..."
echo "  Project: $PROJECT_DIR"

cd "$SCRIPT_DIR"

# Bring up VM with project and optional Claude config mounted
export PROJECT_DIR
if [ -d "$CLAUDE_CONFIG_DIR" ]; then
  echo "  Claude config: $CLAUDE_CONFIG_DIR"
  export CLAUDE_CONFIG_DIR
fi

vagrant up

# Build docker run command
DOCKER_ARGS="-ti -e TERM=xterm-256color"
DOCKER_ARGS="$DOCKER_ARGS ${ANTHROPIC_API_KEY:+-e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY}"
DOCKER_ARGS="$DOCKER_ARGS -v /project:/work/project"
DOCKER_ARGS="$DOCKER_ARGS -v /var/run/docker.sock:/var/run/docker.sock"

if [ -d "$CLAUDE_CONFIG_DIR" ]; then
  DOCKER_ARGS="$DOCKER_ARGS -v /claude-config:/work/.claude"
fi

vagrant ssh -c "docker run $DOCKER_ARGS nemanjan00/dev zsh -ic 'cd project ; tmux'"
