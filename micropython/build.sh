#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────────
# Positional argument 1 = DockerHub username
# ────────────────────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
    echo "ERROR: Missing DockerHub username (first parameter)" >&2
    echo "Usage: $0 <dockerhub-username> --tag <value> --micropython <value>"
    exit 1
fi

DOCKER_USER="$1"
shift 1   # Remove username, leave only flags

TAG=""
MICROPYTHON=""

# ────────────────────────────────────────────────────────────────
# Parse flags
# ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)
            TAG="$2"; shift 2 ;;
        --micropython)
            MICROPYTHON="$2"; shift 2 ;;
        *)
            echo "Unknown flag: $1" >&2
            exit 1 ;;
    esac
done

# ────────────────────────────────────────────────────────────────
# Validate required flags
# ────────────────────────────────────────────────────────────────
if [[ -z "$TAG" ]]; then
    echo "ERROR: Missing --tag" >&2
    exit 1
fi

if [[ -z "$MICROPYTHON" ]]; then
    echo "ERROR: Missing --micropython" >&2
    exit 1
fi

echo "Building MicroPython container:"
echo "  DockerHub user: $DOCKER_USER"
echo "  TAG:            $TAG"
echo "  MICROPYTHON:    $MICROPYTHON"

# ────────────────────────────────────────────────────────────────
# Docker build + push
# ────────────────────────────────────────────────────────────────
docker build \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON" \
  -t "$DOCKER_USER/micropython:$TAG" .

docker push "$DOCKER_USER/micropython:$TAG"