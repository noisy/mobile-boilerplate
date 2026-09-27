import 'package:flutter/widgets.dart';

/// Devices every screen is checked on: in Widgetbook and in the golden
/// screenshots (test/screenshots/). Add your users' real devices here.
class TargetDevice {
  const TargetDevice(
    this.name,
    this.logicalSize,
    this.pixelRatio, {
    this.safeArea = EdgeInsets.zero,
  });

  final String name;
  final Size logicalSize;
  final double pixelRatio;

  /// Status bar / notch / home indicator insets, in logical pixels.
  final EdgeInsets safeArea;
}

const targetDevices = [
  // A small Android phone: 1080x2400 px at 440 dpi.
  TargetDevice(
    'Android phone',
    Size(392.7, 872.7),
    2.75,
    safeArea: EdgeInsets.only(top: 30, bottom: 12),
  ),
  // 1179x2556 px, Dynamic Island and home indicator.
  TargetDevice(
    'iPhone 16',
    Size(393, 852),
    3,
    safeArea: EdgeInsets.only(top: 59, bottom: 34),
  ),
  // A tablet, to catch layouts that only work at phone width.
  TargetDevice(
    'iPad 11 inch',
    Size(834, 1194),
    2,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
  ),
];
