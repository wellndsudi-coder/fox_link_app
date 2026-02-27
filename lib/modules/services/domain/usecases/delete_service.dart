import '../repositories/service_repository.dart';

class DeleteService {
  final ServiceRepository repository;

  DeleteService(this.repository);

  Future<void> call({
    required String serviceId,
    required String tenantId,
  }) async {
    return repository.delete(
      serviceId: serviceId,
      tenantId: tenantId,
    );
  }
}