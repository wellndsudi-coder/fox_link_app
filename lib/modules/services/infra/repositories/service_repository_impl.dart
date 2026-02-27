import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> create(Service service) async {
    final model = ServiceModel.fromEntity(service);
    return remoteDataSource.create(model);
  }

  @override
  Future<void> update(Service service) async {
    final model = ServiceModel.fromEntity(service);
    return remoteDataSource.update(model);
  }

  @override
  Future<List<Service>> getAll(String tenantId) async {
    return remoteDataSource.getAll(tenantId);
  }

  @override
  Future<void> toggleActive({
    required String serviceId,
    required String tenantId,
    required bool isActive,
  }) async {
    return remoteDataSource.toggleActive(
      serviceId: serviceId,
      isActive: isActive,
    );
  }

  @override
  Future<void> delete({
    required String serviceId,
    required String tenantId,
  }) async {
    return remoteDataSource.delete(serviceId);
  }
}