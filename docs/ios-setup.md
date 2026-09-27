# iOS setup: TestFlight builds from GitHub Actions

The app is built for iPhone on a GitHub macOS runner by
`.github/workflows/release.yml` (tick "ios") and optionally uploaded to
TestFlight (tick "testflight"). Nothing needs to be built or signed on your
Mac.

## How signing works (and why)

The workflow uses Xcode cloud signing with an App Store Connect API key:

1. `scripts/ci/prepare_ios.sh` generates `ios/` with `flutter create`, sets
   the bundle ID and name from `app.env`, adds the Sign in with Apple
   entitlement (`platform/ios/Runner.entitlements`) and the Google Sign-In
   URL scheme, and sets your team for automatic signing.
2. `xcodebuild archive` builds the app. By default the archive is left
   unsigned.
3. `xcodebuild -exportArchive -allowProvisioningUpdates` with the API key
   signs the IPA. Xcode asks Apple for a cloud-managed distribution
   certificate and creates or refreshes the App Store provisioning profile
   on the fly.
4. `xcrun altool --upload-app` uploads the IPA with the same key. It appears
   in TestFlight after processing.

Why this and not fastlane match or a .p12 in secrets:

- One credential (the .p8 key) plus three IDs. No certificate, no private
  signing key, no provisioning profile, no keychain setup, no extra repo.
- The distribution certificate's private key never leaves Apple, so it
  cannot leak from CI and never needs exporting or renewing by hand.
- No fastlane or Ruby to maintain; everything is stock Xcode.

Downside: cloud signing needs a key with Admin rights (step 3) and fails with
"Cloud signing permission error" otherwise.

## Secrets

| Secret | What it is |
|---|---|
| `ASC_KEY_ID` | Key ID of the App Store Connect API key (10 characters) |
| `ASC_ISSUER_ID` | Issuer ID shown above the key list (a UUID) |
| `ASC_KEY_P8_BASE64` | The downloaded `AuthKey_<KEYID>.p8` file, base64 encoded |
| `APPLE_TEAM_ID` | Apple Developer Team ID (10 characters) |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `firebase/GoogleService-Info.plist`, base64 encoded (without it the build signs in in demo mode) |

## One-time steps

Needs an active Apple Developer Program membership. Use a desktop browser.
`APP_ID` and `APP_NAME` below are the values in `app.env`.

### 1. Register the bundle ID

1. https://developer.apple.com/account -> "Certificates, IDs & Profiles" ->
   "Identifiers" -> the blue "+".
2. "App IDs" -> Continue -> "App" -> Continue.
3. Description: `APP_NAME`. Bundle ID: "Explicit", `APP_ID`.
4. Capabilities: tick **Sign In with Apple**. Continue -> Register.

Do not create certificates or profiles by hand; cloud signing makes them.

### 2. Create the app record in App Store Connect

1. https://appstoreconnect.apple.com -> "Apps" -> "+" -> "New App".
2. Platform iOS, name `APP_NAME` (the store name must be unique across the
   whole store; the name under the icon comes from the app itself and stays
   `APP_NAME` either way), primary language, bundle ID `APP_ID`, SKU: the
   slug from `app.env`, User Access: Full Access.

### 3. Create the App Store Connect API key

1. App Store Connect -> "Users and Access" -> "Integrations" -> "App Store
   Connect API" -> "Team Keys". The first time, the Account Holder clicks
   "Request Access".
2. "+" -> name `<APP_NAME> CI`, Access **Admin** -> Generate.

Why Admin: uploading only needs App Manager, but cloud signing creates and
uses a cloud-managed distribution certificate, which Apple allows only for
Admin (or Account Holder). Use a Team Key, not an Individual Key: individual
keys cannot manage certificates and profiles.

### 4. Download the key and note the IDs

1. "Download" on the key row. **This works only once.** Keep the `.p8` in a
   password manager.
2. Key ID: the "Key ID" column. Issuer ID: above the key table.
3. Team ID: https://developer.apple.com/account -> "Membership details".

### 5. Store the secrets in GitHub

Replace the placeholders; piping keeps the key off the screen:

```sh
gh secret set ASC_KEY_ID     --body "<key id>"
gh secret set ASC_ISSUER_ID  --body "<issuer id>"
gh secret set APPLE_TEAM_ID  --body "<team id>"
base64 -i ~/Downloads/AuthKey_<KEYID>.p8 | gh secret set ASC_KEY_P8_BASE64
base64 -i firebase/GoogleService-Info.plist | gh secret set GOOGLE_SERVICE_INFO_PLIST_BASE64
gh secret list
```

Then delete the `.p8` from Downloads.

### 6. Internal TestFlight testers

App Store Connect -> the app -> "TestFlight" -> "Internal Testing" "+" ->
create a group, keep "Enable automatic distribution" on, add testers (they
must be users in "Users and Access"). Install TestFlight on the phone with
the same Apple ID.

## Running a build

1. GitHub -> Actions -> "Release" -> "Run workflow", or
   `gh workflow run release.yml -f android=false -f ios=true -f testflight=true`.
2. A run takes roughly 15-25 minutes of macOS time (billed 10x on private
   repos, so run it on purpose).
3. App Store Connect processes the upload for 5-30 minutes.
   `ITSAppUsesNonExemptEncryption = false` skips the export compliance
   question.
4. The IPA is kept for 7 days as the `ios-ipa` artifact.

Build number = commit count (+ `BUILD_NUMBER_OFFSET` in `app.env`); version
= `version:` in `pubspec.yaml`. Every upload of the same version needs a
higher build number, which new commits guarantee.

## Troubleshooting

- "Cloud signing permission error" / "No signing certificate iOS
  Distribution found": the key is not Admin, or it is an Individual Key.
- Export fails right after an unsigned archive: rerun with ios_signing
  `signed-archive`. Each fresh runner may create a new development
  certificate; revoke old "Created via API" ones now and then.
- "No suitable application records were found": the app record (step 2) is
  missing or uses another bundle ID.
- "The bundle version must be higher than the previously uploaded version":
  raise `BUILD_NUMBER_OFFSET` in `app.env` or bump `version:`.
- Google sign-in opens but never returns to the app: the URL scheme is
  missing. `prepare_ios.sh` warns about it; download
  `GoogleService-Info.plist` again after enabling Google sign-in in Firebase
  and update the secret.
- "SDK version issue" on upload: the runner's Xcode is too old; use a newer
  `macos-*` image in `runs-on`.

## Notes

- The minimum iOS version is raised to 15.0 (Firebase needs it); override
  with `MIN_IOS_VERSION`.
- The app is universal (iPhone and iPad), the `flutter create` default.
