import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class AcceptRescheduleUseCase {
  final SchedulingRepository repository;

  AcceptRescheduleUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    if (appointment.proposedStart == null ||
        appointment.proposedEnd == null) {
      throw Exception("Não há proposta de reagendamento.");
    }

    await repository.confirmReschedule(
      appointmentId: appointment.id,
      newStart: appointment.proposedStart!,
      newEnd: appointment.proposedEnd!,
    );
  }
}