// Tests for lib/type/agent_session.dart
// Pure-Dart unit tests for the AgentSession value object.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/type/agent_session.dart';

void main() {
  group('AgentSession', () {
    test('stores all required fields', () {
      final s = AgentSession(
        issueNumber: 7,
        title: 'My session',
        isOpen: true,
        createdAt: DateTime.utc(2024, 1, 2),
      );
      expect(s.issueNumber, 7);
      expect(s.title, 'My session');
      expect(s.isOpen, isTrue);
      expect(s.createdAt, DateTime.utc(2024, 1, 2));
    });

    test('numeric counters default to 0', () {
      final s = AgentSession(
        issueNumber: 1,
        title: 't',
        isOpen: false,
        createdAt: DateTime(2024),
      );
      expect(s.actionCount, 0);
      expect(s.durationSeconds, 0);
      expect(s.sessionCount, 0);
      expect(s.premiumRequests, 0);
    });

    test('optional updatedAt and linkedPrNumber default to null', () {
      final s = AgentSession(
        issueNumber: 1,
        title: 't',
        isOpen: true,
        createdAt: DateTime(2024),
      );
      expect(s.updatedAt, isNull);
      expect(s.linkedPrNumber, isNull);
    });

    test('optional fields are stored when provided', () {
      final updated = DateTime.utc(2024, 6, 1);
      final s = AgentSession(
        issueNumber: 42,
        title: 'Closed session',
        isOpen: false,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: updated,
        actionCount: 3,
        durationSeconds: 120,
        linkedPrNumber: 99,
        sessionCount: 2,
        premiumRequests: 5,
      );
      expect(s.updatedAt, updated);
      expect(s.actionCount, 3);
      expect(s.durationSeconds, 120);
      expect(s.linkedPrNumber, 99);
      expect(s.sessionCount, 2);
      expect(s.premiumRequests, 5);
    });
  });
}
