#!/usr/bin/env bash
set -euo pipefail

service_path="${1:?service_path required}"
hash_file="$service_path/.service_hash"

if [[ ! -f "$hash_file" ]]; then
  echo "true"
  exit 0
fi

current_hash=$(
  cat \
    "$service_path/Dockerfile" \
    "$service_path/build_firmware.sh" \
    "$service_path/versions.json" \
    | sha256sum | awk '{print $1}'
)

stored_hash="$(<"$hash_file")"

if [[ "$current_hash" == "$stored_hash" ]]; then
  echo "false"
else
  echo "true"
fi