#!/usr/bin/env bash
# Runs switch/build.sh inside ghcr.io/danfromtico/switch-dev-legacy-vulkan (MIT): devkitPro's
# Linux toolchain (devkitA64, libnx, switch-sdl2) plus mesa-switch's NVK. Mark OK'd pulling it
# for the cloud Switch builds (2026-11-03). The repository is mounted at the same path inside.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-ghcr.io/danfromtico/switch-dev-legacy-vulkan:latest}"
exec docker run --rm -v "$REPO:$REPO" -w "$REPO" -e JOBS -e PARTS "$IMAGE" \
    bash -c "git config --global --add safe.directory '*' && bash switch/build.sh"
