import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the layering honest as the app grows. See docs/architecture.md.
///
/// lib/app          composition root, may import anything
/// lib/core         shared building blocks, never imports features or app
/// lib/features/FEATURE/domain        pure Dart rules and models
/// lib/features/FEATURE/application   state and use cases
/// lib/features/FEATURE/data          adapters to the outside world
/// lib/features/FEATURE/presentation  widgets
void main() {
  final package = _packageName();
  final sources = _libSources(package);

  test('domain code is pure Dart', () {
    final violations = [
      for (final file in sources.where((f) => f.layer == 'domain'))
        for (final import in file.imports)
          if (import.startsWith('package:') &&
              !import.startsWith('package:$package/'))
            '${file.path} imports $import',
    ];
    expect(violations, isEmpty);
  });

  test('each layer only depends on the layers it is allowed to', () {
    const allowed = {
      'domain': {'domain', 'core'},
      'application': {'domain', 'application', 'core'},
      'data': {'domain', 'data', 'core'},
      'presentation': {'domain', 'application', 'presentation', 'core', 'l10n'},
      'core': {'core'},
    };
    final violations = <String>[];
    for (final file in sources) {
      final allowedTargets = allowed[file.layer];
      if (allowedTargets == null) continue;
      for (final target in file.localImports) {
        final targetLayer = _layerOf(target);
        final crossFeature =
            _featureOf(target) != null &&
            file.feature != null &&
            _featureOf(target) != file.feature;
        if (targetLayer == 'app' ||
            !allowedTargets.contains(targetLayer) ||
            (crossFeature && targetLayer == 'presentation')) {
          violations.add('${file.path} (${file.layer}) imports $target');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('domain code does not import Flutter UI or I/O', () {
    final violations = [
      for (final file in sources.where((f) => f.layer == 'domain'))
        for (final import in file.imports)
          if (import == 'dart:io' || import == 'dart:ui')
            '${file.path} imports $import',
    ];
    expect(violations, isEmpty);
  });
}

class _Source {
  _Source(this.path, this.imports, this.package);

  final String path;
  final List<String> imports;
  final String package;

  String get layer => _layerOf(path);
  String? get feature => _featureOf(path);

  /// Imports inside this package, as paths relative to the repo root.
  Iterable<String> get localImports sync* {
    for (final import in imports) {
      if (import.startsWith('package:$package/')) {
        yield 'lib/${import.substring('package:$package/'.length)}';
      } else if (!import.contains(':')) {
        yield File(path).parent.uri.resolve(import).path;
      }
    }
  }
}

final _importPattern = RegExp(
  r'''^(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// The `name:` in pubspec.yaml, so the test survives scripts/rename_app.sh.
String _packageName() => RegExp(
  r'^name:\s*(\S+)',
  multiLine: true,
).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

List<_Source> _libSources(String package) => [
  for (final entity in Directory('lib').listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart'))
      _Source(
        entity.path,
        _importPattern
            .allMatches(entity.readAsStringSync())
            .map((match) => match.group(1)!)
            .toList(),
        package,
      ),
];

String _layerOf(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.contains('lib/app/')) return 'app';
  if (normalized.contains('lib/core/')) return 'core';
  if (normalized.contains('lib/l10n/')) return 'l10n';
  for (final layer in ['domain', 'application', 'data', 'presentation']) {
    if (normalized.contains('/$layer/')) return layer;
  }
  return 'root';
}

String? _featureOf(String path) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}
