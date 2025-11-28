#!/usr/bin/env bash
set -euo pipefail

TAG=""
MICROPYTHON=""

# Parse flags
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

# Validate required flags
if [[ -z "$TAG" ]]; then
    echo "ERROR: Missing --tag" >&2
    exit 1
fi

if [[ -z "$MICROPYTHON" ]]; then
    echo "ERROR: Missing --micropython" >&2
    exit 1
fi

echo "Building MicroPython container:"
echo "  TAG: $TAG"
echo "  MICROPYTHON: $MICROPYTHON"

docker build \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON" \
  -t "mydockerhubuser/micropython:$TAG" .

docker push "mydockerhubuser/micropython:$TAG"
