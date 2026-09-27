import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/auth/application/auth_controller.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';

import '../../../support/fake_auth_gateway.dart';

void main() {
  test('follows the gateway user', () async {
    final gateway = FakeAuthGateway();
    final auth = AuthController(gateway);
    addTearDown(auth.dispose);

    await auth.signIn(SignInProvider.google);
    await pumpEventQueue();

    expect(auth.user?.uid, googleUser.uid);
    expect(auth.busy, isFalse);
  });

  test('a canceled sign-in is not a failure', () async {
    final gateway = FakeAuthGateway()..accountUser = null;
    final auth = AuthController(gateway);
    addTearDown(auth.dispose);

    await auth.signIn(SignInProvider.apple);

    expect(auth.user, isNull);
    expect(auth.failed, isFalse);
  });

  test('marks the running task while it runs', () async {
    final auth = AuthController(FakeAuthGateway());
    addTearDown(auth.dispose);
    final tasks = <AuthTask?>[];
    auth.addListener(() => tasks.add(auth.task));

    await auth.continueWithoutAccount();

    expect(tasks.first, AuthTask.anonymous);
    expect(tasks.last, isNull);
  });

  test(
    'an account in use waits for a choice; staying keeps the user',
    () async {
      final gateway = FakeAuthGateway(signedIn: anonymousUser)
        ..takenBy = googleUser;
      final auth = AuthController(gateway);
      addTearDown(auth.dispose);

      await auth.link(SignInProvider.google);
      expect(auth.taken?.provider, SignInProvider.google);

      auth.stayOnThisAccount();

      expect(auth.taken, isNull);
      expect(auth.user?.uid, anonymousUser.uid);
    },
  );

  test('failures are reported and cleared by the next action', () async {
    final gateway = FakeAuthGateway()..offline = true;
    final auth = AuthController(gateway);
    addTearDown(auth.dispose);

    await auth.signIn(SignInProvider.google);
    expect(auth.failed, isTrue);

    gateway.offline = false;
    await auth.signIn(SignInProvider.google);
    expect(auth.failed, isFalse);
  });
}
