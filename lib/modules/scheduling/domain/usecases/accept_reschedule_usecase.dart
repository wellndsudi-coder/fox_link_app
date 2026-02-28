import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class AcceptRescheduleUseCase {
  final SchedulingRepository repository;

  AcceptRescheduleUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    // 🔥 1️⃣ Só pode aceitar se estiver aguardando reagendamento
    if (appointment.status != AppointmentStatus.rescheduleRequested) {
      throw Exception("Agendamento não está aguardando reagendamento.");
    }

    if (appointment.proposedStart == null ||
        appointment.proposedEnd == null) {
      throw Exception("Não há proposta de reagendamento.");
    }

    final newStart = appointment.proposedStart!;
    final newEnd = appointment.proposedEnd!;

    // 🔥 2️⃣ Validar horário passado
    if (newStart.isBefore(DateTime.now())) {
      throw Exception("Não é possível reagendar para horário passado.");
    }

    // 🔥 3️⃣ Validar intervalo
    if (!newEnd.isAfter(newStart)) {
      throw Exception("Horário final inválido.");
    }

    // 🔥 4️⃣ Validar conflito novamente
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

    await repository.confirmReschedule(
      appointmentId: appointment.id,
      newStart: newStart,
      newEnd: newEnd,
    );
  }
}