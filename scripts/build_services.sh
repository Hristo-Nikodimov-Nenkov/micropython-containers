#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${CI_WORKSPACE:-$(pwd)}"
SERVICES_JSON="$WORKSPACE/services.json"

# -----------------------------
# 1. Check services.json exists
# -----------------------------
if [[ ! -f "$SERVICES_JSON" ]]; then
  echo "ERROR: services.json missing at $SERVICES_JSON"
  exit 51
fi

# -----------------------------
# 2. Get ordered service directories
# -----------------------------
ORDERED_SERVICES=$(jq -r 'keys | join(",")' "$SERVICES_JSON") || exit 52
if [[ -z "$ORDERED_SERVICES" ]]; then
  echo "ERROR: No services found in $SERVICES_JSON"
  exit 53
fi

IFS=','

# -----------------------------
# 3. Loop over each service
# -----------------------------
for dir in $ORDERED_SERVICES; do
  SERVICE_PATH="$WORKSPACE/$dir"
  VERSION_FILE="$SERVICE_PATH/versions.json"

  # Validate required files
  bash "$WORKSPACE/scripts/validate_service_files.sh" "$SERVICE_PATH" || exit 54

  # Check if full rebuild is required
  FULL_SERVICE_REBUILD=$(bash "$WORKSPACE/scripts/service_hash.sh" "$SERVICE_PATH") || exit 55

  # Read JSON objects into array safely
  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $SERVICE_PATH"
    mapfile -t JSON_ARRAY < <(jq -c '.[]' "$VERSION_FILE") || exit 56
  else
    echo "[INFO] Partial rebuild for $SERVICE_PATH"
    mapfile -t JSON_ARRAY < <(jq -c '.[] | select(.built == false)' "$VERSION_FILE") || exit 57
  fi

  if [[ ${#JSON_ARRAY[@]} -eq 0 ]]; then
    echo "[INFO] Nothing to rebuild in $SERVICE_PATH"
    continue
  fi

  # -----------------------------
  # 4. Loop over each JSON object
  # -----------------------------
  mapfile -t JSON_ARRAY < <(jq -c '.[]' "$VERSION_FILE")

  for OBJ in "${JSON_ARRAY[@]}"; do
    FLAGS_ARRAY=()
    while IFS="=" read -r key value; do
      FLAGS_ARRAY+=( "--$key" "$value" )
    done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' <<<"$OBJ")

    # Add extra --built false if full rebuild
    if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
      FLAGS_ARRAY+=( "--built" "false" )
    fi

    # Debug print
    echo "[DEBUG] Running: bash $SERVICE_PATH/build.sh $SERVICE_PATH ${FLAGS_ARRAY[*]}"

    bash "$SERVICE_PATH/build.sh" "$SERVICE_PATH" "${FLAGS_ARRAY[@]}" || exit 59
  done


  # Wait for all parallel jobs
  wait
  echo "[INFO] Builds finished for $SERVICE_PATH"
done