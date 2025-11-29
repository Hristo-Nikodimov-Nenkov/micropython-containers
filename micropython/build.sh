#!/bin/bash
set -e

# -----------------------------
# Determine service directory
# -----------------------------
DIRECTORY=$(pwd)
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
# Validate required properties
# -----------------------------
if [[ -z "$MICROPYTHON_VERSION" ]]; then
  echo "Missing required property in versions.json (micropython)."
  exit 2
fi

if [[ -z "$TAG" ]]; then
  echo "Missing required property in versions.json (tag)."
  exit 3
fi

# -----------------------------
# Build and push Docker image
# -----------------------------
echo "Building Docker image: $DOCKERHUB_USERNAME/$DIR_NAME:$TAG"
docker build --rm \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON_VERSION" \
  -t "$DOCKERHUB_USERNAME/$DIR_NAME:$TAG" \
  "$DIRECTORY"

echo "Pushing Docker image: $DOCKERHUB_USERNAME/$DIR_NAME:$TAG"
docker push "$DOCKERHUB_USERNAME/$DIR_NAME:$TAG"

# -----------------------------
# Update versions.json "built": true
# -----------------------------
VERSION_JSON="$DIRECTORY/versions.json"

jq "map(if .micropython == \"$MICROPYTHON_VERSION\" and .tag == \"$TAG\" then .built = true else . end)" \
  "$VERSION_JSON" > "$VERSION_JSON.tmp" && mv "$VERSION_JSON.tmp" "$VERSION_JSON"

echo "Build and push completed for $DOCKERHUB_USERNAME/$DIR_NAME:$TAG (built=true)"