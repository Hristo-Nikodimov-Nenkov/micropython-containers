#!/usr/bin/env bash
set -euo pipefail

# Configure git
git config --global user.name "$GIT_USER_NAME" || exit 1
git config --global user.email "$GIT_USER_EMAIL" || exit 2

# Mark workspace as safe
git config --global --add safe.directory "$CI_WORKSPACE" || exit 3