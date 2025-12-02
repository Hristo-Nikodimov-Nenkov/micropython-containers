#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/var/containers"

: "${DOCKERHUB_USERNAME:?Must set DOCKERHUB_USERNAME in .env}"
: "${DOCKERHUB_TOKEN:?Must set DOCKERHUB_TOKEN in .env}"

echo "========== Starting build_containers =========="

# ======================================================
# Compute stable hash of build-critical files
# ======================================================
calculate_service_hash() {
    local dir="$1"
    (
        cd "$dir"
        sha256sum Dockerfile build.sh build_firmware.sh 2>/dev/null \
            | sha256sum \
            | awk '{print $1}'
    )
}

# ======================================================
# Convert JSON object to CLI flags for build.sh
# ======================================================
json_obj_to_flags() {
    local json_file="$1"
    local index="$2"

    local flags=""
    local keys
    keys=$(jq -r ".[$index] | keys[]" "$json_file")

    for key in $keys; do
        local value
        value=$(jq -r ".[$index][\"$key\"]" "$json_file")

        if [[ "$value" == "true" || "$value" == "false" ]]; then
            flags+=" --$key $value"
        else
            flags+=" --$key \"$value\""
        fi
    done

    echo "$flags"
}

# ======================================================
# Update DockerHub README
# ======================================================
update_dockerhub_readme() {
    local service="$1"
    local readme_path="$2"
    local repo="${DOCKERHUB_USERNAME}/${service}"

    if [[ ! -f "$readme_path" ]]; then
        echo ">>> No README.md found for ${service}, skipping DockerHub description update"
        return
    fi

    echo ">>> Updating DockerHub README for ${repo}"
    local readme_text
    readme_text=$(sed 's/"/\\"/g' "$readme_path" | awk '{printf "%s\\n", $0}')

    # Docker Hub API v2: update repository description
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PATCH "https://hub.docker.com/v2/repositories/${repo}/" \
        -H "Content-Type: application/json" \
        -u "${DOCKERHUB_USERNAME}:${DOCKERHUB_TOKEN}" \
        -d "{\"full_description\": \"${readme_text}\"}")

    if [[ "$http_code" == "200" ]]; then
        echo ">>> DockerHub README updated for ${repo}"
    else
        echo ">>> Failed to update README (HTTP $http_code)"
    fi
}

# ======================================================
# DockerHub login
# ======================================================
echo "========== DockerHub Login =========="
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
echo "========== Login successful =========="

# ======================================================
# Process each service
# ======================================================
for dir in "$WORKSPACE"/*/ ; do
    [[ -f "$dir/build.sh" ]] || continue
    [[ -f "$dir/versions.json" ]] || continue

    service=$(basename "$dir")

    echo ""
    echo "-------------------------------------------------"
    echo " SERVICE: $service"
    echo " DIRECTORY: $dir"
    echo "-------------------------------------------------"

    # ----------------------------------------------
    # Detect changes for force rebuild
    # ----------------------------------------------
    echo ">>> Checking build file changes"
    current_hash=$(calculate_service_hash "$dir")
    hash_file="$dir/.service_hash"
    force_rebuild=false

    if [[ -f "$hash_file" ]]; then
        previous_hash=$(cat "$hash_file")
        if [[ "$current_hash" != "$previous_hash" ]]; then
            echo ">>> Changes detected — forcing rebuild of all tags"
            force_rebuild=true
        else
            echo ">>> No changes detected"
        fi
    else
        echo ">>> First build — forcing rebuild of all tags"
        force_rebuild=true
    fi

    # ----------------------------------------------
    # Loop through versions.json entries
    # ----------------------------------------------
    version_count=$(jq 'length' "$dir/versions.json")

    for i in $(seq 0 $((version_count - 1))); do
        flags=$(json_obj_to_flags "$dir/versions.json" "$i")
        built=$(jq -r ".[$i].built" "$dir/versions.json")
        tag=$(jq -r ".[$i].tag" "$dir/versions.json")

        # Skip if already built
        if [[ "$force_rebuild" = false && "$built" = "true" ]]; then
            echo ">>> Skipping $service:$tag — already built"
            continue
        fi

        final_flags="$flags"
        if [[ "$force_rebuild" = true ]]; then
            final_flags="$flags --built false"
        fi

        echo ">>> Running build.sh for $service:$tag"
        (
            cd "$dir"
            chmod +x ./build.sh
            eval ./build.sh $final_flags
        )

        # ----------------------------------------------
        # Commit changes to versions.json immediately
        # ----------------------------------------------
        jq ".[$i].built = true" "$dir/versions.json" > "$dir/versions.json.tmp"
        mv "$dir/versions.json.tmp" "$dir/versions.json"

        git -C "$WORKSPACE" add "$dir/versions.json"
        if ! git -C "$WORKSPACE" diff --cached --quiet; then
            git -C "$WORKSPACE" commit -m "Built $service:$tag — updated versions.json"
            git -C "$WORKSPACE" push || echo ">>> Push failed for $service:$tag"
        else
            echo ">>> No changes to commit for $service:$tag"
        fi
    done

    # ----------------------------------------------
    # Update service hash (commit after all versions)
    # ----------------------------------------------
    echo "$current_hash" > "$hash_file"

    git -C "$WORKSPACE" add "$hash_file"
    if ! git -C "$WORKSPACE" diff --cached --quiet; then
        git -C "$WORKSPACE" commit -m "Updated service hash for $service"
        git -C "$WORKSPACE" push || echo ">>> Push failed for service hash"
    else
        echo ">>> No changes to commit for service hash"
    fi

    # ----------------------------------------------
    # Update DockerHub README
    # ----------------------------------------------
    update_dockerhub_readme "$service" "$dir/README.md"
done

echo ""
echo "========== All services built, pushed to DockerHub, and committed & pushed to Git =========="