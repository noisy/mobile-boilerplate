#!/usr/bin/env bash
# The one quality gate. Git hooks, CI and humans all run this same script.
#
#   scripts/check.sh           secrets + format check + analyze + tests
#   scripts/check.sh --fix     format the code instead of only checking it
#   scripts/check.sh --quick   secrets + format + analyze only (pre-commit hook)
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-}"

step() { printf '\n==> %s\n' "$1"; }

pinned="$(sed -n 's/^  flutter: *\([0-9.]*\).*/\1/p' pubspec.yaml)"
local_version="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p')"
if [[ -n "$pinned" && "$local_version" != "$pinned" ]]; then
  echo "warning: Flutter $local_version here, pubspec.yaml pins $pinned (CI uses the pin)." >&2
fi

step "No secrets"
scripts/check_no_secrets.sh

step "Format"
if [[ "$mode" == "--fix" ]]; then
  dart format lib test widgetbook
else
  dart format --output=none --set-exit-if-changed lib test widgetbook
fi

step "Analyze"
# Translations are generated, not committed: regenerate so a pulled ARB
# change never shows up as "getter isn't defined" in a stale checkout.
flutter gen-l10n
flutter analyze

if [[ "$mode" == "--quick" ]]; then
  exit 0
fi

step "Test"
# -j 2: parallel testers on all cores can exhaust memory and crash the machine.
flutter test -j 2 --exclude-tags screenshots

printf '\nAll checks passed.\n'
