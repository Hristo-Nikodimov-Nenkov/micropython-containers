#!/usr/bin/env bash
set -euo pipefail

# DockerHub username is always the first argument
DOCKERHUB_USER="$1"
shift

TAG=""
MICROPYTHON=""
ESP_IDF=""
DIR_NAME=$(basename "$PWD")  # Use basename for Docker image name

# Parse flags, ignore unknown ones
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --micropython) MICROPYTHON="$2"; shift 2 ;;
    --esp_idf) ESP_IDF="$2"; shift 2 ;;  # optional, only for esp-idf images
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

# Build arguments
BUILD_ARGS="--build-arg MICROPYTHON_VERSION=$MICROPYTHON"
[[ -n "$ESP_IDF" ]] && BUILD_ARGS="$BUILD_ARGS --build-arg ESP_IDF_VERSION=$ESP_IDF"

# Build and push
docker build $BUILD_ARGS -t "$DOCKERHUB_USER/$DIR_NAME:$TAG" .
docker push "$DOCKERHUB_USER/$DIR_NAME:$TAG"
