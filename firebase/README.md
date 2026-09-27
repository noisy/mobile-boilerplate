# Firebase config

Put the two files you download from the Firebase console here. Both are
gitignored; only the `.template` files are committed, to show the shape.

| File | Where it comes from |
|---|---|
| `google-services.json` | Firebase console -> Project settings -> Your apps -> the Android app -> "google-services.json" |
| `GoogleService-Info.plist` | Firebase console -> Project settings -> Your apps -> the iOS app -> "GoogleService-Info.plist" |

The app never reads these files directly. `scripts/firebase_defines.py` turns
them into `build/firebase_defines.json`, which every build passes to Flutter
with `--dart-define-from-file` (see `scripts/ci/build_flags.sh` and
`scripts/run.sh`). It also checks that the files belong to the project and
application id in `app.env`, so a file from another app fails loudly.

Without the files the app still builds and runs in demo mode: sign-in is
simulated on the device, and the sign-in screen says so.

On CI the files come from the `GOOGLE_SERVICES_JSON_BASE64` and
`GOOGLE_SERVICE_INFO_PLIST_BASE64` secrets (see the README).
