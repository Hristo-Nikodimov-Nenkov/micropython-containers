#!/bin/sh
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
ESP_IDF_VERSION=""

# -----------------------------
# Parse flags from CLI
# -----------------------------
while [ $# -gt 0 ]; do
  key="$1"
  case "$key" in
    --tags)
      TAGS="$2"
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

if [ -z "$ESP_IDF_VERSION" ]; then
  echo "Missing required property in versions.json (esp_idf)."
  exit 3
fi

if [ -z "$TAGS" ]; then
  echo "Missing required property in versions.json (tags)."
  exit 4
fi

# -----------------------------
# Split & trim tags (POSIX sh)
# -----------------------------
OLD_IFS="$IFS"
IFS=','
set -- $TAGS
IFS="$OLD_IFS"

# Trim first tag
FIRST_TAG=$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

BASE_IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$FIRST_TAG"

if [ -z "$FIRST_TAG" ]; then
  echo "ERROR: Failed to determine first tag from TAGS=$TAGS"
  exit 5
fi

# -----------------------------
# Build image ONCE (first tag)
# -----------------------------
echo "📦 Building Docker image: $BASE_IMAGE"
docker build --rm \
  --build-arg MICROPYTHON_VERSION="$MICROPYTHON_VERSION" \
  --build-arg ESP_IDF_VERSION="$ESP_IDF_VERSION" \
  -t "$BASE_IMAGE" \
  "$DIRECTORY"

# -----------------------------
# Tag & push ALL tags
# -----------------------------
echo "$TAGS" | tr ',' '\n' | while read tag; do
  tag=$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$tag"

  if [ "$tag" != "$FIRST_TAG" ]; then
    docker tag "$BASE_IMAGE" "$IMAGE"
  fi

  echo "🚀 Pushing Docker image: $IMAGE"
  docker push "$IMAGE"
done

# -----------------------------
# Cleanup local images
# -----------------------------
echo "$TAGS" | tr ',' '\n' | while read tag; do
  tag=$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  docker rmi -f "$DOCKERHUB_USERNAME/$DIR_NAME:$tag" || true

  BASE_IMAGE="rav3nh01m/micropython:${MICROPYTHON_VERSION}"
  echo "Removing base image: $BASE_IMAGE"
  docker rmi -f "$BASE_IMAGE" || true
done

# -----------------------------
# Update versions.json
# -----------------------------
VERSION_JSON="$DIRECTORY/versions.json"
TMP_JSON="$VERSION_JSON.tmp"

jq --arg mp "$MICROPYTHON_VERSION" '
  map(if .micropython == $mp then .built = true else . end)
' "$VERSION_JSON" > "$TMP_JSON" && mv "$TMP_JSON" "$VERSION_JSON"

echo "✔ Completed: $DIR_NAME (micropython=$MICROPYTHON_VERSION, esp-idf=$ESP_IDF_VERSION, built=$BUILT)"
