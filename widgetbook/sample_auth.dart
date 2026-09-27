import 'dart:async';

import 'package:my_app/features/auth/application/auth_controller.dart';
import 'package:my_app/features/auth/domain/auth_gateway.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';
import 'package:my_app/features/auth/domain/link_outcome.dart';

const sampleUser = AuthUser(
  uid: 'sample',
  name: 'Alex Morgan',
  email: 'alex@example.org',
  providers: {SignInProvider.google},
);

const sampleAnonymousUser = AuthUser(uid: 'anonymous', isAnonymous: true);

/// An auth controller frozen in one state, for stories and screenshots.
AuthController sampleAuth({
  AuthUser? user,
  bool demo = false,
  bool accountTaken = false,
  List<SignInProvider> providers = SignInProvider.values,
}) {
  final auth = AuthController(_SampleGateway(user, demo, providers));
  if (accountTaken) unawaited(auth.link(SignInProvider.google));
  return auth;
}

/// Answers instantly and never changes who is signed in, so each story
/// stays in the state it shows. Linking always finds the account taken.
class _SampleGateway implements AuthGateway {
  _SampleGateway(this.currentUser, this.isDemo, this.availableProviders);

  @override
  final AuthUser? currentUser;

  @override
  final bool isDemo;

  @override
  final List<SignInProvider> availableProviders;

  @override
  Stream<AuthUser?> get userChanges => const Stream.empty();

  @override
  Future<AuthUser?> signIn(SignInProvider provider) async => currentUser;

  @override
  Future<AuthUser> signInAnonymously() async => sampleAnonymousUser;

  @override
  Future<LinkOutcome> link(SignInProvider provider) async =>
      AccountTaken(provider, sampleUser);

  @override
  Future<AuthUser> signInAsTaken(AccountTaken taken) async => sampleUser;

  @override
  Future<void> signOut() async {}
}
