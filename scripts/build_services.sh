#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${CI_WORKSPACE:-$(pwd)}"
SERVICES_JSON="$WORKSPACE/services.json"

if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: services.json missing at $SERVICES_JSON"
  exit 51
fi

ORDERED_SERVICES=$(jq -r 'keys | join(",")' "$SERVICES_JSON") || exit 52

if [[ -z "$ORDERED_SERVICES" ]]; then
  echo "ERROR: No services found in $SERVICES_JSON"
  exit 53
fi

IFS=','

for dir in $ORDERED_SERVICES; do
  SERVICE_PATH="$WORKSPACE/$dir"
  VERSION_FILE="$SERVICE_PATH/versions.json"

  bash "$WORKSPACE/scripts/validate_service_files.sh" "$SERVICE_PATH" || exit 54

  FULL_SERVICE_REBUILD=$(bash "$WORKSPACE/scripts/service_hash.sh" "$SERVICE_PATH") || exit 55

  # Safely get JSON objects
  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[]' "$VERSION_FILE" 2>/dev/null || true)
  else
    echo "[INFO] Partial rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[] | select(.built == false)' "$VERSION_FILE" 2>/dev/null || true)
  fi

  # Skip if empty
  if [[ -z "$JSON_OBJECTS" ]]; then
    echo "[INFO] Nothing to rebuild in $SERVICE_PATH"
    continue
  fi

  # Loop through JSON objects
  while read -r OBJ; do
    (
      # Build flags array from JSON object
      FLAGS_ARRAY=()
      while IFS="=" read -r key value; do
        FLAGS_ARRAY+=("--$key" "$value")
      done < <(jq -r 'to_entries | .[] | "\(.key)=\(.value)"' <<<"$OBJ")

      # Add --built false if full rebuild
      if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
        FLAGS_ARRAY+=("--built" "false")
      fi

      # Debug print
      echo "[DEBUG] Running: bash $SERVICE_PATH/build.sh $SERVICE_PATH ${FLAGS_ARRAY[*]}"

      # Execute build.sh
      bash "$SERVICE_PATH/build.sh" "$SERVICE_PATH" "${FLAGS_ARRAY[@]}"
    ) &
  done <<<"$JSON_OBJECTS"

  wait
  echo "[INFO] Builds finished for $SERVICE_PATH"
done