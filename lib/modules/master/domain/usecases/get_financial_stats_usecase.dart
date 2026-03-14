import '../entities/financial_stats_entity.dart';
import '../repositories/master_repository.dart';

class GetFinancialStatsUseCase {
  final MasterRepository repository;

  GetFinancialStatsUseCase(this.repository);

  Future<FinancialStatsEntity> call() => repository.getFinancialStats();
}
