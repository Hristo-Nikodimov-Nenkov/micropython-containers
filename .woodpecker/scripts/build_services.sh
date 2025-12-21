#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${CI_WORKSPACE:-$(pwd)}"

IFS=','

for dir in $ORDERED_SERVICES; do
  SERVICE_PATH="$WORKSPACE/$dir"
  VERSION_FILE="$SERVICE_PATH/versions.json"

  .woodpecker/scripts/05_validate_service_files.sh "$SERVICE_PATH"

  FULL_SERVICE_REBUILD="$(
    .woodpecker/scripts/05_service_hash.sh "$SERVICE_PATH"
  )"

  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[]' "$VERSION_FILE")
  else
    echo "[INFO] Partial rebuild for $SERVICE_PATH"
    JSON_OBJECTS=$(jq -c '.[] | select(.built == false)' "$VERSION_FILE")
  fi

  if [[ -z "$JSON_OBJECTS" ]]; then
    echo "[INFO] Nothing to rebuild in $SERVICE_PATH"
    continue
  fi

  while read -r OBJ; do
    (
      FLAGS=$(jq -r '
        to_entries[] |
        "--" + .key + " " + (.value|tostring)
      ' <<<"$OBJ")

      # shellcheck disable=SC2086
      bash "$SERVICE_PATH/build.sh" "$SERVICE_PATH" $FLAGS
    ) &
  done <<<"$JSON_OBJECTS"

  wait
  echo "[INFO] Builds finished for $SERVICE_PATH"
done