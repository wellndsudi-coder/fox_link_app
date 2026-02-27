import '../repositories/service_repository.dart';

class ToggleServiceActive {
  final ServiceRepository repository;

  ToggleServiceActive(this.repository);

  Future<void> call({
    required String serviceId,
    required String tenantId,
    required bool isActive,
  }) async {
    return repository.toggleActive(
      serviceId: serviceId,
      tenantId: tenantId,
      isActive: isActive,
    );
  }
}