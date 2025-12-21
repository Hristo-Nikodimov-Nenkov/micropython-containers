#!/bin/sh
set -eu

echo "$DOCKERHUB_TOKEN" \
  | docker login -u "$DOCKERHUB_USERNAME" --password-stdin