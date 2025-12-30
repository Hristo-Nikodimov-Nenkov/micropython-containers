#!/bin/bash
set -e

# -----------------------------
# Determine service directory
# -----------------------------
DIRECTORY="$1"
shift
DIR_NAME=$(basename "$DIRECTORY")

BUILT="false"
TAGS=""
MICROPYTHON_VERSION=""

# -----------------------------
# Parse flags from CLI
# -----------------------------
while [ $# -gt 0 ]; do
  key="$1"
  case "$key" in
    --tag|--tags)
      TAGS="$2"
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
      shift 2
      ;;
  esac
done

# -----------------------------
# Validate required properties
# -----------------------------
if [ -z "$MICROPYTHON_VERSION" ]; then
  echo "Missing required property in versions.json (micropython)."
  exit 2
fi

if [ -z "$TAGS" ]; then
  echo "Missing required property in versions.json (tags)."
  exit 3
fi

# -----------------------------
# Split & trim tags
# -----------------------------
IFS=',' read -r -a TAG_ARRAY <<< "$TAGS"

trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# -----------------------------
# Build image ONCE (first tag)
# -----------------------------
FIRST_TAG="$(trim "${TAG_ARRAY[0]}")"
IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$FIRST_TAG"

echo "Building Docker image: $IMAGE"
docker build --rm \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON_VERSION" \
  -t "$IMAGE" \
  "$DIRECTORY"

# -----------------------------
# Tag & push ALL tags
# -----------------------------
for tag in "${TAG_ARRAY[@]}"; do
  tag="$(trim "$tag")"
  FULL_IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$tag"

  if [ "$tag" != "$FIRST_TAG" ]; then
    docker tag "$IMAGE" "$FULL_IMAGE"
  fi

  echo "Pushing Docker image: $FULL_IMAGE"
  docker push "$FULL_IMAGE"
done

# -----------------------------
# Cleanup local images
# -----------------------------
for tag in "${TAG_ARRAY[@]}"; do
  tag="$(trim "$tag")"
  docker rmi -f "$DOCKERHUB_USERNAME/$DIR_NAME:$tag" || true
done

# -----------------------------
# Update versions.json
# -----------------------------
VERSION_JSON="$DIRECTORY/versions.json"

jq --arg mp "$MICROPYTHON_VERSION" '
  map(if .micropython == $mp then .built = true else . end)
' "$VERSION_JSON" > "$VERSION_JSON.tmp" && mv "$VERSION_JSON.tmp" "$VERSION_JSON"

echo "Build and push completed for $DIR_NAME ($MICROPYTHON_VERSION)"
