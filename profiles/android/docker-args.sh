#!/bin/bash
# Emits extra `docker run` arguments for the android profile.
# Called by bin/claude-docker when --profile android is used.
set -euo pipefail

HOST_CCACHE="${HOME}/.cache/android-ccache"
mkdir -p "$HOST_CCACHE"
echo "-v $HOST_CCACHE:/work/.ccache"
