import 'dart:async';

import 'package:GitSync/api/remote_event_channel.dart';
import 'package:GitSync/type/action_run.dart';
import 'package:http/http.dart' as http;

/// A [RemoteEventChannel] that monitors GitHub Actions workflow runs for a
/// given repository using ETag-based conditional polling.
///
/// The channel polls `GET /repos/{owner}/{repo}/actions/runs?per_page=30` and
/// **only emits** [ActionRun] objects whose [ActionRun.status] has changed
/// since the previous poll.  Callers therefore see a stream of change events
/// rather than the full list on every tick.
///
/// Usage:
/// ```dart
/// final channel = GithubActionsChannel(
///   accessToken: token,
///   owner: 'my-org',
///   repo: 'my-repo',
/// );
/// channel.events.listen((run) { /* handle changed run */ });
/// await channel.connect();
/// // …later…
/// channel.disconnect();
/// ```
class GithubActionsChannel implements RemoteEventChannel<ActionRun> {
  final String accessToken;
  final String owner;
  final String repo;

  late final HttpLongPollChannel<ActionRun> _inner;
  final StreamController<ActionRun> _changed = StreamController<ActionRun>.broadcast();
  final Map<int, ActionRunStatus> _lastStatus = {};
  StreamSubscription<ActionRun>? _innerSub;

  GithubActionsChannel({
    required this.accessToken,
    required this.owner,
    required this.repo,
  }) {
    _inner = HttpLongPollChannel<ActionRun>(
      uri: Uri.parse('https://api.github.com/repos/$owner/$repo/actions/runs?per_page=30'),
      baseHeaders: {
        'Authorization': 'token $accessToken',
        'Accept': 'application/vnd.github+json',
      },
      parseItems: _parseItems,
    );
  }

  @override
  Stream<ActionRun> get events => _changed.stream;

  @override
  Future<void> connect() async {
    _innerSub = _inner.events.listen((run) {
      final prev = _lastStatus[run.number];
      if (prev != run.status) {
        _lastStatus[run.number] = run.status;
        if (!_changed.isClosed) _changed.add(run);
      }
    });
    await _inner.connect();
  }

  @override
  void disconnect() {
    _innerSub?.cancel();
    _innerSub = null;
    _inner.disconnect();
    if (!_changed.isClosed) _changed.close();
  }

  static List<ActionRun> _parseItems(dynamic json) {
    if (json is! Map<String, dynamic>) return [];
    final runs = json['workflow_runs'] as List<dynamic>? ?? [];
    return runs.whereType<Map<String, dynamic>>().map(_parseRun).toList();
  }

  static ActionRun _parseRun(Map<String, dynamic> item) {
    final conclusion = item['conclusion'] as String?;
    final statusStr = item['status'] as String? ?? '';
    final ActionRunStatus status = switch (conclusion) {
      'success' => ActionRunStatus.success,
      'failure' => ActionRunStatus.failure,
      'cancelled' => ActionRunStatus.cancelled,
      'skipped' => ActionRunStatus.skipped,
      _ => statusStr == 'in_progress' ? ActionRunStatus.inProgress : ActionRunStatus.pending,
    };

    final startedAt = DateTime.tryParse(item['run_started_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(item['updated_at'] as String? ?? '');
    final Duration? duration =
        (startedAt != null && updatedAt != null && conclusion != null) ? updatedAt.difference(startedAt) : null;

    final prs = item['pull_requests'] as List<dynamic>? ?? [];
    final int? prNumber = prs.isNotEmpty ? prs[0]['number'] as int? : null;

    return ActionRun(
      name: item['name'] as String? ?? '',
      number: item['run_number'] as int? ?? 0,
      status: status,
      event: item['event'] as String? ?? '',
      prNumber: prNumber,
      authorUsername: (item['actor'] as Map<String, dynamic>?)?['login'] as String? ?? '',
      createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
      duration: duration,
      branch: item['head_branch'] as String?,
    );
  }
}
