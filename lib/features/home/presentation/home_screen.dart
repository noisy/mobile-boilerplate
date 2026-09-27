import 'package:flutter/material.dart';

import '../../../core/design_system/widgets/content_column.dart';
import '../../../core/design_system/widgets/user_avatar.dart';
import '../../../l10n/localization.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';

/// Who is signed in, and signing out. The example feature: replace it with
/// the app's real first screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.buildLabel,
    this.accountPanel,
  });

  final AuthController auth;

  /// Shown under the user, e.g. linking an account. Built by lib/app, as
  /// features never import each other's widgets.
  final Widget? accountPanel;

  /// Version, build and commit (BuildInfo.label()).
  final String buildLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            final user = auth.user;
            if (user == null) return const SizedBox.shrink();
            return ContentColumn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserHeader(user),
                  const SizedBox(height: 32),
                  ?accountPanel,
                  const Spacer(),
                  if (auth.failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.authFailed,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: auth.busy ? null : auth.signOut,
                    child: Text(l10n.signOut),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.buildLabel(buildLabel),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader(this.user);

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = user.name;
    return Column(
      children: [
        UserAvatar(name: name),
        const SizedBox(height: 16),
        Text(
          name == null || name.isEmpty
              ? l10n.homeGreetingAnonymous
              : l10n.homeGreeting(name),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (user.email case final email?) ...[
          const SizedBox(height: 4),
          Text(email, style: theme.textTheme.bodyLarge),
        ],
        if (user.providers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.signedInWith(user.providers.map((p) => p.brand).join(', ')),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
