// Tests for lib/constant/reactions.dart
// Pure-Dart unit tests that run without a device or the Rust bridge.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/constant/reactions.dart';

void main() {
  // The canonical set of reaction keys used across providers.
  const canonicalKeys = {'+1', '-1', 'laugh', 'hooray', 'confused', 'heart', 'rocket', 'eyes'};

  // ---------------------------------------------------------------------------
  // standardReactions
  // ---------------------------------------------------------------------------
  group('standardReactions', () {
    test('has exactly 8 entries', () {
      expect(standardReactions.length, 8);
    });

    test('contains all canonical reaction keys', () {
      for (final key in canonicalKeys) {
        expect(standardReactions.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('all values are non-empty emoji strings', () {
      for (final entry in standardReactions.entries) {
        expect(entry.value.isNotEmpty, isTrue, reason: 'Empty emoji for ${entry.key}');
      }
    });

    test('+1 maps to thumbs-up emoji', () {
      expect(standardReactions['+1'], '\u{1F44D}');
    });

    test('-1 maps to thumbs-down emoji', () {
      expect(standardReactions['-1'], '\u{1F44E}');
    });
  });

  // ---------------------------------------------------------------------------
  // githubReactionNames  (standard key → GraphQL name)
  // ---------------------------------------------------------------------------
  group('githubReactionNames', () {
    test('has exactly 8 entries', () {
      expect(githubReactionNames.length, 8);
    });

    test('contains all canonical reaction keys', () {
      for (final key in canonicalKeys) {
        expect(githubReactionNames.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('+1 maps to THUMBS_UP', () {
      expect(githubReactionNames['+1'], 'THUMBS_UP');
    });

    test('-1 maps to THUMBS_DOWN', () {
      expect(githubReactionNames['-1'], 'THUMBS_DOWN');
    });

    test('all values are uppercase', () {
      for (final v in githubReactionNames.values) {
        expect(v, equals(v.toUpperCase()), reason: 'Not uppercase: $v');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // githubReactionNamesReverse  (GraphQL name → standard key)
  // ---------------------------------------------------------------------------
  group('githubReactionNamesReverse', () {
    test('has exactly 8 entries', () {
      expect(githubReactionNamesReverse.length, 8);
    });

    test('is the exact inverse of githubReactionNames', () {
      for (final entry in githubReactionNames.entries) {
        expect(
          githubReactionNamesReverse[entry.value],
          entry.key,
          reason: 'Reverse mapping failed for ${entry.key} → ${entry.value}',
        );
      }
    });

    test('THUMBS_UP maps back to +1', () {
      expect(githubReactionNamesReverse['THUMBS_UP'], '+1');
    });
  });

  // ---------------------------------------------------------------------------
  // gitlabReactionNames  (standard key → GitLab shortcode)
  // ---------------------------------------------------------------------------
  group('gitlabReactionNames', () {
    test('has exactly 8 entries', () {
      expect(gitlabReactionNames.length, 8);
    });

    test('contains all canonical reaction keys', () {
      for (final key in canonicalKeys) {
        expect(gitlabReactionNames.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('+1 maps to thumbsup', () {
      expect(gitlabReactionNames['+1'], 'thumbsup');
    });

    test('-1 maps to thumbsdown', () {
      expect(gitlabReactionNames['-1'], 'thumbsdown');
    });

    test('hooray maps to tada', () {
      expect(gitlabReactionNames['hooray'], 'tada');
    });

    test('laugh maps to laughing', () {
      expect(gitlabReactionNames['laugh'], 'laughing');
    });

    test('all values are lowercase', () {
      for (final v in gitlabReactionNames.values) {
        expect(v, equals(v.toLowerCase()), reason: 'Not lowercase: $v');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // gitlabReactionNamesReverse  (GitLab shortcode → standard key)
  // ---------------------------------------------------------------------------
  group('gitlabReactionNamesReverse', () {
    test('has exactly 8 entries', () {
      expect(gitlabReactionNamesReverse.length, 8);
    });

    test('is the exact inverse of gitlabReactionNames', () {
      for (final entry in gitlabReactionNames.entries) {
        expect(
          gitlabReactionNamesReverse[entry.value],
          entry.key,
          reason: 'Reverse mapping failed for ${entry.key} → ${entry.value}',
        );
      }
    });

    test('thumbsup maps back to +1', () {
      expect(gitlabReactionNamesReverse['thumbsup'], '+1');
    });

    test('tada maps back to hooray', () {
      expect(gitlabReactionNamesReverse['tada'], 'hooray');
    });
  });

  // ---------------------------------------------------------------------------
  // Cross-provider consistency
  // ---------------------------------------------------------------------------
  group('cross-provider consistency', () {
    test('same canonical keys in github and gitlab maps', () {
      final githubKeys = githubReactionNames.keys.toSet();
      final gitlabKeys = gitlabReactionNames.keys.toSet();
      expect(githubKeys, equals(gitlabKeys));
    });

    test('github and standard reactions have same canonical keys', () {
      expect(standardReactions.keys.toSet(), equals(githubReactionNames.keys.toSet()));
    });

    test('all reverse maps recover every canonical key', () {
      for (final key in canonicalKeys) {
        final githubName = githubReactionNames[key]!;
        final gitlabName = gitlabReactionNames[key]!;
        expect(githubReactionNamesReverse[githubName], key,
            reason: 'GitHub reverse failed for $key');
        expect(gitlabReactionNamesReverse[gitlabName], key,
            reason: 'GitLab reverse failed for $key');
      }
    });
  });
}
