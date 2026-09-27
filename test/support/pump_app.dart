import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/app/app_dependencies.dart';
import 'package:my_app/core/design_system/app_theme.dart';
import 'package:my_app/l10n/localization.dart';

import 'fake_auth_gateway.dart';

/// A typical phone in portrait, in logical pixels.
const phoneSize = Size(412, 915);

extension PumpInApp on WidgetTester {
  /// Makes the test screen phone-sized for the rest of the test.
  void usePhoneScreen() {
    view.physicalSize = phoneSize * view.devicePixelRatio;
    addTearDown(view.reset);
  }

  /// Pumps the whole app with [gateway], on a phone-sized screen.
  Future<AppDependencies> pumpApp(
    FakeAuthGateway gateway, {
    Locale locale = const Locale('en'),
  }) async {
    usePhoneScreen();
    final dependencies = AppDependencies(
      authGateway: gateway,
      buildLabel: 'v0.1.0 (42) · abc1234',
    );
    await pumpWidget(App(dependencies: dependencies, locale: locale));
    return dependencies;
  }

  /// Pumps [screen] on a phone-sized screen with the real theme.
  Future<void> pumpScreen(Widget screen, {Locale locale = const Locale('en')}) {
    usePhoneScreen();
    return pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        home: screen,
      ),
    );
  }
}
