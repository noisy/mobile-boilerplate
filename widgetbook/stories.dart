import 'package:my_app/core/design_system/widgets/user_avatar.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';
import 'package:my_app/features/auth/presentation/sign_in_button.dart';

import 'story.dart';

/// Every component state in the catalog. Add a story next to each new
/// widget: it shows up in Widgetbook and in the component screenshots.
final stories = <Story>[
  for (final provider in SignInProvider.values) ...[
    Story(
      folder: 'Auth',
      component: 'SignInButton',
      state: provider.brand,
      height: 120,
      builder: (_) => SignInButton(provider: provider, onPressed: () {}),
    ),
    Story(
      folder: 'Auth',
      component: 'SignInButton',
      state: '${provider.brand} busy',
      height: 120,
      builder: (_) =>
          SignInButton(provider: provider, busy: true, onPressed: null),
    ),
  ],
  Story(
    folder: 'Auth',
    component: 'SignInButton',
    state: 'Link label',
    height: 120,
    builder: (_) => SignInButton(
      provider: SignInProvider.google,
      label: 'Link Google',
      onPressed: () {},
    ),
  ),
  Story(
    folder: 'Design system',
    component: 'UserAvatar',
    state: 'With name',
    height: 120,
    builder: (_) => const UserAvatar(name: 'Alex Morgan'),
  ),
  Story(
    folder: 'Design system',
    component: 'UserAvatar',
    state: 'Anonymous',
    height: 120,
    builder: (_) => const UserAvatar(),
  ),
];
