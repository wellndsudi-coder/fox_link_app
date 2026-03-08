import '../entities/queue_entry.dart';

abstract class QueueRepository {
  Future<QueueEntry> add(String clientId);

  Future<QueueEntry?> getByClient(String clientId);

  Future<void> remove(String clientId);

  Future<List<QueueEntry>> getAll();
}
