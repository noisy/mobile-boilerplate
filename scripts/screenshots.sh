#!/usr/bin/env bash
# Renders every screen (per device and language) and every component to PNGs
# in test/screenshots/goldens/, for looking at, not for committing.
# -j 1: rendering is memory hungry.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter test -j 1 --tags screenshots --update-goldens "$@"
echo "Screenshots in test/screenshots/goldens/"
