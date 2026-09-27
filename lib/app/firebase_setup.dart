import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/config/firebase_config.dart';
import '../features/auth/data/demo_auth_gateway.dart';
import '../features/auth/data/firebase_auth_gateway.dart';
import '../features/auth/domain/auth_gateway.dart';

/// Starts Firebase where this build has its config (Android, iOS) and
/// returns the matching sign-in; demo sign-in everywhere else (no config,
/// web preview, desktop).
Future<AuthGateway> startAuth() async {
  final options = FirebaseConfig.currentPlatform;
  if (options == null) return DemoAuthGateway();
  try {
    await Firebase.initializeApp(options: options);
  } on Object catch (e) {
    debugPrint('Firebase unavailable, using demo sign-in: $e');
    return DemoAuthGateway();
  }
  return FirebaseAuthGateway(
    googleServerClientId: FirebaseConfig.googleServerClientId,
    googleIosClientId: FirebaseConfig.googleIosClientId,
  );
}
