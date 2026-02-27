import '../entities/availability.dart';
import '../repositories/availability_repository.dart';

class SaveAvailability {
  final AvailabilityRepository repository;

  SaveAvailability(this.repository);

  Future<void> call(Availability availability) {
    return repository.saveWeeklyAvailability(availability);
  }
}