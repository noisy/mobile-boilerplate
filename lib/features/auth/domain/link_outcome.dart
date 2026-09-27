import 'auth_user.dart';

/// What happened when linking the current user to Google or Apple.
sealed class LinkOutcome {
  const LinkOutcome();
}

/// The user closed the sign-in sheet.
class LinkCanceled extends LinkOutcome {
  const LinkCanceled();
}

/// Same user as before (same uid, same data), now with an account.
class Linked extends LinkOutcome {
  const Linked(this.user);

  final AuthUser user;
}

/// The account already belongs to another user. [handle] signs in as that
/// user ([AuthGateway.signInAsTaken]); the anonymous user is left behind.
class AccountTaken extends LinkOutcome {
  const AccountTaken(this.provider, this.handle);

  final SignInProvider provider;

  /// Opaque to everything but the gateway that made it.
  final Object handle;
}
