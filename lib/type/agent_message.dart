class AgentAction {
  final String title;
  final int durationSeconds;
  final bool isCompleted;

  const AgentAction({required this.title, required this.durationSeconds, this.isCompleted = true});
}

class AgentMessage {
  final int id;
  final String body;
  final String authorLogin;
  final bool isAgent;
  final DateTime createdAt;
  final List<AgentAction> actions;

  const AgentMessage({
    required this.id,
    required this.body,
    required this.authorLogin,
    required this.isAgent,
    required this.createdAt,
    this.actions = const [],
  });
}
