#!/bin/sh
set -eu

REPO_URL="https://github.com/Hristo-Nikodimov-Nenkov/micropython-containers.git"

git clone --depth=1 "$REPO_URL" "$WORKSPACE"
cd "$WORKSPACE"