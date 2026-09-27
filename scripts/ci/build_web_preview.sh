#!/usr/bin/env bash
# Builds a browser preview of this commit (sign-in runs in demo mode):
#   build/preview/app/      the app
#   build/preview/catalog/  the Widgetbook component catalog
# Web platform files are generated here (not committed), like Android.
# Base hrefs are relative so the folders work from any URL path.
set -euo pipefail
# shellcheck source=/dev/null
source app.env
scripts/ci/flutter_create.sh web

# shellcheck disable=SC2046 # flags are meant to split into words
flutter build web --no-web-resources-cdn --pwa-strategy=none --output build/preview/app \
  $(scripts/ci/build_flags.sh)
flutter build web -t widgetbook/main.dart --no-web-resources-cdn --pwa-strategy=none \
  --output build/preview/catalog

for index in build/preview/app/index.html build/preview/catalog/index.html; do
  perl -pi -e 's|<base href="/">|<base href="./">|' "$index"
  grep -q '<base href="./">' "$index"
done
