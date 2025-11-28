#!/usr/bin/env bash
set -euo pipefail

# DockerHub username is always the first argument
DOCKERHUB_USER="$1"
shift

TAG=""
MICROPYTHON=""
ESP_IDF=""

# Parse flags, ignore unknown ones
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --micropython) MICROPYTHON="$2"; shift 2 ;;
    --esp_idf) ESP_IDF="$2"; shift 2 ;;  # only for esp-idf builds
    *) shift 2 ;;  # ignore unknown flags
  esac
done

# Required flags
if [[ -z "$TAG" ]] || [[ -z "$MICROPYTHON" ]]; then
  echo "ERROR: --tag and --micropython are required"
  exit 1
fi

echo "Building container:"
echo "  TAG=$TAG"
echo "  MICROPYTHON=$MICROPYTHON"
[[ -n "$ESP_IDF" ]] && echo "  ESP_IDF=$ESP_IDF"

# Build command
BUILD_ARGS="--build-arg MICROPYTHON_VERSION=$MICROPYTHON"
[[ -n "$ESP_IDF" ]] && BUILD_ARGS="$BUILD_ARGS --build-arg ESP_IDF_VERSION=$ESP_IDF"

docker build $BUILD_ARGS -t "$DOCKERHUB_USER/$PWD:$TAG" .
docker push "$DOCKERHUB_USER/$PWD:$TAG"
