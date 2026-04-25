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

    test('GITEA is an OAuth provider', () {
      expect(GitProvider.GITEA.isOAuthProvider, isTrue);
    });

    test('CODEBERG is an OAuth provider', () {
      expect(GitProvider.CODEBERG.isOAuthProvider, isTrue);
    });

    test('GITLAB is an OAuth provider', () {
      expect(GitProvider.GITLAB.isOAuthProvider, isTrue);
    });

    test('HTTPS is not an OAuth provider', () {
      expect(GitProvider.HTTPS.isOAuthProvider, isFalse);
    });

    test('SSH is not an OAuth provider', () {
      expect(GitProvider.SSH.isOAuthProvider, isFalse);
    });

    test('exactly 4 providers are OAuth', () {
      final oauthProviders = GitProvider.values.where((p) => p.isOAuthProvider).toList();
      expect(oauthProviders.length, 4);
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

    test('GITEA produces /commit/ URL', () {
      expect(GitProvider.GITEA.commitUrl(base, sha), '$base/commit/$sha');
    });

    test('CODEBERG produces /commit/ URL', () {
      expect(GitProvider.CODEBERG.commitUrl(base, sha), '$base/commit/$sha');
    });

    test('GITLAB produces /-/commit/ URL', () {
      expect(GitProvider.GITLAB.commitUrl(base, sha), '$base/-/commit/$sha');
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

    test('GITLAB URL contains the SHA', () {
      final url = GitProvider.GITLAB.commitUrl(base, sha);
      expect(url, contains(sha));
    });

    test('GITLAB URL differs from GITHUB URL for same inputs', () {
      final github = GitProvider.GITHUB.commitUrl(base, sha);
      final gitlab = GitProvider.GITLAB.commitUrl(base, sha);
      expect(github, isNot(equals(gitlab)));
    });
  });
}
