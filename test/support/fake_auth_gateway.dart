import 'dart:async';

import 'package:my_app/features/auth/domain/auth_gateway.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';
import 'package:my_app/features/auth/domain/link_outcome.dart';

const googleUser = AuthUser(
  uid: 'google-uid',
  name: 'Alex Morgan',
  email: 'alex@example.org',
  providers: {SignInProvider.google},
);

const anonymousUser = AuthUser(uid: 'anonymous-uid', isAnonymous: true);

/// Sign-in that answers what the test tells it to.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    AuthUser? signedIn,
    this.providers = SignInProvider.values,
    this.isDemo = false,
  }) : _user = signedIn;

  final List<SignInProvider> providers;

  @override
  final bool isDemo;

  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  /// Who signing in with a provider becomes; null = the user cancels.
  AuthUser? accountUser = googleUser;

  /// The user behind the account when linking finds it taken; null links.
  AuthUser? takenBy;

  /// Every call fails, as without network.
  bool offline = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  List<SignInProvider> get availableProviders => providers;

  @override
  Future<AuthUser?> signIn(SignInProvider provider) async {
    _checkOnline();
    final user = accountUser;
    return user == null ? null : _set(user);
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    _checkOnline();
    return _set(anonymousUser);
  }

  @override
  Future<LinkOutcome> link(SignInProvider provider) async {
    _checkOnline();
    final user = _user!;
    if (accountUser == null) return const LinkCanceled();
    if (takenBy case final owner?) return AccountTaken(provider, owner);
    return Linked(
      _set(
        AuthUser(
          uid: user.uid,
          name: accountUser!.name,
          email: accountUser!.email,
          providers: {provider},
        ),
      ),
    );
  }

  @override
  Future<AuthUser> signInAsTaken(AccountTaken taken) async =>
      _set(taken.handle as AuthUser);

  @override
  Future<void> signOut() async {
    _checkOnline();
    _set(null);
  }

  void _checkOnline() {
    if (offline) throw Exception('offline');
  }

  T _set<T extends AuthUser?>(T user) {
    _user = user;
    _changes.add(user);
    return user;
  }
}
