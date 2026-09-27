import 'package:flutter/material.dart';

import '../../../core/design_system/widgets/content_column.dart';
import '../../../l10n/localization.dart';
import '../application/auth_controller.dart';
import 'sign_in_button.dart';

/// The first screen without a signed-in user: Google, Apple (iOS) or no
/// account at all.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) => ContentColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.gateway.isDemo) const _DemoModeNotice(),
                const Spacer(),
                Icon(
                  Icons.lock_person_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                for (final provider in auth.gateway.availableProviders) ...[
                  SignInButton(
                    provider: provider,
                    busy: auth.task?.name == provider.name,
                    onPressed: auth.busy ? null : () => auth.signIn(provider),
                  ),
                  const SizedBox(height: 12),
                ],
                TextButton(
                  onPressed: auth.busy ? null : auth.continueWithoutAccount,
                  child: Text(l10n.continueWithoutAccount),
                ),
                if (auth.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.authFailed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoModeNotice extends StatelessWidget {
  const _DemoModeNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.science_outlined, color: colors.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.demoModeNotice,
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
