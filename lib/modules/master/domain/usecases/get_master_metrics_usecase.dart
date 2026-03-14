import '../repositories/master_repository.dart';

class GetMasterMetricsUseCase {
  final MasterRepository repository;

  GetMasterMetricsUseCase(this.repository);

  Future<MasterMetrics> call() => repository.getMetrics();
}
