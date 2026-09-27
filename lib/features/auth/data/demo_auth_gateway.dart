import 'dart:async';

import '../domain/auth_gateway.dart';
import '../domain/auth_user.dart';
import '../domain/link_outcome.dart';

/// Pretends to sign in, on the device only. Used when the build has no
/// Firebase config (see firebase/README.md), so the app and the web preview
/// work before a Firebase project exists. Nothing survives a restart.
class DemoAuthGateway implements AuthGateway {
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  var _nextId = 1;

  @override
  bool get isDemo => true;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  List<SignInProvider> get availableProviders => SignInProvider.values;

  @override
  Future<AuthUser?> signIn(SignInProvider provider) async =>
      _set(_accountUser('demo-${_nextId++}', provider));

  @override
  Future<AuthUser> signInAnonymously() async =>
      _set(AuthUser(uid: 'demo-${_nextId++}', isAnonymous: true));

  @override
  Future<LinkOutcome> link(SignInProvider provider) async {
    final user = _user;
    if (user == null) throw StateError('Nobody is signed in to link');
    return Linked(_set(_accountUser(user.uid, provider)));
  }

  @override
  Future<AuthUser> signInAsTaken(AccountTaken taken) async =>
      _set(taken.handle as AuthUser);

  @override
  Future<void> signOut() async => _set(null);

  static AuthUser _accountUser(String uid, SignInProvider provider) => AuthUser(
    uid: uid,
    name: 'Demo User',
    email: 'demo.user@example.com',
    providers: {provider},
  );

  T _set<T extends AuthUser?>(T user) {
    _user = user;
    _changes.add(user);
    return user;
  }
}
