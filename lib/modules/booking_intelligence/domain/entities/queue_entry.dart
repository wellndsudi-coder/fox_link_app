class QueueEntry {
  final String id;
  final String clientId;
  final int position;
  final DateTime? estimatedTime;
  final DateTime createdAt;

  const QueueEntry({
    required this.id,
    required this.clientId,
    required this.position,
    this.estimatedTime,
    required this.createdAt,
  });
}
