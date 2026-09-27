/// An account the user can sign in or link with.
enum SignInProvider {
  google('Google'),
  apple('Apple');

  const SignInProvider(this.brand);

  /// The company's name, the same in every language.
  final String brand;
}

/// Who is signed in on this device.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.name,
    this.isAnonymous = false,
    this.providers = const {},
  });

  final String uid;
  final String? email;
  final String? name;

  /// Started with "Continue without an account", until linked to Google
  /// or Apple.
  final bool isAnonymous;

  /// The accounts linked to this user, for "Linked: Google".
  final Set<SignInProvider> providers;
}
