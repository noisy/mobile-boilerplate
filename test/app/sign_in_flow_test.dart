import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_gateway.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('sign in with Google, see the user, sign out', (tester) async {
    await tester.pumpApp(FakeAuthGateway());

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Alex Morgan!'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);
    expect(find.text('Build v0.1.0 (42) · abc1234'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('continue without an account, then link Google', (tester) async {
    await tester.pumpApp(FakeAuthGateway());

    await tester.tap(find.text('Continue without an account'));
    await tester.pumpAndSettle();
    expect(find.text('Hi there!'), findsOneWidget);

    await tester.tap(find.text('Link Google'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Alex Morgan!'), findsOneWidget);
    expect(find.text('Link Google'), findsNothing);
  });

  testWidgets('linking an account in use asks, then switches to it', (
    tester,
  ) async {
    final gateway = FakeAuthGateway(signedIn: anonymousUser)
      ..takenBy = googleUser;
    await tester.pumpApp(gateway);

    await tester.tap(find.text('Link Google'));
    await tester.pumpAndSettle();
    expect(find.text('Account already in use'), findsOneWidget);

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(gateway.currentUser?.uid, googleUser.uid);
    expect(find.text('Hi, Alex Morgan!'), findsOneWidget);
  });

  testWidgets('a failed sign-in says so and stays on the sign-in screen', (
    tester,
  ) async {
    await tester.pumpApp(FakeAuthGateway()..offline = true);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('demo builds say that sign-in is simulated', (tester) async {
    await tester.pumpApp(FakeAuthGateway(isDemo: true));

    expect(find.textContaining('Demo mode'), findsOneWidget);
  });

  testWidgets('speaks Polish', (tester) async {
    await tester.pumpApp(FakeAuthGateway(), locale: const Locale('pl'));

    expect(find.text('Kontynuuj bez konta'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
