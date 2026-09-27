#!/usr/bin/env bash
# Writes the Firebase config files from CI secrets into firebase/.
# Missing secrets are fine: the build then runs in demo mode, with a warning.
set -euo pipefail
restore() {
  local value="$1" file="$2"
  if [[ -n "$value" ]]; then
    echo "$value" | base64 --decode > "firebase/$file"
    echo "Restored firebase/$file"
  else
    echo "::warning::No $file secret: this build signs in in demo mode (see README)."
  fi
}
restore "${GOOGLE_SERVICES_JSON_BASE64:-}" google-services.json
restore "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" GoogleService-Info.plist
