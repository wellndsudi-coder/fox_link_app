import '../../domain/entities/service_category.dart';
import '../../domain/repositories/service_category_repository.dart';
import '../datasources/service_category_remote_datasource.dart';

class ServiceCategoryRepositoryImpl implements ServiceCategoryRepository {
  final ServiceCategoryRemoteDataSource dataSource;

  ServiceCategoryRepositoryImpl(this.dataSource);

  @override
  Future<List<ServiceCategory>> getAll(String tenantId) =>
      dataSource.getAll(tenantId);

  @override
  Future<void> create(ServiceCategory category) => dataSource.create(category);

  @override
  Future<void> update(ServiceCategory category) => dataSource.update(category);

  @override
  Future<void> delete(String id, String tenantId) =>
      dataSource.delete(id, tenantId);
}
