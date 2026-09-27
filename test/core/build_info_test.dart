import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/config/build_info.dart';

void main() {
  test('local runs are labelled dev', () {
    expect(BuildInfo.label(version: 'dev', build: '', commit: ''), 'vdev');
  });

  test('CI builds show version, build and commit', () {
    expect(
      BuildInfo.label(version: '0.1.0', build: '42', commit: 'abc1234'),
      'v0.1.0 (42) · abc1234',
    );
  });
}
