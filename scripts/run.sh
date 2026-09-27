#!/usr/bin/env bash
# `flutter run` with this app's Firebase config (firebase/README.md) and
# build info. Extra arguments go to flutter run, e.g. scripts/run.sh -d chrome
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC2046 # flags are meant to split into words
exec flutter run $(scripts/ci/build_flags.sh --no-build-name) "$@"
