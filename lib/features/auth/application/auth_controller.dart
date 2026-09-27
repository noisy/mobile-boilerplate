import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_gateway.dart';
import '../domain/auth_user.dart';
import '../domain/link_outcome.dart';

/// What the user is waiting for, so the right button shows a spinner.
enum AuthTask { google, apple, anonymous, link, switchAccount, signOut }

/// Signing in, linking an anonymous user to an account, and signing out.
/// Screens listen to it; the gateway does the actual work.
class AuthController extends ChangeNotifier {
  AuthController(this.gateway) : _user = gateway.currentUser {
    _subscription = gateway.userChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthGateway gateway;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? _user;
  AuthUser? get user => _user;

  AuthTask? _task;
  AuthTask? get task => _task;
  bool get busy => _task != null;

  bool _failed = false;

  /// The last action failed (network, misconfigured provider). Cleared by
  /// the next action.
  bool get failed => _failed;

  AccountTaken? _taken;

  /// Linking found the account already in use: the screen asks whether to
  /// switch to it ([switchToTakenAccount]) or stay ([stayOnThisAccount]).
  AccountTaken? get taken => _taken;

  Future<void> signIn(SignInProvider provider) => _run(
    provider == SignInProvider.google ? AuthTask.google : AuthTask.apple,
    () => gateway.signIn(provider),
  );

  Future<void> continueWithoutAccount() =>
      _run(AuthTask.anonymous, gateway.signInAnonymously);

  Future<void> link(SignInProvider provider) => _run(AuthTask.link, () async {
    switch (await gateway.link(provider)) {
      case LinkCanceled():
      case Linked():
        break;
      case final AccountTaken taken:
        _taken = taken;
    }
  });

  Future<void> switchToTakenAccount() async {
    final taken = _taken;
    if (taken == null) return;
    _taken = null;
    await _run(AuthTask.switchAccount, () => gateway.signInAsTaken(taken));
  }

  void stayOnThisAccount() {
    _taken = null;
    notifyListeners();
  }

  Future<void> signOut() => _run(AuthTask.signOut, gateway.signOut);

  Future<void> _run(AuthTask task, Future<void> Function() action) async {
    if (busy) return;
    _task = task;
    _failed = false;
    notifyListeners();
    try {
      await action();
    } on Exception catch (e) {
      debugPrint('Auth ${task.name} failed: $e');
      _failed = true;
    } finally {
      _task = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
