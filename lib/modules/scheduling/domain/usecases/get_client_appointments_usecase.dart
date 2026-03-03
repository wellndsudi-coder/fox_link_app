import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class GetClientAppointmentsUseCase {
  final SchedulingRepository repository;

  GetClientAppointmentsUseCase(this.repository);

  Future<List<Appointment>> call(String clientId) async {
    return repository.getByClient(clientId);
  }
}