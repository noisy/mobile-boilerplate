// Component catalog (Flutter's Storybook). Run it with:
//   flutter run -d chrome -t widgetbook/main.dart
import 'package:flutter/material.dart';
import 'package:my_app/core/design_system/app_theme.dart';
import 'package:my_app/l10n/localization.dart';
import 'package:widgetbook/widgetbook.dart';

import 'devices.dart';
import 'screens.dart';
import 'stories.dart';
import 'story.dart';

void main() => runApp(const AppWidgetbook());

class AppWidgetbook extends StatelessWidget {
  const AppWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [..._directories(stories), _screensFolder()],
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: buildAppTheme()),
            WidgetbookTheme(
              name: 'Dark',
              data: buildAppTheme(brightness: Brightness.dark),
            ),
          ],
        ),
        LocalizationAddon(
          locales: supportedLocales,
          localizationsDelegates: localizationsDelegates,
        ),
        AlignmentAddon(),
      ],
    );
  }
}

/// Groups stories into folder > component > state, as Widgetbook shows them.
List<WidgetbookNode> _directories(List<Story> stories) {
  final folders = <String, Map<String, List<Story>>>{};
  for (final story in stories) {
    folders
        .putIfAbsent(story.folder, () => {})
        .putIfAbsent(story.component, () => [])
        .add(story);
  }
  return [
    for (final MapEntry(key: folder, value: components) in folders.entries)
      WidgetbookFolder(
        name: folder,
        children: [
          for (final MapEntry(key: component, value: states)
              in components.entries)
            WidgetbookComponent(
              name: component,
              useCases: [
                for (final story in states)
                  WidgetbookUseCase(
                    name: story.state,
                    builder: (context) => ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(child: story.builder(context)),
                    ),
                  ),
              ],
            ),
        ],
      ),
  ];
}

/// Every screen on every target device, at the device's real logical size.
WidgetbookFolder _screensFolder() => WidgetbookFolder(
  name: 'Screens',
  children: [
    for (final screen in screenStories)
      WidgetbookComponent(
        name: screen.name,
        useCases: [
          for (final device in targetDevices)
            WidgetbookUseCase(
              name: device.name,
              builder: (context) => Center(
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: device.logicalSize,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: device.logicalSize,
                        padding: device.safeArea,
                        viewPadding: device.safeArea,
                      ),
                      child: Builder(builder: screen.builder),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
  ],
);
