import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class RejectAppointmentUseCase {
  final SchedulingRepository repository;

  RejectAppointmentUseCase(this.repository);

  Future<void> call(Appointment appointment) async {
    if (appointment.status != AppointmentStatus.pending) {
      throw Exception('Apenas agendamentos pendentes podem ser rejeitados.');
    }
    await repository.updateStatus(
      appointment.id,
      AppointmentStatus.rejected,
    );
  }
}
