#!/usr/bin/env bash
set -euo pipefail

source .env
      
# Login to Docker Hub
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Make all scripts executable
chmod +x scripts/*.sh

# Run your existing scripts
./scripts/git_setup.sh
./scripts/docker_login.sh
./scripts/validate_repo.sh
./scripts/build_services.sh