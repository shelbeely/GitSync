// Tests for lib/type/showcase_feature.dart
// Pure-Dart unit tests for the ShowcaseFeature enum: storage-key conversions
// and the default-pinned set.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/type/showcase_feature.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Enum identity
  // ---------------------------------------------------------------------------
  group('ShowcaseFeature enum', () {
    test('every value has a non-empty storage key and label', () {
      for (final f in ShowcaseFeature.values) {
        expect(f.storageKey, isNotEmpty);
        expect(f.label, isNotEmpty);
      }
    });

    test('storage keys are unique', () {
      final keys = ShowcaseFeature.values.map((f) => f.storageKey).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('exposes the expected feature set', () {
      expect(
        ShowcaseFeature.values.map((f) => f.storageKey).toSet(),
        {'issues', 'pull_requests', 'tags', 'releases', 'actions'},
      );
    });
  });

  // ---------------------------------------------------------------------------
  // fromStorageKey
  // ---------------------------------------------------------------------------
  group('fromStorageKey', () {
    test('returns the matching feature for a known key', () {
      expect(ShowcaseFeature.fromStorageKey('issues'), ShowcaseFeature.issues);
      expect(ShowcaseFeature.fromStorageKey('pull_requests'), ShowcaseFeature.pullRequests);
      expect(ShowcaseFeature.fromStorageKey('actions'), ShowcaseFeature.actions);
      expect(ShowcaseFeature.fromStorageKey('releases'), ShowcaseFeature.releases);
      expect(ShowcaseFeature.fromStorageKey('tags'), ShowcaseFeature.tags);
    });

    test('returns null for an unknown key', () {
      expect(ShowcaseFeature.fromStorageKey('mystery'), isNull);
    });

    test('match is case-sensitive', () {
      expect(ShowcaseFeature.fromStorageKey('Issues'), isNull);
    });

    test('returns null for an empty key', () {
      expect(ShowcaseFeature.fromStorageKey(''), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fromStorageKeys / toStorageKeys – round-trip
  // ---------------------------------------------------------------------------
  group('storage-key list conversions', () {
    test('fromStorageKeys preserves order and skips unknowns', () {
      final result = ShowcaseFeature.fromStorageKeys(['actions', 'mystery', 'issues']);
      expect(result, [ShowcaseFeature.actions, ShowcaseFeature.issues]);
    });

    test('fromStorageKeys returns an empty list for an empty input', () {
      expect(ShowcaseFeature.fromStorageKeys([]), isEmpty);
    });

    test('fromStorageKeys returns an empty list when every key is unknown', () {
      expect(ShowcaseFeature.fromStorageKeys(['x', 'y']), isEmpty);
    });

    test('toStorageKeys maps features to their keys, preserving order', () {
      final keys = ShowcaseFeature.toStorageKeys([ShowcaseFeature.tags, ShowcaseFeature.issues]);
      expect(keys, ['tags', 'issues']);
    });

    test('round-trip toStorageKeys → fromStorageKeys is identity for valid features', () {
      const features = [
        ShowcaseFeature.issues,
        ShowcaseFeature.pullRequests,
        ShowcaseFeature.actions,
        ShowcaseFeature.releases,
        ShowcaseFeature.tags,
      ];
      final restored = ShowcaseFeature.fromStorageKeys(ShowcaseFeature.toStorageKeys(features));
      expect(restored, features);
    });
  });

  // ---------------------------------------------------------------------------
  // defaultPinned
  // ---------------------------------------------------------------------------
  group('defaultPinned', () {
    test('contains every available feature', () {
      expect(ShowcaseFeature.defaultPinned.toSet(), ShowcaseFeature.values.toSet());
    });

    test('first entry is issues (the most-used surface)', () {
      expect(ShowcaseFeature.defaultPinned.first, ShowcaseFeature.issues);
    });
  });

  // ---------------------------------------------------------------------------
  // labelForProvider / availableFor
  // ---------------------------------------------------------------------------
  group('provider-aware helpers', () {
    test('labelForProvider returns the underlying label regardless of provider', () {
      // Currently provider-agnostic; verify the documented behaviour holds.
      expect(ShowcaseFeature.issues.labelForProvider(null), ShowcaseFeature.issues.label);
    });

    test('availableFor returns every feature when provider is null', () {
      expect(ShowcaseFeature.availableFor(null), ShowcaseFeature.values);
    });
  });
}
