import 'dart:async';

import 'package:GitSync/api/remote_event_channel.dart';
import 'package:GitSync/type/agent_session.dart';

/// A [RemoteEventChannel] that monitors GitHub Copilot agent sessions (issues
/// assigned to `app/github-copilot`) for a given repository using ETag-based
/// conditional polling.
///
/// The channel polls
/// `GET /repos/{owner}/{repo}/issues?assignee=app/github-copilot&state=all&per_page=30`
/// and **only emits** [AgentSession] objects whose [AgentSession.isOpen] or
/// [AgentSession.updatedAt] has changed since the previous poll.
///
/// Usage:
/// ```dart
/// final channel = GithubAgentChannel(
///   accessToken: token,
///   owner: 'my-org',
///   repo: 'my-repo',
/// );
/// channel.events.listen((session) { /* handle changed session */ });
/// await channel.connect();
/// // …later…
/// channel.disconnect();
/// ```
class GithubAgentChannel implements RemoteEventChannel<AgentSession> {
  final String accessToken;
  final String owner;
  final String repo;

  late final HttpLongPollChannel<AgentSession> _inner;
  final StreamController<AgentSession> _changed = StreamController<AgentSession>.broadcast();
  // Maps issueNumber → (isOpen, updatedAt)
  final Map<int, ({bool isOpen, DateTime? updatedAt})> _lastState = {};
  StreamSubscription<AgentSession>? _innerSub;

  GithubAgentChannel({
    required this.accessToken,
    required this.owner,
    required this.repo,
  }) {
    _inner = HttpLongPollChannel<AgentSession>(
      uri: Uri.parse(
          'https://api.github.com/repos/$owner/$repo/issues?assignee=app%2Fgithub-copilot&state=all&per_page=30'),
      baseHeaders: {
        'Authorization': 'token $accessToken',
        'Accept': 'application/vnd.github+json',
      },
      parseItems: _parseItems,
    );
  }

  @override
  Stream<AgentSession> get events => _changed.stream;

  @override
  Future<void> connect() async {
    _innerSub = _inner.events.listen((session) {
      final prev = _lastState[session.issueNumber];
      final changed = prev == null ||
          prev.isOpen != session.isOpen ||
          prev.updatedAt != session.updatedAt;
      if (changed) {
        _lastState[session.issueNumber] = (isOpen: session.isOpen, updatedAt: session.updatedAt);
        if (!_changed.isClosed) _changed.add(session);
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

  static List<AgentSession> _parseItems(dynamic json) {
    if (json is! List) return [];
    return json.whereType<Map<String, dynamic>>().map(_parseSession).toList();
  }

  static AgentSession _parseSession(Map<String, dynamic> item) {
    final prLinks = item['pull_request'] as Map<String, dynamic>?;
    return AgentSession(
      issueNumber: item['number'] as int? ?? 0,
      title: item['title'] as String? ?? '',
      isOpen: item['state'] == 'open',
      createdAt: DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(item['updated_at'] as String? ?? ''),
      linkedPrNumber: prLinks != null ? (item['number'] as int?) : null,
    );
  }
}
