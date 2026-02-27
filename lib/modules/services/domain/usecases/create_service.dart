import '../entities/service.dart';
import '../repositories/service_repository.dart';

class CreateService {
  final ServiceRepository repository;

  CreateService(this.repository);

  Future<void> call(Service service) async {
    return repository.create(service);
  }
}