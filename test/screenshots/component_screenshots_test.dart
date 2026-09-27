@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../widgetbook/stories.dart';
import 'screenshot_support.dart';

/// The narrowest target phone.
const _componentCanvasWidth = 360.0;

/// Renders every Widgetbook story to a PNG with the real fonts.
/// Run with: scripts/screenshots.sh
void main() {
  setUpAll(loadScreenshotFonts);

  for (final story in stories) {
    testWidgets('${story.folder} / ${story.component} / ${story.state}', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 2
        ..physicalSize = Size(_componentCanvasWidth, story.height) * 2;
      addTearDown(tester.view.reset);

      await withRealShadows(() async {
        await tester.pumpWidget(
          screenshotApp(
            Builder(
              builder: (context) => ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: story.builder(context)),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(story.screenshotPath),
        );
      });
    });
  }
}
