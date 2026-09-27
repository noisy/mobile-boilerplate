import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every language must have every text, with the same placeholders, and
/// every English text says where it appears (@key.description), so
/// translators never guess.
void main() {
  final arbFiles = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();
  final templateJson = _json(File('lib/l10n/app_en.arb'));
  final template = _messages(templateJson);

  test('English and at least one more language are present', () {
    final names = arbFiles.map((f) => f.uri.pathSegments.last).toSet();
    expect(names, contains('app_en.arb'));
    expect(names.length, greaterThan(1));
  });

  test('every English text has a description', () {
    final missing = [
      for (final key in template.keys)
        if ((templateJson['@$key'] as Map<String, dynamic>?)?['description']
            case final String description when description.isNotEmpty)
          null
        else
          key,
    ].nonNulls;
    expect(missing, isEmpty);
  });

  for (final file in arbFiles) {
    test(
      '${file.uri.pathSegments.last} has every text with its placeholders',
      () {
        final messages = _messages(_json(file));
        expect(messages.keys.toSet(), template.keys.toSet());
        for (final MapEntry(:key, :value) in template.entries) {
          expect(
            _placeholders(messages[key]!),
            _placeholders(value),
            reason: key,
          );
          expect(messages[key], isNotEmpty, reason: key);
        }
      },
    );
  }
}

Map<String, dynamic> _json(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Map<String, String> _messages(Map<String, dynamic> json) => {
  for (final MapEntry(:key, :value) in json.entries)
    if (!key.startsWith('@')) key: value as String,
};

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!).toSet();
