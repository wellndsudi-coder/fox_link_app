import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class ApproveAppointmentUseCase {

  final SchedulingRepository repository;

  ApproveAppointmentUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    final approved =
    await repository
        .getApprovedByProfessionalAndDate(
      professionalId:
      appointment.professionalId,
      date: appointment.scheduledStart,
    );

    for (final existing in approved) {

      final conflict =
          appointment.scheduledStart
              .isBefore(existing.scheduledEnd) &&
              appointment.scheduledEnd
                  .isAfter(existing.scheduledStart);

      if (conflict) {
        throw Exception(
          "Conflito de horário detectado.",
        );
      }
    }

    await repository.updateStatus(
      appointment.id,
      AppointmentStatus.approved,
    );
  }
}