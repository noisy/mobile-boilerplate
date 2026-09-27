/// Which build this is. Stamped by CI (scripts/ci/build_flags.sh); local
/// runs show "dev".
abstract final class BuildInfo {
  static const version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'dev',
  );
  static const build = String.fromEnvironment('APP_BUILD');
  static const commit = String.fromEnvironment('APP_COMMIT');

  /// e.g. "v0.1.0 (235) · 1a2b3c4", matching the git tag v0.1.0-build.235.
  static String label({
    String version = BuildInfo.version,
    String build = BuildInfo.build,
    String commit = BuildInfo.commit,
  }) => [
    'v$version',
    if (build.isNotEmpty) '($build)',
    if (commit.isNotEmpty) '· $commit',
  ].join(' ');
}
