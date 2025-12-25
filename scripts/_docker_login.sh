#!/usr/bin/env bash
set -euo pipefail

echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin || exit 11