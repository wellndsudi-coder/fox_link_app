import '../entities/appointment.dart';
import '../repositories/manual_block_repository.dart';
import '../repositories/scheduling_repository.dart';
import '../services/schedule_validator.dart';

class CreateAppointmentUseCase {
  final SchedulingRepository repository;
  final ManualBlockRepository manualBlockRepository;

  CreateAppointmentUseCase(this.repository, {required this.manualBlockRepository});

  Future<void> call(Appointment appointment) async {
    // 1. Garantir status inicial
    if (appointment.status != AppointmentStatus.pending) {
      throw Exception("Novo agendamento deve iniciar como pendente.");
    }

    // 2. Não permitir horário passado
    if (appointment.scheduledStart.isBefore(DateTime.now())) {
      throw Exception("Não é possível agendar horário passado.");
    }

    // 3. Validar intervalo
    if (!appointment.scheduledEnd.isAfter(appointment.scheduledStart)) {
      throw Exception("Horário final inválido.");
    }

    // 4. Validar conflito com agendamentos já existentes
    final allDay = await repository.getByProfessionalAndDate(
      professionalId: appointment.professionalId,
      date: appointment.scheduledStart,
    );
    final blocked = allDay
        .where((a) =>
            a.status == AppointmentStatus.approved ||
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.rescheduleRequested)
        .toList();

    ScheduleValidator.validateConflict(
      newAppointment: appointment,
      approvedAppointments: blocked,
    );

    // 5. Validar conflito com bloqueios manuais
    final date = DateTime(
      appointment.scheduledStart.year,
      appointment.scheduledStart.month,
      appointment.scheduledStart.day,
    );
    final startOfDay = date;
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final manualBlocks = await manualBlockRepository.getByProfessionalAndPeriod(
      professionalId: appointment.professionalId,
      start: startOfDay,
      end: endOfDay,
    );
    for (final b in manualBlocks) {
      if (appointment.scheduledStart.isBefore(b.end) &&
          appointment.scheduledEnd.isAfter(b.start)) {
        throw ScheduleConflictException();
      }
    }

    await repository.create(appointment);
  }
}