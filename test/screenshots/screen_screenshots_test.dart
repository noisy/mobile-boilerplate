@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/l10n/localization.dart';

import '../../widgetbook/devices.dart';
import '../../widgetbook/screens.dart';
import 'screenshot_support.dart';

/// Every screen on every target device in every language, to catch
/// overflow and cramped layouts. A layout overflow fails the test, not
/// just the look. Run with: scripts/screenshots.sh
void main() {
  setUpAll(loadScreenshotFonts);

  for (final locale in supportedLocales) {
    for (final device in targetDevices) {
      for (final screen in screenStories) {
        testWidgets(
          '${locale.languageCode} / ${device.name} / ${screen.name}',
          (tester) async {
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = device.logicalSize * 2
              ..padding = FakeViewPadding(
                top: device.safeArea.top * 2,
                bottom: device.safeArea.bottom * 2,
              );
            addTearDown(tester.view.reset);

            await withRealShadows(() async {
              await tester.pumpWidget(
                screenshotApp(Builder(builder: screen.builder), locale: locale),
              );
              // Let state changes from the first frames finish animating.
              await tester.pump();
              await tester.pump(const Duration(seconds: 1));

              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile(
                  'goldens/screens/${locale.languageCode}/${slug(device.name)}/'
                  '${slug(screen.name)}.png',
                ),
              );
            });
          },
        );
      }
    }
  }
}
