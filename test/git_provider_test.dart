// Tests for lib/type/git_provider.dart
// Pure-Dart unit tests that run without a device or the Rust bridge.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/type/git_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // isOAuthProvider
  // ---------------------------------------------------------------------------
  group('GitProvider.isOAuthProvider', () {
    test('GITHUB is an OAuth provider', () {
      expect(GitProvider.GITHUB.isOAuthProvider, isTrue);
    });

    test('HTTPS is not an OAuth provider', () {
      expect(GitProvider.HTTPS.isOAuthProvider, isFalse);
    });

    test('SSH is not an OAuth provider', () {
      expect(GitProvider.SSH.isOAuthProvider, isFalse);
    });

    test('exactly 1 provider is OAuth', () {
      final oauthProviders = GitProvider.values.where((p) => p.isOAuthProvider).toList();
      expect(oauthProviders.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // commitUrl
  // ---------------------------------------------------------------------------
  group('GitProvider.commitUrl', () {
    const base = 'https://github.com/user/repo';
    const sha = 'abc1234';

    test('GITHUB produces /commit/ URL', () {
      expect(GitProvider.GITHUB.commitUrl(base, sha), '$base/commit/$sha');
    });

    test('HTTPS returns null', () {
      expect(GitProvider.HTTPS.commitUrl(base, sha), isNull);
    });

    test('SSH returns null', () {
      expect(GitProvider.SSH.commitUrl(base, sha), isNull);
    });

    test('GITHUB URL contains the SHA', () {
      final url = GitProvider.GITHUB.commitUrl(base, sha);
      expect(url, contains(sha));
    });
  });
}
