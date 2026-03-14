import '../repositories/master_repository.dart';

class MasterUpdateTenantPlanUseCase {
  final MasterRepository repository;

  MasterUpdateTenantPlanUseCase(this.repository);

  Future<void> call({
    required String tenantId,
    required String plan,
  }) =>
      repository.updateTenantPlan(tenantId: tenantId, plan: plan);
}
