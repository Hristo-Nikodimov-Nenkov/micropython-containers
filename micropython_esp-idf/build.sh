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
ESP_IDF_VERSION=""
BUILD_ARGS=()

# -----------------------------
# Parse flags from CLI
# -----------------------------
while [[ $# -gt 0 ]]; do
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
if [[ -z "$MICROPYTHON_VERSION" ]]; then
  echo "Missing required property in versions.json (micropython)."
  exit 2
fi

if [[ -z "$ESP_IDF_VERSION" ]]; then
  echo "Missing required property in versions.json (esp_idf)."
  exit 4
fi

if [[ -z "$TAGS" ]]; then
  echo "Missing required property in versions.json (tags)."
  exit 3
fi

# -----------------------------
# Build args
# -----------------------------
BUILD_ARGS+=( --build-arg "MICROPYTHON_VERSION=${MICROPYTHON_VERSION}" )
BUILD_ARGS+=( --build-arg "ESP_IDF_VERSION=${ESP_IDF_VERSION}" )

# -----------------------------
# Split & trim tags
# -----------------------------
IFS=',' read -r -a TAG_ARRAY <<< "$TAGS"

trim() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

FIRST_TAG="$(trim "${TAG_ARRAY[0]}")"
BASE_IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$FIRST_TAG"

# -----------------------------
# Build ONCE
# -----------------------------
echo "📦 Building: $BASE_IMAGE"
echo "Build args:"
printf '  %s\n' "${BUILD_ARGS[@]}"

docker build --rm \
  "${BUILD_ARGS[@]}" \
  -t "$BASE_IMAGE" \
  "$DIRECTORY"

# -----------------------------
# Tag & Push ALL tags
# -----------------------------
for tag in "${TAG_ARRAY[@]}"; do
  tag="$(trim "$tag")"
  IMAGE="$DOCKERHUB_USERNAME/$DIR_NAME:$tag"

  if [[ "$tag" != "$FIRST_TAG" ]]; then
    docker tag "$BASE_IMAGE" "$IMAGE"
  fi

  echo "🚀 Pushing: $IMAGE"
  docker push "$IMAGE"
done

# -----------------------------
# Cleanup local images
# -----------------------------
for tag in "${TAG_ARRAY[@]}"; do
  tag="$(trim "$tag")"
  docker rmi -f "$DOCKERHUB_USERNAME/$DIR_NAME:$tag" || true
done

echo "✔ Completed: $DIR_NAME (micropython=$MICROPYTHON_VERSION, esp-idf=$ESP_IDF_VERSION, built=$BUILT)"
