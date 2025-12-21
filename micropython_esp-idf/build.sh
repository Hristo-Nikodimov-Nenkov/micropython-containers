#!/bin/bash
set -e

# -----------------------------
# Determine service directory
# -----------------------------
DIRECTORY="$1"
shift
DIR_NAME=$(basename "$DIRECTORY")

BUILT="false"
TAG=""
MICROPYTHON_VERSION=""

# -----------------------------
# Parse flags from CLI
# -----------------------------
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --tag)
      TAG="$2"
      shift 2
      ;;
    --micropython)
      MICROPYTHON_VERSION="$2"
      shift 2
      ;;
    --esp_idf)
      ESP_IDF_VERSION="$2"
      shift 2
      ;;
    --built)
      BUILT="$2"
      shift 2
      ;;
    *)
      # Ignore unknown flags
      shift 2
      ;;
  esac
done
# -----------------------------
# Validate required fields
# -----------------------------
if [[ -z "$MICROPYTHON_VERSION" ]]; then
  echo "Missing required property in versions.json (micropython)."
  exit 2
fi

if [[ -z "$ESP_IDF_VERSION" ]]; then
  echo "Missing required property in versions.json (esp_idf_version)."
  exit 4
fi

if [[ -z "$TAG" ]]; then
  echo "Missing required property in versions.json (tag)."
  exit 3
fi

# Required args must be included
BUILD_ARGS+=( --build-arg "MICROPYTHON_VERSION=${MICROPYTHON_VERSION}" )
BUILD_ARGS+=( --build-arg "ESP_IDF_VERSION=${ESP_IDF_VERSION}" )

# -----------------------------
# Build and Push
# -----------------------------
echo "📦 Building: $DOCKERHUB_USERNAME/$DIR_NAME:$TAG"
echo "Build args:"
printf '  %s\n' "${BUILD_ARGS[@]}"

docker build --rm \
  "${BUILD_ARGS[@]}" \
  -t "$DOCKERHUB_USERNAME/$DIR_NAME:$TAG" \
  "$DIRECTORY"

docker push "$DOCKERHUB_USERNAME/$DIR_NAME:$TAG"

echo "✔ Completed: $DOCKERHUB_USERNAME/$DIR_NAME:$TAG (built=$BUILT)"
