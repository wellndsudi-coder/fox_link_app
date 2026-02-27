import '../entities/availability.dart';
import '../repositories/availability_repository.dart';

class GetProfessionalAvailability {
  final AvailabilityRepository repository;

  GetProfessionalAvailability(this.repository);

  Future<List<Availability>> call(String professionalId) {
    return repository
        .getWeeklyAvailabilityByProfessional(professionalId);
  }
}