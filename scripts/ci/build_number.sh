#!/usr/bin/env bash
# Prints the build number: BUILD_NUMBER_OFFSET (app.env, default 0) + the
# number of commits on this branch. Same commit -> same number on Android and
# iOS; always increases on main. Raise the offset if the stores already have
# higher numbers. Needs full git history (actions/checkout fetch-depth: 0).
set -euo pipefail
# shellcheck source=/dev/null
source app.env
commits="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
echo $((${BUILD_NUMBER_OFFSET:-0} + commits))
