import '../entities/tenant_entity.dart';
import '../repositories/master_repository.dart';

class GetTenantsUseCase {
  final MasterRepository repository;

  GetTenantsUseCase(this.repository);

  Future<List<TenantEntity>> call() => repository.getTenants();
}
