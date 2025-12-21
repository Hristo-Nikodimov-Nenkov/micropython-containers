#!/usr/bin/env bash
set -euo pipefail

IFS=','

for dir in $ORDERED_SERVICES; do
  service_path="$WORKSPACE/$dir"
  version_file="$service_path/versions.json"

  .woodpecker/scripts/validate_service_files.sh "$service_path"

  FULL_SERVICE_REBUILD="$(
    .woodpecker/scripts/service_hash.sh "$service_path"
  )"

  if [[ "$FULL_SERVICE_REBUILD" == "true" ]]; then
    echo "[INFO] Full rebuild for $service_path"
    json_objects=$(jq -c '.[]' "$version_file")
  else
    echo "[INFO] Partial rebuild for $service_path"
    json_objects=$(jq -c '.[] | select(.built == false)' "$version_file")
  fi

  if [[ -z "$json_objects" ]]; then
    echo "[INFO] Nothing to rebuild in $service_path"
    continue
  fi

  while read -r obj; do
    (
      flags=$(jq -r '
        to_entries[] |
        "--" + .key + " " + (.value|tostring)
      ' <<<"$obj")

      # shellcheck disable=SC2086
      bash "$service_path/build.sh" "$service_path" $flags
    ) &
  done <<<"$json_objects"

  wait
  echo "[INFO] Builds finished for $service_path"
done