import 'package:flutter/material.dart';

import '../core/design_system/app_theme.dart';
import '../features/auth/presentation/link_account_card.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../l10n/localization.dart';
import 'app_dependencies.dart';

class App extends StatelessWidget {
  const App({super.key, required this.dependencies, this.locale});

  final AppDependencies dependencies;

  /// Forces a language (tests); null follows the device.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      home: _AuthGate(dependencies),
    );
  }
}

/// Sign-in screen without a user, the home screen with one.
class _AuthGate extends StatelessWidget {
  const _AuthGate(this.dependencies);

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    final auth = dependencies.auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => auth.user == null
          ? SignInScreen(auth: auth)
          : HomeScreen(
              auth: auth,
              buildLabel: dependencies.buildLabel,
              accountPanel: LinkAccountCard(auth: auth),
            ),
    );
  }
}
