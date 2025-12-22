#!/usr/bin/env bash
set -euo pipefail

source .env

echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin || exit 11