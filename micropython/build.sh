#!/bin/bash
set -e

USERNAME="$1"
DIRECTORY="$2"
shift 2  # Remove first two args, rest are flags

DIR_NAME=$(basename "$DIRECTORY")

BUILT="false"

TAG=""
MICROPYTHON_VERSION=""

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
      shift
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
echo "Building Docker image: $USERNAME/$DIR_NAME:$TAG"
docker build --rm \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON_VERSION" \
  -t "$USERNAME/$DIR_NAME:$TAG" \
  "$DIRECTORY"

echo "Pushing Docker image: $USERNAME/$DIR_NAME:$TAG"
docker push "$USERNAME/$DIR_NAME:$TAG"

echo "Build and push completed for $USERNAME/$DIR_NAME:$TAG (built=$BUILT)"
