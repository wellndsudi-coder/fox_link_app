import '../repositories/master_repository.dart';

class ExtendTrialUseCase {
  final MasterRepository repository;

  ExtendTrialUseCase(this.repository);

  Future<void> call({required String tenantId, required int days}) =>
      repository.extendTrial(tenantId: tenantId, days: days);
}
