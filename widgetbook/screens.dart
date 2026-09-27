import 'package:flutter/widgets.dart';
import 'package:my_app/features/auth/application/auth_controller.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';
import 'package:my_app/features/auth/presentation/link_account_card.dart';
import 'package:my_app/features/auth/presentation/sign_in_screen.dart';
import 'package:my_app/features/home/presentation/home_screen.dart';

import 'sample_auth.dart';

/// A whole screen in one state, shown on every target device.
class ScreenStory {
  const ScreenStory(this.name, this.builder);

  final String name;
  final WidgetBuilder builder;
}

Widget _home(AuthController auth) => HomeScreen(
  auth: auth,
  buildLabel: 'v0.1.0 (42) · abc1234',
  accountPanel: LinkAccountCard(auth: auth),
);

final screenStories = <ScreenStory>[
  ScreenStory('Sign in', (_) => SignInScreen(auth: sampleAuth())),
  ScreenStory(
    'Sign in on Android',
    (_) => SignInScreen(
      auth: sampleAuth(providers: const [SignInProvider.google]),
    ),
  ),
  ScreenStory(
    'Sign in, demo mode',
    (_) => SignInScreen(auth: sampleAuth(demo: true)),
  ),
  ScreenStory('Home', (_) => _home(sampleAuth(user: sampleUser))),
  ScreenStory(
    'Home without an account',
    (_) => _home(sampleAuth(user: sampleAnonymousUser)),
  ),
  ScreenStory(
    'Home, account in use',
    (_) => _home(sampleAuth(user: sampleAnonymousUser, accountTaken: true)),
  ),
];
