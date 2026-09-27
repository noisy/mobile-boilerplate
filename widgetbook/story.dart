import 'package:flutter/widgets.dart';

/// One component in one state. The single source for both the Widgetbook
/// catalog and the screenshot tests, so every state you can browse is also
/// captured as a PNG.
class Story {
  const Story({
    required this.folder,
    required this.component,
    required this.state,
    required this.builder,
    this.height = 260,
  });

  final String folder;
  final String component;
  final String state;
  final WidgetBuilder builder;

  /// Height of the screenshot canvas, in logical pixels (width is a phone).
  final double height;

  String get screenshotPath =>
      'goldens/components/${_slug(component)}/${_slug(state)}.png';
}

String _slug(String text) => text
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');
