// Pure-Dart unit tests that run without a device or the Rust bridge.
// These are suitable for headless CI environments (e.g. Copilot cloud agent).

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity: basic arithmetic', () {
    expect(1 + 1, 2);
  });

  test('sanity: string operations', () {
    const appName = 'GitSync';
    expect(appName.isNotEmpty, isTrue);
    expect(appName.toLowerCase(), 'gitsync');
  });
}
