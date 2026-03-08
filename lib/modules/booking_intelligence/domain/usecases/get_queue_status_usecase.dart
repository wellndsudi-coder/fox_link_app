import '../entities/queue_entry.dart';
import '../repositories/queue_repository.dart';

class GetQueueStatusUseCase {
  final QueueRepository repository;

  GetQueueStatusUseCase(this.repository);

  Future<QueueEntry?> call(String clientId) {
    return repository.getByClient(clientId);
  }
}
