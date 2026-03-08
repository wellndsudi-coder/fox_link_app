import '../entities/service_category.dart';

abstract class ServiceCategoryRepository {
  Future<List<ServiceCategory>> getAll(String tenantId);
  Future<void> create(ServiceCategory category);
  Future<void> update(ServiceCategory category);
  Future<void> delete(String id, String tenantId);
}
