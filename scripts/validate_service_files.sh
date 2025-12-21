#!/usr/bin/env bash
set -euo pipefail

SERVICE_PATH="${1:?Service path is required}"

[[ -f "$SERVICE_PATH/Dockerfile" ]] || {
  echo "ERROR: Dockerfile missing in $SERVICE_PATH"
  exit 2
}

[[ -f "$SERVICE_PATH/build_firmware.sh" ]] || {
  echo "ERROR: build_firmware.sh missing in $SERVICE_PATH"
  exit 3
}

[[ -f "$SERVICE_PATH/versions.json" ]] || {
  echo "ERROR: versions.json missing in $SERVICE_PATH"
  exit 4
}

echo "[OK] Required files present in $SERVICE_PATH"