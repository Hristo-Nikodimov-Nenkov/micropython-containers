#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${CI_WORKSPACE:-$(pwd)}"
SERVICES_JSON="$WORKSPACE/services.json"

if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: services.json missing at $SERVICES_JSON"
  exit 51
fi

# Get ordered services as a comma-separated list
ORDERED_SERVICES=$(jq -r 'keys | join(",")' "$SERVICES_JSON") || exit 52

if [[ -z "$ORDERED_SERVICES" ]]; then
  echo "ERROR: No services found in $SERVICES_JSON"
  exit 53
fi

IFS=',' read -r -a SERVICES <<<"$ORDERED_SERVICES"

for dir in "${SERVICES[@]}"; do
  SERVICE_PATH="$WORKSPACE/$dir"
  VERSION_FILE="$SERVICE_PATH/versions.json"

  # Validate service files
  bash "$WORKSPACE/scripts/validate_service_files.sh" "$SERVICE_PATH" || exit 54

  # Determine if full rebuild is needed
  FULL_SERVICE_REBUILD=$(bash "$WORKSPACE/scripts/service_hash.sh" "$SERVICE_PATH") || exit 55

  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[]' "$VERSION_FILE") || exit 56
  else
    echo "[INFO] Partial rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[] | select(.built == false)' "$VERSION_FILE") || exit 57
  fi

  if [[ -z "$JSON_OBJECTS" ]]; then
    echo "[INFO] Nothing to rebuild in $SERVICE_PATH"
    continue
  fi

  while IFS= read -r OBJ; do
    # Convert JSON object to array of arguments: --key value
    readarray -t FLAGS_ARRAY < <(
      jq -r 'to_entries | map("--"+.key, (.value|tostring)) | .[]' <<<"$OBJ"
    )

    # Append --built false for full rebuilds
    if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
      FLAGS_ARRAY+=("--built" "false")
    fi

    # Print debug info
    printf '[DEBUG] Running: bash %s/build.sh %s' "$SERVICE_PATH" "$SERVICE_PATH"
    for arg in "${FLAGS_ARRAY[@]}"; do
      printf ' %q' "$arg"
    done
    echo

    # Run build.sh synchronously
    bash -x "$SERVICE_PATH/build.sh" "$SERVICE_PATH" "${FLAGS_ARRAY[@]}"

  done <<<"$JSON_OBJECTS"

  echo "[INFO] Builds finished for $SERVICE_PATH"
done