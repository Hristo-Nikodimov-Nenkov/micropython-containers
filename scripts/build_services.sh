#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${CI_WORKSPACE:-$(pwd)}"
SERVICES_JSON="$WORKSPACE/services.json"

# Check for services.json
if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: services.json missing at $SERVICES_JSON"
  exit 51
fi

# Get service directories as comma-separated string
ORDERED_SERVICES=$(jq -r 'keys | join(",")' "$SERVICES_JSON") || exit 52
if [[ -z "$ORDERED_SERVICES" ]]; then
  echo "ERROR: No services found in $SERVICES_JSON"
  exit 53
fi

IFS=','

for dir in $ORDERED_SERVICES; do
  SERVICE_PATH="$WORKSPACE/$dir"
  VERSION_FILE="$SERVICE_PATH/versions.json"

  # Validate required files
  bash "$WORKSPACE/scripts/validate_service_files.sh" "$SERVICE_PATH" || exit 54

  # Determine if full rebuild is required
  FULL_SERVICE_REBUILD=$(bash "$WORKSPACE/scripts/service_hash.sh" "$SERVICE_PATH") || exit 55

  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $SERVICE_PATH"
    # Read JSON objects into Bash array safely
    mapfile -t JSON_ARRAY < <(jq -c '.[]' "$VERSION_FILE") || exit 56
  else
    echo "[INFO] Partial rebuild for $SERVICE_PATH"
    mapfile -t JSON_ARRAY < <(jq -c '.[] | select(.built == false)' "$VERSION_FILE") || exit 57
  fi

  # Nothing to build
  if [[ ${#JSON_ARRAY[@]} -eq 0 ]]; then
    echo "[INFO] Nothing to rebuild in $SERVICE_PATH"
    continue
  fi

  # Loop over each JSON object
  for OBJ in "${JSON_ARRAY[@]}"; do
    (
      # Convert JSON object to flags array safely
      mapfile -t FLAGS_ARRAY < <(
        jq -r 'to_entries[] | "--" + .key + " " + (.value|tostring)' <<<"$OBJ"
      ) || exit 58
  
      # Print the command that will be run
      echo "[DEBUG] Running: bash $SERVICE_PATH/build.sh $SERVICE_PATH ${FLAGS_ARRAY[*]}"
  
      # Call build.sh with correct arguments
      bash "$SERVICE_PATH/build.sh" "$SERVICE_PATH" "${FLAGS_ARRAY[@]}" || exit 59
    ) &
  done


  # Wait for all parallel builds to finish
  wait
  echo "[INFO] Builds finished for $SERVICE_PATH"
done