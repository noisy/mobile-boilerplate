#!/usr/bin/env bash
# Generates the Android project (not committed) and applies this app's
# settings from app.env. Runs on Linux (CI) and macOS: perl instead of sed -i.
set -euo pipefail
# shellcheck source=/dev/null
source app.env

scripts/ci/flutter_create.sh android

manifest=android/app/src/main/AndroidManifest.xml
APP_NAME="$APP_NAME" perl -pi -e 's/android:label="[^"]*"/android:label="$ENV{APP_NAME}"/' "$manifest"
# Sign-in needs network access in release builds.
grep -q "android.permission.INTERNET" "$manifest" ||
  perl -pi -e 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$manifest"

gradle=android/app/build.gradle.kts
# The store id comes from app.env; the Kotlin package stays what flutter create made.
APP_ID="$APP_ID" perl -pi -e 's/applicationId = "[^"]*"/applicationId = "$ENV{APP_ID}"/' "$gradle"
grep -q "applicationId = \"$APP_ID\"" "$gradle"
# Firebase needs Android 6 (API 23) or newer.
perl -pi -e 's/minSdk = flutter.minSdkVersion/minSdk = maxOf(23, flutter.minSdkVersion)/' "$gradle"
grep -q "minSdk = maxOf(23" "$gradle"

# Gradle and Kotlin daemons share the runner's memory; cap them so the
# release build is not killed.
cat >> android/gradle.properties <<'PROPS'
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError
kotlin.daemon.jvmargs=-Xmx2g
org.gradle.caching=true
PROPS

# Release builds are signed with the upload key when APP_KEYSTORE points at
# it (CI: restore_signing_key.sh; locally: README "Android signing"), and
# with the debug key otherwise, so local release builds still install.
cat >> "$gradle" <<'KTS'

android {
    signingConfigs {
        create("upload") {
            val keystore = System.getenv("APP_KEYSTORE")
            if (keystore != null) {
                storeFile = file(keystore)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = if (System.getenv("APP_KEYSTORE") != null)
                signingConfigs.getByName("upload")
            else
                signingConfigs.getByName("debug")
        }
    }
}
KTS

flutter pub get
dart run flutter_launcher_icons -f platform/icons/android.yaml
