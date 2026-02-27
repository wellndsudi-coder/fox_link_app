import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class CreateAppointmentUseCase {
  final SchedulingRepository repository;

  CreateAppointmentUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    final approved =
    await repository.getApprovedByProfessionalAndDate(
      professionalId: appointment.professionalId,
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
            "Horário já ocupado.");
      }
    }

    await repository.create(appointment);
  }
}