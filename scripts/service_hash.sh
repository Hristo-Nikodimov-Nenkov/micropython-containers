#!/usr/bin/env bash
set -euo pipefail

SERVICE_PATH="${1:?Service path is required}"
HASH_FILE="$SERVICE_PATH/.service_hash"

if [[ ! -f "$HASH_FILE" ]]; then
  echo "true"
  exit 0
fi

CURRENT_HASH=$(
  cat \
    "$SERVICE_PATH/Dockerfile" \
    "$SERVICE_PATH/build_firmware.sh" \
    "$SERVICE_PATH/versions.json" \
    | sha256sum | awk '{print $1}'
)

STORED_HASH=$(<"$HASH_FILE")

if [[ "$CURRENT_HASH" == "$STORED_HASH" ]]; then
  echo "false"
else
  echo "true"
fi