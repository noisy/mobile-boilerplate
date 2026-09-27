#!/usr/bin/env bash
# Prints the flutter build flags for this commit: version, build number and
# commit (shown on the home screen, lib/core/config/build_info.dart), plus the
# Firebase config from firebase/ when it is there (firebase/README.md).
#
#   scripts/ci/build_flags.sh                  for flutter build
#   scripts/ci/build_flags.sh --no-build-name  for flutter run
set -euo pipefail
version="$(scripts/ci/app_version.sh)"
build="$(scripts/ci/build_number.sh)"
commit="$(git rev-parse --short HEAD 2>/dev/null || echo local)"

flags=()
[[ "${1:-}" == "--no-build-name" ]] || flags+=(--build-name="$version" --build-number="$build")
flags+=(
  --dart-define=APP_VERSION="$version"
  --dart-define=APP_BUILD="$build"
  --dart-define=APP_COMMIT="$commit"
)

defines=build/firebase_defines.json
status=0
python3 scripts/firebase_defines.py --out "$defines" || status=$?
case $status in
  0) flags+=(--dart-define-from-file="$defines") ;;
  3) ;; # no config: demo mode
  *) exit "$status" ;;
esac
echo "${flags[@]}"
