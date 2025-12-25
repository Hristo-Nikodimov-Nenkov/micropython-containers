#!/usr/bin/env bash
set -euo pipefail

SERVICE_PATH="${1:?Service path is required}"

[[ -f "$SERVICE_PATH/Dockerfile" ]] || { echo "ERROR: Dockerfile missing in $SERVICE_PATH"; exit 31; }
[[ -f "$SERVICE_PATH/build_firmware.sh" ]] || { echo "ERROR: build_firmware.sh missing in $SERVICE_PATH"; exit 32; }
[[ -f "$SERVICE_PATH/versions.json" ]] || { echo "ERROR: versions.json missing in $SERVICE_PATH"; exit 33; }

echo "[INFO] Required files present in $SERVICE_PATH"