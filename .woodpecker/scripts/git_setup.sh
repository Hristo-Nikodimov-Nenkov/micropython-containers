#!/bin/sh
set -eu

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global --add safe.directory "$WORKSPACE"