import 'auth_user.dart';
import 'link_outcome.dart';

/// Signing in, backed by Firebase Auth in the app, a local simulation in
/// demo mode and a fake in tests.
abstract interface class AuthGateway {
  AuthUser? get currentUser;
  Stream<AuthUser?> get userChanges;

  /// Whether sign-in only pretends (no Firebase config in this build).
  bool get isDemo;

  /// The providers this device offers, in the order the buttons show.
  List<SignInProvider> get availableProviders;

  /// Null when the user cancels.
  Future<AuthUser?> signIn(SignInProvider provider);

  /// "Continue without an account".
  Future<AuthUser> signInAnonymously();

  /// Links the signed-in (anonymous) user to [provider]: same uid, so
  /// everything saved under it stays.
  Future<LinkOutcome> link(SignInProvider provider);

  /// Signs in as the user behind [taken], leaving the current user.
  Future<AuthUser> signInAsTaken(AccountTaken taken);

  Future<void> signOut();
}
