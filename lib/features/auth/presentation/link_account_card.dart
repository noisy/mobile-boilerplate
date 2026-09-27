import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../application/auth_controller.dart';
import 'sign_in_button.dart';

/// For anonymous users: link Google or Apple and keep everything (same
/// uid). Asks before switching when the account already has a user.
/// Shows nothing for users with an account.
class LinkAccountCard extends StatelessWidget {
  const LinkAccountCard({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (auth.user?.isAnonymous != true) return const SizedBox.shrink();
        final l10n = context.l10n;
        final taken = auth.taken;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.anonymousHint),
                    for (final provider in auth.gateway.availableProviders) ...[
                      const SizedBox(height: 12),
                      SignInButton(
                        provider: provider,
                        label: l10n.linkWith(provider.brand),
                        busy: auth.task == AuthTask.link,
                        onPressed: auth.busy ? null : () => auth.link(provider),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (taken != null)
              _AccountTakenPrompt(
                title: l10n.accountTakenTitle,
                body: l10n.accountTakenBody(taken.provider.brand),
                onSwitch: auth.switchToTakenAccount,
                onStay: auth.stayOnThisAccount,
              ),
          ],
        );
      },
    );
  }
}

/// Inline rather than a dialog, so it survives rebuilds and needs no
/// navigation state.
class _AccountTakenPrompt extends StatelessWidget {
  const _AccountTakenPrompt({
    required this.title,
    required this.body,
    required this.onSwitch,
    required this.onStay,
  });

  final String title;
  final String body;
  final VoidCallback onSwitch;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onStay, child: Text(l10n.stayOnAccount)),
                TextButton(
                  onPressed: onSwitch,
                  child: Text(l10n.switchAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
