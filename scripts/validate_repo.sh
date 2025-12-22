#!/usr/bin/env bash
set -euo pipefail

source .env

SERVICES_JSON="$CI_WORKSPACE/services.json"

if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: services.json missing at repo root ($SERVICES_JSON)"
  exit 21
fi

echo "[INFO] services.json found at $SERVICES_JSON"