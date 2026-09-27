# MyApp

A Flutter app for Android and iOS, started from the mobile boilerplate:
Firebase sign-in (Google, Apple, or no account at all, with account linking),
a layered feature-first structure the tests enforce, English and Polish, golden
screenshots per device, a Widgetbook catalog, and GitHub Actions for checks and
releases.

The example feature is small on purpose: a sign-in screen, then a home screen
showing who is signed in, with sign out. Replace the home screen with your app.

## Start a new app

Work through this list top to bottom. Each step says where the result goes.
Nothing on it is a secret that belongs in the repo: keys and config files go
into gitignored files or GitHub secrets.

### 1. Copy and rename

1. Copy the boilerplate into a new repo (GitHub "Use this template", or clone
   and replace the remote).
2. Rename everything in one go:

   ```sh
   scripts/rename_app.sh --name "Pocket Coach" --id com.yourcompany.pocketcoach --firebase pocket-coach-1a2b3
   ```

   The app's identity lives in `app.env` (the boilerplate starts with the name
   `MyApp`, package `my_app`, slug `myapp`, id `com.example.myapp` and Firebase
   project `my-firebase-project`). The script replaces those values in every
   file, then fails if any of them is left anywhere. `--firebase` is the
   project ID you get in step 2; if you do not have it yet, pick the ID now
   and use it when creating the project. Your id is permanent once the app is
   in a store.
3. `scripts/setup-hooks.sh`, then `scripts/check.sh`. Commit.

### 2. Firebase project

