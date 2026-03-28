#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo "Starting dev VM..."
echo "  Project: $PROJECT_DIR"

cd "$SCRIPT_DIR"

# Bring up VM with project mounted
PROJECT_DIR="$PROJECT_DIR" vagrant up

# Run the dev container inside the VM with Docker socket access
vagrant ssh -c "docker run -ti \
  -e TERM=xterm-256color \
  ${ANTHROPIC_API_KEY:+-e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY} \
  -v /project:/work/project \
  -v /var/run/docker.sock:/var/run/docker.sock \
  nemanjan00/dev \
  zsh -ic 'cd project ; tmux'"
