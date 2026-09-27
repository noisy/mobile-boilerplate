import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = {'Nunito': 'assets/fonts/Nunito-OFL.txt'};

/// The bundled fonts are SIL OFL, which asks for the licence to ship with them.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: font, value: path) in _fontLicenses.entries) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(path));
    }
  });
}
