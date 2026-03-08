import '../entities/service_category.dart';
import '../repositories/service_category_repository.dart';

class GetServiceCategoriesUseCase {
  final ServiceCategoryRepository repository;

  GetServiceCategoriesUseCase(this.repository);

  Future<List<ServiceCategory>> call(String tenantId) =>
      repository.getAll(tenantId);
}
