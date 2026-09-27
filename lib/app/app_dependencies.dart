import '../core/config/build_info.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_gateway.dart';
import 'firebase_setup.dart';

/// Composition root: the one place that picks concrete implementations.
/// Tests build their own instance with fakes (test/support/).
class AppDependencies {
  AppDependencies({required AuthGateway authGateway, String? buildLabel})
    : auth = AuthController(authGateway),
      buildLabel = buildLabel ?? BuildInfo.label();

  static Future<AppDependencies> production() async =>
      AppDependencies(authGateway: await startAuth());

  final AuthController auth;

  /// Version, build and commit, for the home screen.
  final String buildLabel;
}