In the [Firebase console](https://console.firebase.google.com):

1. Create the project with the ID from `app.env` (`FIREBASE_PROJECT`).
2. Authentication -> Sign-in method: enable **Anonymous**, **Google** and
   **Apple** (for Apple on iOS only, no Services ID or key is needed here).
3. Project settings -> Your apps: add an **Android** app with the package name
   `APP_ID` from `app.env`, and an **iOS** app with the same bundle ID.
4. Android app -> "Add fingerprint": add the **SHA-1** (and SHA-256) of every
   key that signs the app, or Google sign-in fails with "developer error":
   - your debug key:
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
   - the upload key from step 4 (`keytool -list -v -keystore <file> -alias upload`)
   - after Google Play takes over signing: Play Console -> Test and release ->
     App integrity -> App signing key certificate.
5. Only now download the config files, because they include the OAuth clients
   created by steps 2 and 4: `google-services.json` and
   `GoogleService-Info.plist` go into `firebase/` (gitignored; the
   `.template` files show the shape). `scripts/firebase_defines.py` checks
   they belong to this project and app id. Download them again whenever you
   add a fingerprint.

Without these files the app still runs, in demo mode (sign-in simulated on
the device, with a banner saying so). Run with the config: `scripts/run.sh`.

### 3. Apple

Needs an Apple Developer Program membership. Step by step: [docs/ios-setup.md](docs/ios-setup.md).

1. Certificates, IDs & Profiles -> Identifiers: register the App ID
   (`APP_ID`) with the **Sign In with Apple** capability.
2. The **reversed client ID URL scheme** for Google sign-in is added by
   `scripts/ci/prepare_ios.sh` from `REVERSED_CLIENT_ID` in
   `GoogleService-Info.plist`. It warns when the key is missing: download the
   plist again after enabling Google sign-in.
3. Only for Apple sign-in on Android or the web: create a **Services ID**
   and a Sign in with Apple key, and enter them in Firebase -> Authentication
   -> Apple. Then add `SignInProvider.apple` on Android in
   `FirebaseAuthGateway.availableProviders`.
4. App Store Connect: create the app record and an API key (Admin, Team Key)
   for CI.

### 4. Android signing

Create the upload keystore once and keep it (and its passwords) in a password
manager. Losing it means you can no longer update the app outside Google Play
App Signing.

```sh
keytool -genkeypair -v -keystore ~/.config/myapp/upload.keystore -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Local release builds use it when `APP_KEYSTORE`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` are set, and the debug key
otherwise. Add its SHA-1 to Firebase (step 2.4).

### 5. GitHub secrets

Settings -> Secrets and variables -> Actions, or `gh secret set NAME`:

| Secret | Value |
|---|---|
| `GOOGLE_SERVICES_JSON_BASE64` | `base64 -i firebase/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `base64 -i firebase/GoogleService-Info.plist` |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/.config/myapp/upload.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | the key password |
| `ASC_KEY_ID` | App Store Connect API key ID |
| `ASC_ISSUER_ID` | App Store Connect issuer ID |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_<KEYID>.p8` |

Optional repo **variable** (not secret) `ANDROID_CERT_SHA256`: the upload
certificate's SHA-256; release builds signed with anything else fail.

Pipe the base64 straight into gh so it never lands on screen:
`base64 -i firebase/google-services.json | gh secret set GOOGLE_SERVICES_JSON_BASE64`.

### 6. Icons, name and stores

1. App icon: replace `assets/icon/app-icon.png` with your 1024x1024 PNG
   without transparency. The prepare scripts generate every size from it
   (`platform/icons/`).
2. Brand color: `brandSeedColor` in `lib/core/design_system/app_theme.dart`.
3. Texts: `lib/l10n/app_en.arb` (the template) and `app_pl.arb`.
4. Store records: Google Play Console app (package `APP_ID`) and the App Store
   Connect app record. Both ask for a privacy policy URL. Apple also requires
   in-app account deletion for apps that create accounts (guideline 5.1.1(v)),
   which the boilerplate does not include yet.
5. Target devices for screenshots: `widgetbook/devices.dart`.

## Everyday work

| Task | Command |
|---|---|
| Run on a device or simulator | `scripts/run.sh` (adds the Firebase config and build info) |
| Run in the browser (demo sign-in) | `scripts/run.sh -d chrome` |
| All checks (what CI and the pre-push hook run) | `scripts/check.sh` |
| Fix formatting | `scripts/check.sh --fix` |
| Render screenshots of every screen and component | `scripts/screenshots.sh` -> `test/screenshots/goldens/` |
| Component catalog | `flutter run -d chrome -t widgetbook/main.dart` |
| Release APK installed on connected phones | `scripts/dev/build_android.sh` |

Tests run with `-j 2` and screenshots with `-j 1`: running test files on
every core at once can exhaust the machine's memory.

The Flutter version is pinned in `pubspec.yaml` (`environment: flutter:`).
CI installs exactly that version and `scripts/check.sh` warns when yours
differs. To upgrade, change it there.

## Releases

- **CI** (`.github/workflows/ci.yml`, every push): quality (secrets, format,
  analyze, script tests, rename check), tests, screenshots (artifact), web
  preview of the app and the catalog (artifact).
- **Release** (`.github/workflows/release.yml`, manual): the signed Android
  APK, published as a GitHub prerelease `v<version>-build.<n>` from main, and
  the iOS IPA (unsigned archive, signed at export with Xcode cloud signing
  through the App Store Connect API key), uploaded to TestFlight when
  "testflight" is ticked.

Version: `version:` in `pubspec.yaml`. Build number: the commit count (plus
`BUILD_NUMBER_OFFSET` in `app.env`), the same on both platforms for the same
commit. The home screen shows version, build and commit.

Platform folders (`android/`, `ios/`, `web/`) are not committed: the
`scripts/ci/prepare_*.sh` scripts generate them with `flutter create` and
apply the settings from `app.env` and `platform/`. Commit them only if you
need native changes the scripts cannot make.

## Structure

```
app.env                  the app's identity (scripts/rename_app.sh changes it)
lib/
  main.dart              starts the app with production dependencies
  app/                   composition root: wiring (AppDependencies), Firebase start, auth gate
  core/                  config (build info, Firebase options), design system
  features/<feature>/
    domain/              pure Dart models and interfaces
    application/         ChangeNotifier controllers
    data/                adapters (Firebase, Google, Apple)
    presentation/        screens and widgets
  l10n/                  ARB files (English template + Polish)
test/                    mirrors lib/, plus architecture, l10n and screenshot tests
widgetbook/              component catalog; stories double as screenshot sources
firebase/                config file templates (real files are gitignored)
platform/                what the prepare scripts copy into generated platform folders
scripts/                 quality gate, rename, run, screenshots; ci/ and dev/ build scripts
docs/                    architecture, iOS setup
```

Rules and reasons: [docs/architecture.md](docs/architecture.md).
