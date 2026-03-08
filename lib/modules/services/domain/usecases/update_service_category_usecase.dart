import '../entities/service_category.dart';
import '../repositories/service_category_repository.dart';

class UpdateServiceCategoryUseCase {
  final ServiceCategoryRepository repository;

  UpdateServiceCategoryUseCase(this.repository);

  Future<void> call(ServiceCategory category) => repository.update(category);
}
