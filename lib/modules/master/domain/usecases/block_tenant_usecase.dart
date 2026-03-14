import '../repositories/master_repository.dart';

class BlockTenantUseCase {
  final MasterRepository repository;

  BlockTenantUseCase(this.repository);

  Future<void> call(String tenantId) =>
      repository.blockTenant(tenantId: tenantId);
}
