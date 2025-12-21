#!/usr/bin/env bash
set -euo pipefail

# Setup git config in the cloned repo
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

git config --global --add safe.directory "$CI_WORKSPACE"