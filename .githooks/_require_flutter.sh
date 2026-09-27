#!/usr/bin/env bash
# Hooks need Flutter. Without it they warn and let the commit through;
# CI still runs the same checks and blocks the build.
if ! command -v flutter >/dev/null 2>&1; then
  echo "hooks: flutter not found, skipping local checks (CI will run them)." >&2
  exit 0
fi

# Git exports its own repo to hooks (GIT_DIR and friends, set in worktrees).
# The Flutter tool runs git inside the SDK to read its version and would read
# this repo instead, failing as "Flutter 0.0.0-unknown".
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR
