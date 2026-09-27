#!/usr/bin/env bash
# Builds the release APK on this machine, in a separate worktree so the
# generated android/ project never touches your checkout, and installs it on
# every connected phone (adb).
#
#   scripts/dev/build_android.sh [ref]      (default: HEAD)
#
# Needs Flutter and the Android SDK. Signs with the upload key when
# APP_KEYSTORE and the ANDROID_* passwords are set (README, "Android
# signing"), otherwise with the debug key. The Firebase files in firebase/
# are copied into the worktree.
set -euo pipefail
cd "$(dirname "$0")/../.."
ref="${1:-HEAD}"
dir=.worktree/android-build

if [[ -d "$dir" ]]; then
  git -C "$dir" checkout -q --detach "$(git rev-parse "$ref")"
else
  git worktree add -q --detach "$dir" "$ref"
fi
cp firebase/google-services.json firebase/GoogleService-Info.plist "$dir/firebase/" 2>/dev/null || true
cd "$dir"
# shellcheck source=/dev/null
source app.env
[[ -d android ]] || scripts/ci/prepare_android.sh
scripts/ci/build_apk.sh
apk=$(ls -t "$APP_SLUG"-*.apk | head -1)

for device in $(adb devices | awk 'NR>1 && $2=="device" {print $1}'); do
  echo "Installing on $device"
  adb -s "$device" install -r "$apk" | tail -1
done
