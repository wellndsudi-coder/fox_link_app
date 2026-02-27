import '../entities/service.dart';

abstract class ServiceRepository {
  Future<void> create(Service service);

  Future<void> update(Service service);

  Future<List<Service>> getAll(String tenantId);

  Future<void> toggleActive({
    required String serviceId,
    required String tenantId,
    required bool isActive,
  });

  Future<void> delete({
    required String serviceId,
    required String tenantId,
  });
}