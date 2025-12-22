#!/bin/sh

source .env

check_required_files() {
  SERVICE_PATH="$1"

  [ -f "$SERVICE_PATH/Dockerfile" ] || {
    echo "ERROR: Dockerfile missing in $SERVICE_PATH"
    exit 2
  }

  [ -f "$SERVICE_PATH/build_firmware.sh" ] || {
    echo "ERROR: build_firmware.sh missing in $SERVICE_PATH"
    exit 3
  }

  [ -f "$SERVICE_PATH/versions.json" ] || {
    echo "ERROR: versions.json missing in $SERVICE_PATH"
    exit 4
  }
}

check_service_hash() {
  SERVICE_PATH="$1"
  HASH_FILE="$SERVICE_PATH/.service_hash"

  if [ ! -f "$HASH_FILE" ]; then
    FULL_SERVICE_REBUILD=true
    export FULL_SERVICE_REBUILD
    return
  fi

  CURRENT_HASH=$(cat \
    "$SERVICE_PATH/Dockerfile" \
    "$SERVICE_PATH/build_firmware.sh" \
    "$SERVICE_PATH/versions.json" \
    | sha256sum | awk '{print $1}')

  STORED_HASH=$(cat "$HASH_FILE")

  if [ "$CURRENT_HASH" = "$STORED_HASH" ]; then
    FULL_SERVICE_REBUILD=false
  else
    FULL_SERVICE_REBUILD=true
  fi

  export FULL_SERVICE_REBUILD
}