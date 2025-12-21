#!/usr/bin/env bash
set -euo pipefail

service_path="${1:?service_path required}"

[[ -f "$service_path/Dockerfile" ]] || {
  echo "ERROR: Dockerfile missing in $service_path"
  exit 2
}

[[ -f "$service_path/build_firmware.sh" ]] || {
  echo "ERROR: build_firmware.sh missing in $service_path"
  exit 3
}

[[ -f "$service_path/versions.json" ]] || {
  echo "ERROR: versions.json missing in $service_path"
  exit 4
}

echo "[OK] Required files present in $service_path"