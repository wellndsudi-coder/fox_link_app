import '../repositories/service_category_repository.dart';

class DeleteServiceCategoryUseCase {
  final ServiceCategoryRepository repository;

  DeleteServiceCategoryUseCase(this.repository);

  Future<void> call(String id, String tenantId) =>
      repository.delete(id, tenantId);
}
