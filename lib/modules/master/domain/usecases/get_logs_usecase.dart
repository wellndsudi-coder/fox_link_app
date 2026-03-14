import '../entities/platform_log_entity.dart';
import '../repositories/master_repository.dart';

class GetLogsUseCase {
  final MasterRepository repository;

  GetLogsUseCase(this.repository);

  Future<List<PlatformLogEntity>> call({int limit = 100}) =>
      repository.getLogs(limit: limit);
}
