#!/usr/bin/env bash
# Gives the app its own identity in one go. Replaces the current values from
# app.env (at first the boilerplate's placeholders) in every file of the repo,
# including app.env itself, renames files named after them, and then checks
# that no old value is left anywhere.
#
#   scripts/rename_app.sh --name "Pocket Coach" --id com.yourcompany.pocketcoach \
#     --firebase pocket-coach-1a2b3 [--package pocket_coach] [--slug pocketcoach]
#
#   --name      what users see under the icon and in the stores
#   --id        Android application id and iOS bundle id (reverse domain)
#   --firebase  Firebase project id (console -> Project settings)
#   --package   Dart package name (default: from --name, e.g. pocket_coach)
#   --slug      short lowercase name for files and artifacts (default: from --name)
#
# Meant to run once, right after copying the boilerplate. Running it again
# works too (it starts from what app.env says now), as long as the current
# values are distinctive: every occurrence of them is replaced.
set -euo pipefail
cd "$(dirname "$0")/.."

usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
fail() { echo "rename_app: $*" >&2; exit 1; }

new_name="" new_id="" new_firebase="" new_package="" new_slug=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) new_name="${2:-}"; shift 2 ;;
    --id) new_id="${2:-}"; shift 2 ;;
    --firebase) new_firebase="${2:-}"; shift 2 ;;
    --package) new_package="${2:-}"; shift 2 ;;
    --slug) new_slug="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done
[[ -n "$new_name" && -n "$new_id" && -n "$new_firebase" ]] || usage

lower_name="$(tr '[:upper:]' '[:lower:]' <<<"$new_name")"
[[ -n "$new_package" ]] || new_package="$(sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g' <<<"$lower_name")"
[[ -n "$new_slug" ]] || new_slug="$(sed -E 's/[^a-z0-9]+//g' <<<"$lower_name")"

# Each value ends up in Dart strings, XML, plists, JSON and shell, so only
# characters that are safe in all of them are allowed.
[[ "$new_name" =~ ^[A-Za-z0-9][A-Za-z0-9\ .-]{0,29}$ ]] ||
  fail "--name: letters, digits, spaces, dots and dashes, at most 30 characters"
[[ "$new_id" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$ ]] ||
  fail "--id: lowercase reverse domain like com.yourcompany.pocketcoach (no dashes or underscores: valid on both stores)"
[[ "$new_firebase" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]] ||
  fail "--firebase: a Firebase project id (6-30 lowercase letters, digits, dashes)"
[[ "$new_package" =~ ^[a-z][a-z0-9_]*$ ]] ||
  fail "--package: a Dart package name (lowercase letters, digits, underscores)"
[[ "$new_slug" =~ ^[a-z][a-z0-9]*$ ]] ||
  fail "--slug: lowercase letters and digits"

# shellcheck source=/dev/null
source app.env
old_name="$APP_NAME" old_package="$APP_PACKAGE" old_slug="$APP_SLUG"
old_id="$APP_ID" old_firebase="$FIREBASE_PROJECT"

# Files to rewrite: everything git knows (tracked or new, not ignored), or
# every file outside build output when this is not a git checkout.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  list_files() { git ls-files --cached --others --exclude-standard; }
else
  list_files() {
    find . -type f \
      -not -path './.git/*' -not -path './build/*' -not -path './.dart_tool/*' \
      -not -path './android/*' -not -path './ios/*' -not -path './web/*' \
      -not -path './.worktree/*' | sed 's|^\./||'
  }
fi

# One pass with all old values at once, longest first, so a new value that
# happens to contain an old one is never replaced again.
export OLD_ID="$old_id" NEW_ID="$new_id" OLD_FIREBASE="$old_firebase" NEW_FIREBASE="$new_firebase"
export OLD_PACKAGE="$old_package" NEW_PACKAGE="$new_package" OLD_NAME="$old_name" NEW_NAME="$new_name"
export OLD_SLUG="$old_slug" NEW_SLUG="$new_slug"
replace='
  BEGIN {
    %map = (
      $ENV{OLD_ID} => $ENV{NEW_ID}, $ENV{OLD_FIREBASE} => $ENV{NEW_FIREBASE},
      $ENV{OLD_PACKAGE} => $ENV{NEW_PACKAGE}, $ENV{OLD_NAME} => $ENV{NEW_NAME},
      $ENV{OLD_SLUG} => $ENV{NEW_SLUG},
    );
    $re = join "|", map { quotemeta } sort { length $b <=> length $a } keys %map;
  }
  s/($re)/$map{$1}/g;
'

changed=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  grep -Iq . "$file" 2>/dev/null || continue # skip binary and empty files
  if grep -qF -e "$old_id" -e "$old_firebase" -e "$old_package" -e "$old_name" -e "$old_slug" "$file"; then
    perl -pi -e "$replace" "$file"
    changed=$((changed + 1))
  fi
done < <(list_files)

# Files and folders named after an old value.
while IFS= read -r file; do
  target="$(perl -pe "$replace" <<<"$file")"
  if [[ "$target" != "$file" && -e "$file" ]]; then
    mkdir -p "$(dirname "$target")"
    git mv "$file" "$target" 2>/dev/null || mv "$file" "$target"
  fi
done < <(list_files)

# The Dart package name changed: resolve packages under the new name, then
# fix the import order, which sorts by package name.
if command -v flutter >/dev/null 2>&1; then
  flutter pub get >/dev/null
  dart fix --apply --code=directives_ordering . >/dev/null
  dart format lib test widgetbook >/dev/null
fi

# Nothing of the old identity may remain (case-insensitive).
left="$(list_files | while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  if grep -IqiF -e "$old_id" -e "$old_firebase" -e "$old_package" -e "$old_name" -e "$old_slug" "$file" \
    || grep -qiF -e "$old_package" -e "$old_name" -e "$old_slug" <<<"$file"; then
    echo "$file"
  fi
done)"
if [[ -n "$left" ]]; then
  echo "rename_app: old values are still in:" >&2
  sed 's/^/  /' <<<"$left" >&2
  exit 1
fi

cat <<EOF
Renamed in $changed files:
  name      $old_name -> $new_name
  id        $old_id -> $new_id
  firebase  $old_firebase -> $new_firebase
  package   $old_package -> $new_package
  slug      $old_slug -> $new_slug
Next: scripts/check.sh, then the rest of the README checklist.
EOF
