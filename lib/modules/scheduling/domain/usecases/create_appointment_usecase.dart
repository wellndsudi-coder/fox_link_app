import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class CreateAppointmentUseCase {
  final SchedulingRepository repository;

  CreateAppointmentUseCase(this.repository);

  Future<void> call(Appointment appointment) async {

    // 🔥 1️⃣ Garantir status inicial
    if (appointment.status != AppointmentStatus.pending) {
      throw Exception("Novo agendamento deve iniciar como pendente.");
    }

    // 🔥 2️⃣ Não permitir horário passado
    if (appointment.scheduledStart.isBefore(DateTime.now())) {
      throw Exception("Não é possível agendar horário passado.");
    }

    // 🔥 3️⃣ Validar intervalo
    if (!appointment.scheduledEnd
        .isAfter(appointment.scheduledStart)) {
      throw Exception("Horário final inválido.");
    }

    // 🔥 4️⃣ Validar conflito com horários já ocupados (aprovados, pendentes, reagendamento solicitado)
    final allDay = await repository.getByProfessionalAndDate(
      professionalId: appointment.professionalId,
      date: appointment.scheduledStart,
    );
    final blocked = allDay.where((a) =>
        a.status == AppointmentStatus.approved ||
        a.status == AppointmentStatus.pending ||
        a.status == AppointmentStatus.rescheduleRequested);

    for (final existing in blocked) {

      final conflict =
          appointment.scheduledStart
              .isBefore(existing.scheduledEnd) &&
              appointment.scheduledEnd
                  .isAfter(existing.scheduledStart);

      if (conflict) {
        throw Exception("Horário já ocupado.");
      }
    }

    await repository.create(appointment);
  }
}