// Tests for lib/type/ai_chat.dart
// Pure-Dart unit tests for the chat message data model: content blocks,
// computed getters, JSON serialisation/deserialisation, and TokenUsage.

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/type/ai_chat.dart';

void main() {
  // ---------------------------------------------------------------------------
  // TokenUsage
  // ---------------------------------------------------------------------------
  group('TokenUsage', () {
    test('stores input and output token counts', () {
      const u = TokenUsage(10, 20);
      expect(u.inputTokens, 10);
      expect(u.outputTokens, 20);
    });

    test('operator + sums both fields independently', () {
      const a = TokenUsage(10, 20);
      const b = TokenUsage(5, 7);
      final sum = a + b;
      expect(sum.inputTokens, 15);
      expect(sum.outputTokens, 27);
    });

    test('operator + with zero is identity', () {
      const a = TokenUsage(42, 99);
      const zero = TokenUsage(0, 0);
      final r = a + zero;
      expect(r.inputTokens, a.inputTokens);
      expect(r.outputTokens, a.outputTokens);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatMessage – construction & defaults
  // ---------------------------------------------------------------------------
  group('ChatMessage construction', () {
    test('timestamp defaults to roughly now when omitted', () {
      final before = DateTime.now();
      final msg = ChatMessage(id: '1', role: ChatRole.user, content: [TextBlock('hi')]);
      final after = DateTime.now();
      expect(
        msg.timestamp.isAfter(before.subtract(const Duration(seconds: 1))) &&
            msg.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('uses provided timestamp when supplied', () {
      final ts = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final msg = ChatMessage(id: '1', role: ChatRole.assistant, content: [], timestamp: ts);
      expect(msg.timestamp, ts);
    });

    test('usage defaults to null', () {
      final msg = ChatMessage(id: '1', role: ChatRole.user, content: []);
      expect(msg.usage, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatMessage – computed getters
  // ---------------------------------------------------------------------------
  group('ChatMessage getters', () {
    test('hasToolCalls is false when content is text-only', () {
      final msg = ChatMessage(id: '1', role: ChatRole.assistant, content: [TextBlock('hello')]);
      expect(msg.hasToolCalls, isFalse);
      expect(msg.toolCalls, isEmpty);
    });

    test('hasToolCalls is true when any ToolUseBlock is present', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [
          TextBlock('thinking…'),
          ToolUseBlock(toolCallId: 't1', toolName: 'git_status', input: {}),
        ],
      );
      expect(msg.hasToolCalls, isTrue);
      expect(msg.toolCalls.length, 1);
      expect(msg.toolCalls.first.toolName, 'git_status');
    });

    test('toolCalls returns every ToolUseBlock in order', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [
          ToolUseBlock(toolCallId: 'a', toolName: 'git_status', input: {}),
          TextBlock('between'),
          ToolUseBlock(toolCallId: 'b', toolName: 'file_read', input: {'path': 'README.md'}),
        ],
      );
      expect(msg.toolCalls.map((t) => t.toolCallId).toList(), ['a', 'b']);
    });

    test('textContent concatenates all TextBlock text in order', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [TextBlock('Hello, '), TextBlock('world')],
      );
      expect(msg.textContent, 'Hello, world');
    });

    test('textContent ignores ToolUseBlock content', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [
          TextBlock('Result: '),
          ToolUseBlock(toolCallId: 't', toolName: 'x', input: {}),
          TextBlock('done'),
        ],
      );
      expect(msg.textContent, 'Result: done');
    });

    test('textContent is empty when no TextBlocks present', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [ToolUseBlock(toolCallId: 't', toolName: 'x', input: {})],
      );
      expect(msg.textContent, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatMessage.toJson / fromJson
  // ---------------------------------------------------------------------------
  group('ChatMessage JSON serialisation', () {
    test('toJson includes id, role, timestamp', () {
      final msg = ChatMessage(
        id: 'abc',
        role: ChatRole.user,
        content: [TextBlock('hi')],
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final json = msg.toJson();
      expect(json['id'], 'abc');
      expect(json['role'], 'user');
      expect(json['timestamp'], 1700000000000);
    });

    test('toJson serialises TextBlock with type=text', () {
      final msg = ChatMessage(id: '1', role: ChatRole.assistant, content: [TextBlock('hello')]);
      final json = msg.toJson();
      final blocks = json['content'] as List;
      expect(blocks.first['type'], 'text');
      expect(blocks.first['text'], 'hello');
    });

    test('toJson serialises ToolUseBlock with all fields', () {
      final msg = ChatMessage(
        id: '1',
        role: ChatRole.assistant,
        content: [
          ToolUseBlock(
            toolCallId: 'tc1',
            toolName: 'git_status',
            input: {'path': '.'},
            status: ToolCallStatus.completed,
            output: 'clean',
            error: null,
          ),
        ],
      );
      final blocks = msg.toJson()['content'] as List;
      expect(blocks.first['type'], 'tool_use');
      expect(blocks.first['toolCallId'], 'tc1');
      expect(blocks.first['toolName'], 'git_status');
      expect(blocks.first['input'], {'path': '.'});
      expect(blocks.first['status'], 'completed');
      expect(blocks.first['output'], 'clean');
      expect(blocks.first['error'], isNull);
    });

    test('toJson omits usage key when usage is null', () {
      final msg = ChatMessage(id: '1', role: ChatRole.user, content: []);
      expect(msg.toJson().containsKey('usage'), isFalse);
    });

    test('toJson includes usage when set', () {
      final msg = ChatMessage(id: '1', role: ChatRole.user, content: [], usage: const TokenUsage(7, 13));
      final json = msg.toJson();
      expect(json['usage'], {'input': 7, 'output': 13});
    });

    test('fromJson reconstructs id, role, timestamp', () {
      final msg = ChatMessage.fromJson({
        'id': 'x',
        'role': 'assistant',
        'timestamp': 1700000000000,
        'content': <Map<String, dynamic>>[],
      });
      expect(msg.id, 'x');
      expect(msg.role, ChatRole.assistant);
      expect(msg.timestamp.millisecondsSinceEpoch, 1700000000000);
    });

    test('fromJson reconstructs TextBlock content', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'user',
        'timestamp': 0,
        'content': [
          {'type': 'text', 'text': 'hello'},
        ],
      });
      expect(msg.content.length, 1);
      expect(msg.content.first, isA<TextBlock>());
      expect((msg.content.first as TextBlock).text, 'hello');
    });

    test('fromJson reconstructs ToolUseBlock with status', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'assistant',
        'timestamp': 0,
        'content': [
          {
            'type': 'tool_use',
            'toolCallId': 'tc',
            'toolName': 'git_status',
            'input': <String, dynamic>{'verbose': true},
            'status': 'running',
            'output': null,
            'error': null,
          },
        ],
      });
      final block = msg.content.first as ToolUseBlock;
      expect(block.toolCallId, 'tc');
      expect(block.toolName, 'git_status');
      expect(block.input['verbose'], true);
      expect(block.status, ToolCallStatus.running);
    });

    test('fromJson treats unknown block type as empty TextBlock', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'user',
        'timestamp': 0,
        'content': [
          {'type': 'mystery'},
        ],
      });
      expect(msg.content.first, isA<TextBlock>());
      expect((msg.content.first as TextBlock).text, '');
    });

    test('fromJson defaults missing text to empty string', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'user',
        'timestamp': 0,
        'content': [
          {'type': 'text'},
        ],
      });
      expect((msg.content.first as TextBlock).text, '');
    });

    test('fromJson handles unknown status string by defaulting to completed', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'assistant',
        'timestamp': 0,
        'content': [
          {
            'type': 'tool_use',
            'toolCallId': 'tc',
            'toolName': 'x',
            'input': <String, dynamic>{},
            'status': 'totally_not_a_status',
          },
        ],
      });
      expect((msg.content.first as ToolUseBlock).status, ToolCallStatus.completed);
    });

    test('fromJson rebuilds TokenUsage when present', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'assistant',
        'timestamp': 0,
        'content': <Map<String, dynamic>>[],
        'usage': {'input': 100, 'output': 200},
      });
      expect(msg.usage, isNotNull);
      expect(msg.usage!.inputTokens, 100);
      expect(msg.usage!.outputTokens, 200);
    });

    test('fromJson leaves usage null when absent', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'role': 'user',
        'timestamp': 0,
        'content': <Map<String, dynamic>>[],
      });
      expect(msg.usage, isNull);
    });

    test('round-trip preserves text + tool_use messages', () {
      final original = ChatMessage(
        id: 'r1',
        role: ChatRole.assistant,
        content: [
          TextBlock('analysing…'),
          ToolUseBlock(
            toolCallId: 'tc1',
            toolName: 'file_read',
            input: {'path': 'README.md', 'offset': 0, 'limit': 100},
            status: ToolCallStatus.completed,
            output: 'content',
          ),
        ],
        usage: const TokenUsage(50, 75),
        timestamp: DateTime.fromMillisecondsSinceEpoch(1234567890000),
      );
      final restored = ChatMessage.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.timestamp, original.timestamp);
      expect(restored.content.length, 2);
      expect((restored.content[0] as TextBlock).text, 'analysing…');
      final tool = restored.content[1] as ToolUseBlock;
      expect(tool.toolCallId, 'tc1');
      expect(tool.toolName, 'file_read');
      expect(tool.input['path'], 'README.md');
      expect(tool.status, ToolCallStatus.completed);
      expect(tool.output, 'content');
      expect(restored.usage!.inputTokens, 50);
      expect(restored.usage!.outputTokens, 75);
    });
  });

  // ---------------------------------------------------------------------------
  // ToolUseBlock – defaults
  // ---------------------------------------------------------------------------
  group('ToolUseBlock', () {
    test('status defaults to pending', () {
      final block = ToolUseBlock(toolCallId: 'x', toolName: 'y', input: {});
      expect(block.status, ToolCallStatus.pending);
    });

    test('output and error default to null', () {
      final block = ToolUseBlock(toolCallId: 'x', toolName: 'y', input: {});
      expect(block.output, isNull);
      expect(block.error, isNull);
    });
  });
}
