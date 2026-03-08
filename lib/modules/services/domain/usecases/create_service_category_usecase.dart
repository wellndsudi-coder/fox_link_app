import '../entities/service_category.dart';
import '../repositories/service_category_repository.dart';

class CreateServiceCategoryUseCase {
  final ServiceCategoryRepository repository;

  CreateServiceCategoryUseCase(this.repository);

  Future<void> call(ServiceCategory category) => repository.create(category);
}
