// Tests for lib/api/ai_system_prompt.dart
// Sanity checks that the prompt builders return non-empty content with the
// guidance keywords callers rely on. Both builders ignore repoIndex and
// return a constant string (by design for prompt-cache hits), so the tests
// check that contract too.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/ai_system_prompt.dart';

void main() {
  // ---------------------------------------------------------------------------
  // buildToolModelSystemPrompt
  // ---------------------------------------------------------------------------
  group('buildToolModelSystemPrompt', () {
    test('returns a non-empty string', () async {
      final p = await buildToolModelSystemPrompt();
      expect(p, isNotEmpty);
    });

    test('mentions GitSync persona', () async {
      final p = await buildToolModelSystemPrompt();
      expect(p, contains('GitSync'));
    });

    test('contains tool-selection guidance', () async {
      final p = await buildToolModelSystemPrompt();
      expect(p, contains('git_status'));
      expect(p, contains('git_sync'));
    });

    test('returns the same content regardless of repoIndex (cacheable)', () async {
      final a = await buildToolModelSystemPrompt(repoIndex: 0);
      final b = await buildToolModelSystemPrompt(repoIndex: 99);
      final c = await buildToolModelSystemPrompt();
      expect(a, b);
      expect(a, c);
    });
  });

  // ---------------------------------------------------------------------------
  // buildChatModelSystemPrompt
  // ---------------------------------------------------------------------------
  group('buildChatModelSystemPrompt', () {
    test('returns a non-empty string', () async {
      final p = await buildChatModelSystemPrompt();
      expect(p, isNotEmpty);
    });

    test('mentions GitSync persona', () async {
      final p = await buildChatModelSystemPrompt();
      expect(p, contains('GitSync'));
    });

    test('returns the same content regardless of repoIndex (cacheable)', () async {
      final a = await buildChatModelSystemPrompt(repoIndex: 1);
      final b = await buildChatModelSystemPrompt(repoIndex: 2);
      expect(a, b);
    });

    test('is shorter than the tool-model prompt', () async {
      final chat = await buildChatModelSystemPrompt();
      final tool = await buildToolModelSystemPrompt();
      expect(chat.length, lessThan(tool.length));
    });
  });

  // ---------------------------------------------------------------------------
  // Deprecated wrapper
  // ---------------------------------------------------------------------------
  group('buildSystemPrompt (deprecated wrapper)', () {
    // ignore: deprecated_member_use_from_same_package
    test('returns the tool-model prompt for backwards compatibility', () async {
// ignore: deprecated_member_use_from_same_package
      final wrapped = await buildSystemPrompt();
      final toolPrompt = await buildToolModelSystemPrompt();
      expect(wrapped, toolPrompt);
    });
  });
}
