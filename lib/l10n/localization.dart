import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart' show AppLocalizations;

/// Languages the app speaks. Adding one = adding `lib/l10n/app_<code>.arb`.
const supportedLocales = AppLocalizations.supportedLocales;

const localizationsDelegates = AppLocalizations.localizationsDelegates;

extension Localized on BuildContext {
  /// The texts in the current language: `context.l10n.signOut`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
