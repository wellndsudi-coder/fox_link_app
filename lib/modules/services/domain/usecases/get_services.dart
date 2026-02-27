import '../entities/service.dart';
import '../repositories/service_repository.dart';

class GetServices {
  final ServiceRepository repository;

  GetServices(this.repository);

  Future<List<Service>> call(String tenantId) async {
    return repository.getAll(tenantId);
  }
}