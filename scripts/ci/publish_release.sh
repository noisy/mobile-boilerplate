#!/usr/bin/env bash
# Publishes the APK as a GitHub prerelease tagged with the version, e.g.
# v0.1.0-build.235, so every installed build maps back to a commit. The notes
# list the issues (#N) mentioned in the commits since the previous release.
set -euo pipefail
# shellcheck source=/dev/null
source app.env
version="$(scripts/ci/app_version.sh)"
build="$(scripts/ci/build_number.sh)"
tag="v$version-build.$build"

git fetch --tags --quiet origin || true
previous="$(git describe --tags --abbrev=0 --match 'v*-build.*' HEAD^ 2>/dev/null || true)"
range="${previous:+$previous..}HEAD"
issues="$(git log --format='%s%n%b' "$range" | grep -oE '#[0-9]+' | tr -d '#' | sort -un || true)"

notes="Commit $(git rev-parse --short HEAD). Install $APP_SLUG-$build.apk on Android."
if [[ -n "$issues" ]]; then
  notes+=$'\n\nIssues in this build:'
  for issue in $issues; do notes+=$'\n'"- #$issue"; done
fi

gh release create "$tag" "$APP_SLUG-$build.apk" \
  --target "$GITHUB_SHA" \
  --title "$APP_NAME $version ($build)" \
  --notes "$notes" \
  --prerelease
