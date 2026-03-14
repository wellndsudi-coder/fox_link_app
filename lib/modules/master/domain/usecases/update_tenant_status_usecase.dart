import '../repositories/master_repository.dart';

class UpdateTenantStatusUseCase {
  final MasterRepository repository;

  UpdateTenantStatusUseCase(this.repository);

  Future<void> call({
    required String tenantId,
    required String status,
  }) =>
      repository.updateTenantStatus(tenantId: tenantId, status: status);
}
