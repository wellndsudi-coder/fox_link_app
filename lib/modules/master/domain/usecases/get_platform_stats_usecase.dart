import '../entities/platform_stats_entity.dart';
import '../repositories/master_repository.dart';

class GetPlatformStatsUseCase {
  final MasterRepository repository;

  GetPlatformStatsUseCase(this.repository);

  Future<PlatformStatsEntity> call() => repository.getPlatformStats();
}
