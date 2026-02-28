import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class ApproveAppointmentUseCase {

  final SchedulingRepository repository;

  ApproveAppointmentUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    // 🔥 1️⃣ Não permitir horário passado
    if (appointment.scheduledStart.isBefore(DateTime.now())) {
      throw Exception("Não é possível aprovar horário passado.");
    }

    // 🔥 2️⃣ Só pode aprovar se estiver pendente
    if (appointment.status != AppointmentStatus.pending) {
      throw Exception("Apenas agendamentos pendentes podem ser aprovados.");
    }

    final approved =
    await repository.getApprovedByProfessionalAndDate(
      professionalId: appointment.professionalId,
      date: appointment.scheduledStart,
    );

    for (final existing in approved) {

      // 🔥 Ignorar ele mesmo (segurança extra)
      if (existing.id == appointment.id) continue;

      final conflict =
          appointment.scheduledStart.isBefore(existing.scheduledEnd) &&
              appointment.scheduledEnd.isAfter(existing.scheduledStart);

      if (conflict) {
        throw Exception("Conflito de horário detectado.");
      }
    }

    await repository.updateStatus(
      appointment.id,
      AppointmentStatus.approved,
    );
  }
}