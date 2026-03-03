import '../repositories/scheduling_repository.dart';

class CancelAppointmentUseCase {
  final SchedulingRepository repository;

  CancelAppointmentUseCase(this.repository);

  Future<void> call(String appointmentId) async {
    await repository.cancelAppointment(
      appointmentId: appointmentId,
    );
  }
}