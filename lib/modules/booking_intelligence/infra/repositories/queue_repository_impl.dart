import '../../domain/entities/queue_entry.dart';
import '../../domain/repositories/queue_repository.dart';
import '../datasources/queue_remote_datasource.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDataSource dataSource;

  QueueRepositoryImpl(this.dataSource);

  @override
  Future<QueueEntry> add(String clientId) => dataSource.add(clientId);

  @override
  Future<QueueEntry?> getByClient(String clientId) =>
      dataSource.getByClient(clientId);

  @override
  Future<void> remove(String clientId) => dataSource.remove(clientId);

  @override
  Future<List<QueueEntry>> getAll() => dataSource.getAll();
}
