// Tests for lib/api/ai_tools.dart
// Covers ToolRegistry filtering, AiTool's provider-format serialisation,
// the ok()/err() result helpers, and the built-in ListAvailableToolsTool.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/api/ai_tools.dart';

/// Minimal concrete AiTool used as a test double.
class _FakeTool extends AiTool {
  _FakeTool(this._name, {this.tier = ToolTier.core, String description = 'desc'}) : _description = description;
  final String _name;
  final String _description;
  @override
  final ToolTier tier;
  @override
  String get name => _name;
  @override
  String get description => _description;
  @override
  ToolConfirmation get confirmation => ToolConfirmation.none;
  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'foo': {'type': 'string'},
        },
      };
  @override
  Future<String> execute(Map<String, dynamic> input, ToolContext? context) async => ok({'echo': input});
}

void main() {
  // ---------------------------------------------------------------------------
  // AiTool.ok / err
  // ---------------------------------------------------------------------------
  group('AiTool result helpers', () {
    final tool = _FakeTool('t');

    test('ok() wraps data under "result"', () {
      final json = jsonDecode(tool.ok('hello'));
      expect(json, {'result': 'hello'});
    });

    test('ok() handles maps and lists', () {
      final json = jsonDecode(tool.ok({'a': 1, 'b': [2, 3]}));
      expect(json, {'result': {'a': 1, 'b': [2, 3]}});
    });

    test('err() wraps message under "error"', () {
      final json = jsonDecode(tool.err('boom'));
      expect(json, {'error': 'boom'});
    });
  });

  // ---------------------------------------------------------------------------
  // AiTool.toAnthropic / toOpenAI / toGoogle
  // ---------------------------------------------------------------------------
  group('AiTool provider serialisation', () {
    final tool = _FakeTool('git_status');

    test('toAnthropic uses input_schema key', () {
      final out = tool.toAnthropic();
      expect(out['name'], 'git_status');
      expect(out['description'], 'desc');
      expect(out['input_schema'], tool.inputSchema);
      expect(out.containsKey('parameters'), isFalse);
    });

    test('toOpenAI wraps in function block', () {
      final out = tool.toOpenAI();
      expect(out['type'], 'function');
      final fn = out['function'] as Map<String, dynamic>;
      expect(fn['name'], 'git_status');
      expect(fn['description'], 'desc');
      expect(fn['parameters'], tool.inputSchema);
    });

    test('toGoogle uses parameters key (no wrapper)', () {
      final out = tool.toGoogle();
      expect(out['name'], 'git_status');
      expect(out['description'], 'desc');
      expect(out['parameters'], tool.inputSchema);
      expect(out.containsKey('input_schema'), isFalse);
      expect(out.containsKey('function'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ToolRegistry – register / get / all
  // ---------------------------------------------------------------------------
  group('ToolRegistry', () {
    test('starts empty', () {
      expect(ToolRegistry().all, isEmpty);
    });

    test('register stores a tool retrievable by name', () {
      final reg = ToolRegistry();
      final tool = _FakeTool('t1');
      reg.register(tool);
      expect(reg.get('t1'), same(tool));
    });

    test('registering a tool with the same name overwrites the previous one', () {
      final reg = ToolRegistry();
      final a = _FakeTool('dupe');
      final b = _FakeTool('dupe');
      reg.register(a);
      reg.register(b);
      expect(reg.get('dupe'), same(b));
      expect(reg.all.length, 1);
    });

    test('get returns null for an unknown name', () {
      expect(ToolRegistry().get('missing'), isNull);
    });

    test('registerAll inserts every tool from a list', () {
      final reg = ToolRegistry();
      reg.registerAll([_FakeTool('a'), _FakeTool('b'), _FakeTool('c')]);
      expect(reg.all.map((t) => t.name).toSet(), {'a', 'b', 'c'});
    });
  });

  // ---------------------------------------------------------------------------
  // ToolRegistry.getFiltered – tier visibility
  // ---------------------------------------------------------------------------
  group('ToolRegistry.getFiltered', () {
    ToolRegistry buildRegistry() {
      final reg = ToolRegistry();
      reg.register(_FakeTool('core1', tier: ToolTier.core));
      reg.register(_FakeTool('core2', tier: ToolTier.core));
      reg.register(_FakeTool('ctx1', tier: ToolTier.contextual));
      reg.register(_FakeTool('adv1', tier: ToolTier.advanced));
      reg.register(_FakeTool('adv2', tier: ToolTier.advanced));
      return reg;
    }

    test('core tools are always included', () {
      final result = buildRegistry().getFiltered(hasOAuth: false);
      final names = result.map((t) => t.name).toSet();
      expect(names.contains('core1'), isTrue);
      expect(names.contains('core2'), isTrue);
    });

    test('contextual tools are included only when hasOAuth is true', () {
      final reg = buildRegistry();
      expect(reg.getFiltered(hasOAuth: false).any((t) => t.name == 'ctx1'), isFalse);
      expect(reg.getFiltered(hasOAuth: true).any((t) => t.name == 'ctx1'), isTrue);
    });

    test('advanced tools are excluded by default (no activated set)', () {
      final reg = buildRegistry();
      final result = reg.getFiltered(hasOAuth: true);
      expect(result.any((t) => t.name == 'adv1'), isFalse);
      expect(result.any((t) => t.name == 'adv2'), isFalse);
    });

    test('advanced tools appear only when listed in the activated set', () {
      final reg = buildRegistry();
      final result = reg.getFiltered(hasOAuth: true, activated: {'adv1'});
      expect(result.any((t) => t.name == 'adv1'), isTrue);
      expect(result.any((t) => t.name == 'adv2'), isFalse);
    });

    test('activated names that do not exist are silently ignored', () {
      final reg = buildRegistry();
      final result = reg.getFiltered(hasOAuth: true, activated: {'no_such_tool'});
      expect(result.any((t) => t.name == 'no_such_tool'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ToolRegistry.listAdvancedTools
  // ---------------------------------------------------------------------------
  group('ToolRegistry.listAdvancedTools', () {
    test('returns only advanced tools with name and description', () {
      final reg = ToolRegistry();
      reg.register(_FakeTool('c', tier: ToolTier.core));
      reg.register(_FakeTool('a1', tier: ToolTier.advanced));
      reg.register(_FakeTool('a2', tier: ToolTier.advanced));

      final list = reg.listAdvancedTools();
      expect(list.length, 2);
      expect(list.every((m) => m.containsKey('name') && m.containsKey('description')), isTrue);
      expect(list.map((m) => m['name']).toSet(), {'a1', 'a2'});
    });

    test('returns an empty list when no advanced tools are registered', () {
      final reg = ToolRegistry();
      reg.register(_FakeTool('c', tier: ToolTier.core));
      expect(reg.listAdvancedTools(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ListAvailableToolsTool
  // ---------------------------------------------------------------------------
  group('ListAvailableToolsTool', () {
    test('has expected name and confirmation level', () {
      final tool = ListAvailableToolsTool(ToolRegistry());
      expect(tool.name, 'list_available_tools');
      expect(tool.confirmation, ToolConfirmation.none);
      expect(tool.tier, ToolTier.core);
    });

    test('execute returns the registry\'s advanced tools wrapped under "result.available_tools"', () async {
      final reg = ToolRegistry();
      reg.register(_FakeTool('adv', tier: ToolTier.advanced));
      final out = await ListAvailableToolsTool(reg).execute({}, null);
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json.containsKey('result'), isTrue);
      final result = json['result'] as Map<String, dynamic>;
      final available = result['available_tools'] as List;
      expect(available.length, 1);
      expect(available.first['name'], 'adv');
    });

    test('execute returns an empty list when no advanced tools are registered', () async {
      final out = await ListAvailableToolsTool(ToolRegistry()).execute({}, null);
      final result = jsonDecode(out)['result'] as Map<String, dynamic>;
      expect(result['available_tools'], isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ToolContext – constructor stores all fields
  // ---------------------------------------------------------------------------
  group('ToolContext', () {
    test('exposes all constructor arguments', () {
      final ctx = ToolContext(
        repoIndex: 3,
        repoPath: '/repo',
        gitProvider: null,
        githubAppOauth: true,
        accessToken: 'tok',
        username: 'me',
        owner: 'me',
        repo: 'app',
        providerManager: null,
        authorName: 'Me',
        authorEmail: 'me@example.com',
      );
      expect(ctx.repoIndex, 3);
      expect(ctx.repoPath, '/repo');
      expect(ctx.githubAppOauth, isTrue);
      expect(ctx.accessToken, 'tok');
      expect(ctx.username, 'me');
      expect(ctx.owner, 'me');
      expect(ctx.repo, 'app');
      expect(ctx.authorName, 'Me');
      expect(ctx.authorEmail, 'me@example.com');
    });
  });
}
