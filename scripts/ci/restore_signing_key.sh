#!/usr/bin/env bash
# Puts the Android upload keystore (secret ANDROID_KEYSTORE_BASE64) where the
# Gradle config from prepare_android.sh finds it, via APP_KEYSTORE.
set -euo pipefail
: "${ANDROID_KEYSTORE_BASE64:?ANDROID_KEYSTORE_BASE64 secret is missing (see README)}"
keystore="$RUNNER_TEMP/upload.keystore"
echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$keystore"
echo "APP_KEYSTORE=$keystore" >> "$GITHUB_ENV"
