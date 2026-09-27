#!/usr/bin/env bash
# Generates the iOS project (not committed) and applies this app's settings
# from app.env: bundle id, name, Sign in with Apple, the Google Sign-In URL
# scheme, the minimum iOS version and the signing team. macOS only.
#
#   APPLE_TEAM_ID=XXXXXXXXXX scripts/ci/prepare_ios.sh
set -euo pipefail
# shellcheck source=/dev/null
source app.env
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required (see docs/ios-setup.md)}"
# Firebase (sign-in) needs iOS 15.
MIN_IOS_VERSION="${MIN_IOS_VERSION:-15.0}"

scripts/ci/flutter_create.sh ios

plist=ios/Runner/Info.plist
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$plist"
plutil -replace CFBundleName -string "$APP_NAME" "$plist"
# No custom encryption: skips the export compliance question in TestFlight.
/usr/libexec/PlistBuddy -c "Delete :ITSAppUsesNonExemptEncryption" "$plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$plist"

# Google Sign-In returns to the app through the reversed iOS client id.
reversed=""
if [[ -f firebase/GoogleService-Info.plist ]]; then
  reversed="$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" firebase/GoogleService-Info.plist 2>/dev/null || true)"
fi
if [[ -n "$reversed" ]]; then
  /usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$plist"
  /usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $reversed" "$plist"
else
  echo "warning: no REVERSED_CLIENT_ID in firebase/GoogleService-Info.plist; Google Sign-In will not return to the app." >&2
fi

# Sign in with Apple.
cp platform/ios/Runner.entitlements ios/Runner/Runner.entitlements

pbxproj=ios/Runner.xcodeproj/project.pbxproj
# Bundle id from app.env (flutter create derives its own from the package name),
# then the team for automatic signing and the entitlements, on the Runner
# target only (not Pods, not RunnerTests).
generated="$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*;' "$pbxproj" | grep -v RunnerTests | head -1 | sed 's/PRODUCT_BUNDLE_IDENTIFIER = \(.*\);/\1/')"
GENERATED="$generated" APP_ID="$APP_ID" perl -pi -e 's/PRODUCT_BUNDLE_IDENTIFIER = \Q$ENV{GENERATED}\E(\.RunnerTests)?;/PRODUCT_BUNDLE_IDENTIFIER = $ENV{APP_ID}$1;/' "$pbxproj"
APP_ID="$APP_ID" APPLE_TEAM_ID="$APPLE_TEAM_ID" perl -pi -e 's/^(\s*)(PRODUCT_BUNDLE_IDENTIFIER = \Q$ENV{APP_ID}\E;)$/$1$2\n$1DEVELOPMENT_TEAM = $ENV{APPLE_TEAM_ID};\n$1CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/' "$pbxproj"
grep -q "PRODUCT_BUNDLE_IDENTIFIER = $APP_ID;" "$pbxproj"
grep -q "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" "$pbxproj"
grep -q "DEVELOPMENT_TEAM = $APPLE_TEAM_ID;" "$pbxproj"

# Raise the deployment target to MIN_IOS_VERSION, never lower it.
current="$(grep -m1 -o 'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*' "$pbxproj" | awk '{print $3}')"
if [[ "$(printf '%s\n%s\n' "$current" "$MIN_IOS_VERSION" | sort -V | head -1)" != "$MIN_IOS_VERSION" ]]; then
  MIN_IOS_VERSION="$MIN_IOS_VERSION" perl -pi -e 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/IPHONEOS_DEPLOYMENT_TARGET = $ENV{MIN_IOS_VERSION};/g' "$pbxproj"
fi

flutter pub get
dart run flutter_launcher_icons -f platform/icons/ios.yaml

# Flutter builds the Dart side and writes the Podfile; signing and archiving
# are done by xcodebuild (.github/workflows/release.yml).
# shellcheck disable=SC2046 # flags are meant to split into words
flutter build ios --release --config-only $(scripts/ci/build_flags.sh)
if [[ -f ios/Podfile ]]; then
  MIN_IOS_VERSION="$MIN_IOS_VERSION" perl -pi -e "s/^#?\s*platform :ios, '[0-9.]+'/platform :ios, '\$ENV{MIN_IOS_VERSION}'/" ios/Podfile
  (cd ios && pod install)
fi
