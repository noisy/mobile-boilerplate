#!/usr/bin/env bash
# Builds the release APK as <slug>-<build>.apk and prints its signing
# certificate. With ANDROID_CERT_SHA256 set (a repo variable, not secret) it
# fails unless the APK is signed with that certificate, so a wrong keystore
# never ships an APK that cannot update the installed one.
set -euo pipefail
# shellcheck source=/dev/null
source app.env
build_number="$(scripts/ci/build_number.sh)"

# shellcheck disable=SC2046 # flags are meant to split into words
flutter build apk --release $(scripts/ci/build_flags.sh)
apk=build/app/outputs/flutter-apk/app-release.apk

apksigner=$(ls "$ANDROID_HOME"/build-tools/*/apksigner | sort -V | tail -1)
"$apksigner" verify --print-certs "$apk" | tee certs.txt
if [[ -n "${ANDROID_CERT_SHA256:-}" ]]; then
  grep -qi "SHA-256 digest: $ANDROID_CERT_SHA256" certs.txt ||
    { echo "APK is not signed with ANDROID_CERT_SHA256" >&2; exit 1; }
fi

cp "$apk" "$APP_SLUG-$build_number.apk"
echo "Built $APP_SLUG-$build_number.apk"
