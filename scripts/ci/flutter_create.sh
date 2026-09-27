#!/usr/bin/env bash
# Generates platform folders (android, ios, web: not committed) with the org
# and package name from app.env, and removes the starter files flutter create
# adds next to them (README, counter test), which are not part of this app.
#
#   scripts/ci/flutter_create.sh android|ios|web
set -euo pipefail
# shellcheck source=/dev/null
source app.env
starters=(README.md test/widget_test.dart .metadata)
existing=()
for file in "${starters[@]}"; do [[ -e "$file" ]] && existing+=("$file"); done

flutter create --org "${APP_ID%.*}" --project-name "$APP_PACKAGE" --platforms "$1" . >/dev/null

for file in "${starters[@]}"; do
  if [[ ! " ${existing[*]-} " == *" $file "* ]]; then rm -f "$file"; fi
done
echo "Generated $1/"
