#!/usr/bin/env bash
# Proves scripts/rename_app.sh leaves nothing of the current identity behind:
# renames a copy of the repo to a sample identity (its package name sorts
# before flutter, so the import order changes too) and greps the copy for
# every current value from app.env (case-insensitive). CI runs it on every
# push, so a new file that spells the name differently fails the build.
#
#   scripts/test_rename.sh             rename + grep (seconds)
#   scripts/test_rename.sh --analyze   also flutter analyze and test the copy
set -euo pipefail
cd "$(dirname "$0")/.."

copy="$(mktemp -d)"
trap 'rm -rf "$copy"' EXIT
git ls-files --cached --others --exclude-standard -z | while IFS= read -r -d '' f; do
  [[ -f "$f" ]] || continue
  mkdir -p "$copy/$(dirname "$f")" && cp -p "$f" "$copy/$f"
done
git -C "$copy" init -q && git -C "$copy" add -A

# shellcheck source=/dev/null
source app.env
(cd "$copy" && scripts/rename_app.sh --name "Alpha Tool" --id org.acme.alphatool --firebase acme-alpha-project)

# Every file the repo would hold (generated and ignored files do not count).
left="$(cd "$copy" && git ls-files --cached --others --exclude-standard -z |
  xargs -0 grep -IliF -e "$APP_ID" -e "$FIREBASE_PROJECT" -e "$APP_PACKAGE" -e "$APP_NAME" -e "$APP_SLUG" || true)"
if [[ -n "$left" ]]; then
  echo "Still naming the old app after the rename:" >&2
  sed 's/^/  /' <<<"$left" >&2
  exit 1
fi
grep -q '^APP_ID="org.acme.alphatool"$' "$copy/app.env"
grep -q '^name: alpha_tool$' "$copy/pubspec.yaml"

if [[ "${1:-}" == "--analyze" ]]; then
  (cd "$copy" && flutter pub get >/dev/null && flutter analyze && flutter test -j 2 --exclude-tags screenshots)
fi
echo "Rename leaves no trace of $APP_NAME."
