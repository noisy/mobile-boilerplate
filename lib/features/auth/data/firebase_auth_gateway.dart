import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_gateway.dart';
import '../domain/auth_user.dart';
import '../domain/link_outcome.dart';

/// Firebase Auth with Google (Android, iOS) and Apple (iOS) sign-in,
/// anonymous users, and linking an anonymous user to either (same uid,
/// nothing copied).
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({
    required this.googleServerClientId,
    this.googleIosClientId,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The OAuth web client of the Firebase project; Android asks Google for
  /// an ID token for it.
  final String googleServerClientId;
  final String? googleIosClientId;
  Future<void>? _googleReady;

  @override
  bool get isDemo => false;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges => _auth.userChanges().map(_toUser);

  /// Sign in with Apple is native on iPhone and iPad only. Android and web
  /// need an Apple Services ID and a web flow (see README).
  @override
  List<SignInProvider> get availableProviders => [
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
      SignInProvider.apple,
    SignInProvider.google,
  ];

  @override
  Future<AuthUser?> signIn(SignInProvider provider) async {
    switch (provider) {
      case SignInProvider.google:
        final credential = await _googleCredential();
        if (credential == null) return null;
        return _toUser((await _auth.signInWithCredential(credential)).user);
      case SignInProvider.apple:
        try {
          return _toUser(
            (await _auth.signInWithProvider(_appleProvider())).user,
          );
        } on FirebaseAuthException catch (e) {
          if (_canceled(e)) return null;
          rethrow;
        }
    }
  }

  /// Null when the user cancels.
  Future<OAuthCredential?> _googleCredential() async {
    final google = GoogleSignIn.instance;
    await (_googleReady ??= google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? googleIosClientId
          : null,
      serverClientId: googleServerClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    return GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
  }

  @override
  Future<LinkOutcome> link(SignInProvider provider) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Nobody is signed in to link');
    switch (provider) {
      case SignInProvider.google:
        final credential = await _googleCredential();
        if (credential == null) return const LinkCanceled();
        try {
          return Linked(
            _toUser((await user.linkWithCredential(credential)).user)!,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code != 'credential-already-in-use') rethrow;
          return AccountTaken(provider, e.credential ?? credential);
        }
      case SignInProvider.apple:
        try {
          return Linked(
            _toUser((await user.linkWithProvider(_appleProvider())).user)!,
          );
        } on FirebaseAuthException catch (e) {
          if (_canceled(e)) return const LinkCanceled();
          if (e.code != 'credential-already-in-use' || e.credential == null) {
            rethrow;
          }
          return AccountTaken(provider, e.credential!);
        }
    }
  }

  @override
  Future<AuthUser> signInAsTaken(AccountTaken taken) async {
    final result = await _auth.signInWithCredential(
      taken.handle as AuthCredential,
    );
    return _toUser(result.user)!;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    return _toUser(result.user)!;
  }

  @override
  Future<void> signOut() async {
    if (_googleReady != null) {
      await GoogleSignIn.instance.signOut().catchError((Object _) {});
    }
    await _auth.signOut();
  }

  static AppleAuthProvider _appleProvider() =>
      AppleAuthProvider()..addScope('email');

  static bool _canceled(FirebaseAuthException e) =>
      e.code == 'canceled' || e.code == 'web-context-canceled';

  static AuthUser? _toUser(User? user) => user == null
      ? null
      : AuthUser(
          uid: user.uid,
          email: user.email,
          name: user.displayName,
          isAnonymous: user.isAnonymous,
          providers: {
            for (final info in user.providerData)
              ?switch (info.providerId) {
                'google.com' => SignInProvider.google,
                'apple.com' => SignInProvider.apple,
                _ => null,
              },
          },
        );
}
