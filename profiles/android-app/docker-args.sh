#!/bin/bash
# Emits extra `docker run` arguments for the android-app profile.
# Called by the launcher (bin/lib/docker-common.sh) when --profile android-app
# is selected. Persists Gradle's caches (downloaded dependencies + wrapper
# distributions) across container runs so builds don't re-download the world.
set -euo pipefail

HOST_GRADLE="${HOME}/.cache/android-app/gradle"
mkdir -p "$HOST_GRADLE"
echo "-v $HOST_GRADLE:/work/.gradle"
