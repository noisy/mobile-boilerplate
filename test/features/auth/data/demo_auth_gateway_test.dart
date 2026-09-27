import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/auth/data/demo_auth_gateway.dart';
import 'package:my_app/features/auth/domain/auth_user.dart';
import 'package:my_app/features/auth/domain/link_outcome.dart';

void main() {
  test('linking keeps the anonymous uid', () async {
    final gateway = DemoAuthGateway();
    final anonymous = await gateway.signInAnonymously();

    final outcome = await gateway.link(SignInProvider.apple);

    expect(outcome, isA<Linked>());
    final linked = (outcome as Linked).user;
    expect(linked.uid, anonymous.uid);
    expect(linked.isAnonymous, isFalse);
    expect(linked.providers, {SignInProvider.apple});
  });

  test('signing out clears the user and tells listeners', () async {
    final gateway = DemoAuthGateway();
    await gateway.signIn(SignInProvider.google);
    final changes = gateway.userChanges.first;

    await gateway.signOut();

    expect(await changes, isNull);
    expect(gateway.currentUser, isNull);
  });
}
