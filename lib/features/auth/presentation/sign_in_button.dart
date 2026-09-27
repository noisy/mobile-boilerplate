import 'package:flutter/material.dart';

import '../../../l10n/localization.dart';
import '../domain/auth_user.dart';

/// "Continue with Google / Apple". Apple's guidelines ask for a black
/// button with its logo; Google's allow a plain outlined one.
class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.busy = false,
    this.label,
  });

  final SignInProvider provider;

  /// Null disables the button (another action is running).
  final VoidCallback? onPressed;
  final bool busy;

  /// Replaces "Continue with ..." (e.g. "Link Google").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = Text(label ?? context.l10n.signInWith(provider.brand));
    final icon = busy ? const _Spinner() : _ProviderLogo(provider);
    return switch (provider) {
      SignInProvider.apple => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black54,
          disabledForegroundColor: Colors.white70,
        ),
        onPressed: onPressed,
        icon: icon,
        label: text,
      ),
      SignInProvider.google => OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: text,
      ),
    };
  }
}

/// In the logo's place while signing in, in the button's text color.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: IconTheme.of(context).color,
    ),
  );
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo(this.provider);

  final SignInProvider provider;

  @override
  Widget build(BuildContext context) => switch (provider) {
    SignInProvider.apple => const Icon(Icons.apple),
    // A plain "G": the official logo is an asset each app adds itself.
    SignInProvider.google => const Text(
      'G',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  };
}
