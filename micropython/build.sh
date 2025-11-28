#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <dockerhub_user> [--tag TAG --micropython VERSION ...]"
    exit 1
fi

USER="$1"
shift
FLAGS="$@"

# Extract flags
TAG=$(echo "$FLAGS" | grep -oP '(?<=--tag )"\K[^"]+' || true)
MICROPYTHON=$(echo "$FLAGS" | grep -oP '(?<=--micropython )"\K[^"]+' || true)

echo "Building container:"
echo "  TAG: $TAG"
echo "  MICROPYTHON: $MICROPYTHON"

docker build --build-arg MICROPYTHON_VERSION="$MICROPYTHON" -t "$USER/$(basename "$PWD"):$TAG" .
docker push "$USER/$(basename "$PWD"):$TAG"

# Update versions.json
if [[ -f versions.json ]]; then
    jq --arg tag "$TAG" 'map(if .tag==$tag then .built=true else . end)' versions.json > versions.tmp.json
    mv versions.tmp.json versions.json
    echo "Marked $TAG as built in versions.json"
fi
