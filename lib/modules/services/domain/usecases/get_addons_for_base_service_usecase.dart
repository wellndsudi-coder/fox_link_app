import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Returns add-ons (parentId == baseServiceId) for the given base service.
class GetAddonsForBaseServiceUseCase {
  final ServiceRepository repository;

  GetAddonsForBaseServiceUseCase(this.repository);

  Future<List<Service>> call(String tenantId, String baseServiceId) async {
    final all = await repository.getAll(tenantId);
    return all
        .where((s) =>
            !s.isBase &&
            s.parentId == baseServiceId &&
            s.isActive)
        .toList();
  }
}
