#!/bin/sh
set -e

# -----------------------------
# Determine service directory
# -----------------------------
DIRECTORY="$1"
shift
DIR_NAME=$(basename "$DIRECTORY")

BUILT=false
PUBLISH=false
TAGS=""
MICROPYTHON_VERSION=""

# -----------------------------
# Parse flags
# -----------------------------
while [ $# -gt 0 ]; do
  case "$1" in
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
    --publish)
      PUBLISH="$2"
      shift 2
      ;;
    *)
      shift 2
      ;;
  esac
done

# -----------------------------
# Validate required fields
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
# Helpers
# -----------------------------
trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# -----------------------------
# Get first tag
# -----------------------------
FIRST_TAG=$(printf '%s\n' "$TAGS" | awk -F',' '{print $1}')
FIRST_TAG=$(trim "$FIRST_TAG")

IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$FIRST_TAG"

# -----------------------------
# Build ONCE
# -----------------------------
echo "============================================================================"
echo "📦 Building Docker image: $IMAGE"
echo "============================================================================"
echo " MicroPython: $MICROPYTHON_VERSION"
echo " Publish:      $PUBLISH"
echo "----------------------------------------------------------------------------"

docker build --rm \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON_VERSION" \
  -t "$IMAGE" \
  "$DIRECTORY"

# -----------------------------
# Tag & push ALL tags
# -----------------------------
if [ "$PUBLISH" = "true" ]; then
  echo "Publishing image to Docker Hub..."

  echo "$TAGS" | tr ',' '\n' | while read tag; do
    tag=$(trim "$tag")

    if [ -z "$tag" ]; then
      continue
    fi

    FULL_IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$tag"

    if [ "$tag" != "$FIRST_TAG" ]; then
      docker tag "$IMAGE" "$FULL_IMAGE"
    fi

    echo "Pushing Docker image: $FULL_IMAGE"
    docker push "$FULL_IMAGE"
  done
else
  echo "Publish disabled; image will not be pushed to Docker Hub."
fi

# -----------------------------
# Update versions.json
# -----------------------------
VERSION_JSON="$DIRECTORY/versions.json"

jq --arg mp "$MICROPYTHON_VERSION" '
  map(if .micropython == $mp then .built = true else . end)
' "$VERSION_JSON" > "$VERSION_JSON.tmp" &&
mv "$VERSION_JSON.tmp" "$VERSION_JSON"

echo "Build completed for $DIR_NAME ($MICROPYTHON_VERSION)"