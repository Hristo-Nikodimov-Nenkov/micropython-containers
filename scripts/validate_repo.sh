#!/usr/bin/env bash
set -euo pipefail

SERVICES_JSON="$CI_WORKSPACE/services.json"

if [ ! -f "$SERVICES_JSON" ]; then
  echo "ERROR: services.json missing at repo root"
  exit 2
fi