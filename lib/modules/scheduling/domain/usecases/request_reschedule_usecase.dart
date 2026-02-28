import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class RequestRescheduleUseCase {
  final SchedulingRepository repository;

  RequestRescheduleUseCase(this.repository);

  Future<void> call({
    required Appointment appointment,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {

    // 🔥 1️⃣ Só pode reagendar approved
    if (appointment.status != AppointmentStatus.approved) {
      throw Exception("Apenas agendamentos aprovados podem ser reagendados.");
    }

    // 🔥 2️⃣ Não permitir horário passado
    if (newStart.isBefore(DateTime.now())) {
      throw Exception("Não é possível reagendar para horário passado.");
    }

    // 🔥 3️⃣ Validar intervalo
    if (!newEnd.isAfter(newStart)) {
      throw Exception("Horário final inválido.");
    }

    // 🔥 4️⃣ Validar conflito
    final approved =
    await repository.getApprovedByProfessionalAndDate(
      professionalId: appointment.professionalId,
      date: newStart,
    );

    for (final existing in approved) {

      if (existing.id == appointment.id) continue;

      final conflict =
          newStart.isBefore(existing.scheduledEnd) &&
              newEnd.isAfter(existing.scheduledStart);

      if (conflict) {
        throw Exception("Conflito de horário detectado.");
      }
    }

    await repository.requestReschedule(
      appointmentId: appointment.id,
      proposedStart: newStart,
      proposedEnd: newEnd,
    );
  }
}