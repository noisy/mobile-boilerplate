# Working in this repo

- Read `docs/architecture.md` before adding code; `test/architecture_test.dart` enforces the layers.
- One quality gate: `scripts/check.sh` (the pre-push hook and CI run the same).
- Memory: run `flutter test -j 2` (screenshots `-j 1` via `scripts/screenshots.sh`), never two
  Flutter commands at once, and keep command output short.
- Every new English text gets an `@key` description in `lib/l10n/app_en.arb` and a translation
  in every other ARB file.
- New widget -> a story in `widgetbook/stories.dart`; new screen -> `widgetbook/screens.dart`.
  Both become screenshots; look at them before calling UI work done.
- Never commit keys, keystores or Firebase config files (`scripts/check_no_secrets.sh` blocks them).
- The app's name and ids live in `app.env`; change them only with `scripts/rename_app.sh`.
