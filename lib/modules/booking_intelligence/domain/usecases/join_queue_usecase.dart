import '../entities/queue_entry.dart';
import '../repositories/queue_repository.dart';

class JoinQueueUseCase {
  final QueueRepository repository;

  JoinQueueUseCase(this.repository);

  Future<QueueEntry> call(String clientId) {
    return repository.add(clientId);
  }
}
