// Tests for lib/api/ai_tool_executor.dart
// Exercises the tool-execution pipeline: confirmation, approval/rejection,
// unknown tools, exceptions, and the side-effects on ToolUseBlock state.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/ai_tools.dart';
import 'package:GitSync/api/ai_tool_executor.dart';
import 'package:GitSync/type/ai_chat.dart';

/// Configurable test double: lets each test choose what `execute` does.
class _FakeTool extends AiTool {
  _FakeTool(this._name, this._confirmation, this._handler);
  final String _name;
  final ToolConfirmation _confirmation;
  final Future<String> Function(Map<String, dynamic> input) _handler;

  @override
  String get name => _name;
  @override
  String get description => 'fake $_name';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};
  @override
  ToolConfirmation get confirmation => _confirmation;

  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) => _handler(input);
}

ToolUseBlock _makeBlock(String name, [Map<String, dynamic>? input]) =>
    ToolUseBlock(toolCallId: 'call-$name', toolName: name, input: input ?? <String, dynamic>{});

void main() {
  // ---------------------------------------------------------------------------
  // Unknown tool
  // ---------------------------------------------------------------------------
  group('unknown tool', () {
    test('returns an error JSON and marks block failed', () async {
      final exec = ToolExecutor(
        registry: ToolRegistry(),
        onConfirmationRequired: (_, __) async => true,
      );
      final block = _makeBlock('does_not_exist');

      final result = await exec.execute(block, null);
      final json = jsonDecode(result);

      expect(json['error'], contains('Unknown tool'));
      expect(block.status, ToolCallStatus.failed);
      expect(block.error, contains('Unknown tool'));
    });

    test('does not invoke the confirmation callback', () async {
      var calls = 0;
      final exec = ToolExecutor(
        registry: ToolRegistry(),
        onConfirmationRequired: (_, __) async {
          calls++;
          return true;
        },
      );
      await exec.execute(_makeBlock('missing'), null);
      expect(calls, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // No-confirmation tool: success path
  // ---------------------------------------------------------------------------
  group('confirmation=none', () {
    test('runs straight through to completed', () async {
      final reg = ToolRegistry();
      reg.register(_FakeTool('safe', ToolConfirmation.none, (_) async => '{"result":"ok"}'));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async => fail('Should not be called for confirmation=none'),
      );

      final block = _makeBlock('safe');
      final result = await exec.execute(block, null);

      expect(result, '{"result":"ok"}');
      expect(block.status, ToolCallStatus.completed);
      expect(block.output, '{"result":"ok"}');
      expect(block.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Confirmation required: approval
  // ---------------------------------------------------------------------------
  group('confirmation=confirm – approved', () {
    test('invokes callback with the tool and input', () async {
      AiTool? receivedTool;
      Map<String, dynamic>? receivedInput;
      final reg = ToolRegistry();
      reg.register(_FakeTool('write', ToolConfirmation.confirm, (_) async => 'done'));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (tool, input) async {
          receivedTool = tool;
          receivedInput = input;
          return true;
        },
      );

      final block = _makeBlock('write', {'path': 'README.md'});
      await exec.execute(block, null);

      expect(receivedTool!.name, 'write');
      expect(receivedInput, {'path': 'README.md'});
      expect(block.status, ToolCallStatus.completed);
      expect(block.output, 'done');
    });
  });

  // ---------------------------------------------------------------------------
  // Confirmation required: rejection
  // ---------------------------------------------------------------------------
  group('confirmation=confirm – rejected', () {
    test('returns error JSON, marks block rejected, never executes the tool', () async {
      var executed = false;
      final reg = ToolRegistry();
      reg.register(_FakeTool('write', ToolConfirmation.confirm, (_) async {
        executed = true;
        return 'should not run';
      }));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async => false,
      );

      final block = _makeBlock('write');
      final result = await exec.execute(block, null);

      expect(executed, isFalse);
      expect(jsonDecode(result)['error'], contains('rejected'));
      expect(block.status, ToolCallStatus.rejected);
      expect(block.error, contains('rejected'));
      expect(block.output, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Other confirmation tiers also trigger the prompt
  // ---------------------------------------------------------------------------
  group('confirmation tiers', () {
    Future<bool> runTier(ToolConfirmation tier) async {
      var prompted = false;
      final reg = ToolRegistry();
      reg.register(_FakeTool('t', tier, (_) async => 'ok'));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async {
          prompted = true;
          return true;
        },
      );
      await exec.execute(_makeBlock('t'), null);
      return prompted;
    }

    test('warn tier triggers confirmation', () async {
      expect(await runTier(ToolConfirmation.warn), isTrue);
    });

    test('confirm tier triggers confirmation', () async {
      expect(await runTier(ToolConfirmation.confirm), isTrue);
    });

    test('danger tier triggers confirmation', () async {
      expect(await runTier(ToolConfirmation.danger), isTrue);
    });

    test('none tier does not trigger confirmation', () async {
      expect(await runTier(ToolConfirmation.none), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Tool throws an exception
  // ---------------------------------------------------------------------------
  group('tool execution throws', () {
    test('failure is captured into block.error and returned as JSON error', () async {
      final reg = ToolRegistry();
      // Use Future.error to deliver a rejected Future without triggering
      // the test framework's zone-level "unhandled async error" detector
      // (which fires for `throw` inside an async body even when the caller
      // catches the error downstream).
      reg.register(_FakeTool('bad', ToolConfirmation.none, (_) => Future<String>.error(StateError('kaboom'))));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async => true,
      );

      final block = _makeBlock('bad');
      final result = await exec.execute(block, null);

      expect(jsonDecode(result)['error'], contains('kaboom'));
      expect(block.status, ToolCallStatus.failed);
      expect(block.error, contains('kaboom'));
    });
  });

  // ---------------------------------------------------------------------------
  // Block.status transitions through running before completed
  // ---------------------------------------------------------------------------
  group('status transitions', () {
    test('starts pending → ends completed on success (no confirmation)', () async {
      final reg = ToolRegistry();
      reg.register(_FakeTool('t', ToolConfirmation.none, (_) async => 'ok'));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async => true,
      );

      final block = _makeBlock('t');
      expect(block.status, ToolCallStatus.pending);
      await exec.execute(block, null);
      expect(block.status, ToolCallStatus.completed);
    });

    test('marks block.status as approved before running when confirmed', () async {
      final statesSeen = <ToolCallStatus>[];
      final reg = ToolRegistry();
      // The handler runs after the executor sets status=running. Capture it.
      late ToolUseBlock blockRef;
      reg.register(_FakeTool('t', ToolConfirmation.confirm, (_) async {
        statesSeen.add(blockRef.status);
        return 'ok';
      }));
      final exec = ToolExecutor(
        registry: reg,
        onConfirmationRequired: (_, __) async => true,
      );
      blockRef = _makeBlock('t');
      await exec.execute(blockRef, null);
      // While the handler ran, the executor had progressed status to "running".
      expect(statesSeen, [ToolCallStatus.running]);
      expect(blockRef.status, ToolCallStatus.completed);
    });
  });
}
