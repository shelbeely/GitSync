class AgentSession {
  final int issueNumber;
  final String title;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int actionCount;
  final int durationSeconds;
  final int? linkedPrNumber;
  final int sessionCount;
  final int premiumRequests;

  const AgentSession({
    required this.issueNumber,
    required this.title,
    required this.isOpen,
    required this.createdAt,
    this.updatedAt,
    this.actionCount = 0,
    this.durationSeconds = 0,
    this.linkedPrNumber,
    this.sessionCount = 0,
    this.premiumRequests = 0,
  });
}
