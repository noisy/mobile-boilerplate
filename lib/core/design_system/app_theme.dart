import 'package:flutter/material.dart';

/// The one brand color; Material 3 derives the rest of the palette from it.
const brandSeedColor = Color(0xFF3F51B5);

/// The app's font, bundled in assets/fonts (SIL OFL).
const appFontFamily = 'Nunito';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final colors = ColorScheme.fromSeed(
    seedColor: brandSeedColor,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: colors,
    fontFamily: appFontFamily,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    ),
  );
}
