import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';
import '../repositories/manual_block_repository.dart';
import '../services/schedule_validator.dart';

class UpdateAppointmentTimeUseCase {
  final SchedulingRepository schedulingRepository;
  final ManualBlockRepository manualBlockRepository;

  UpdateAppointmentTimeUseCase({
    required this.schedulingRepository,
    required this.manualBlockRepository,
  });

  Future<void> call({
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    if (!newEnd.isAfter(newStart)) {
      throw Exception('Horário final deve ser após o inicial.');
    }
    final durationMinutes = newEnd.difference(newStart).inMinutes;
    if (durationMinutes < 5) {
      throw Exception('Duração mínima de 5 minutos.');
    }

    final appointment = await schedulingRepository.getById(appointmentId);
    if (appointment == null) {
      throw Exception('Agendamento não encontrado.');
    }
    if (appointment.status != AppointmentStatus.approved &&
        appointment.status != AppointmentStatus.pending) {
      throw Exception('Apenas agendamentos aprovados ou pendentes podem ser movidos.');
    }

    final date = DateTime(newStart.year, newStart.month, newStart.day);
    final startOfDay = date;
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final allDay = await schedulingRepository.getByProfessionalAndDate(
      professionalId: appointment.professionalId,
      date: date,
    );
    final blocked = allDay
        .where((a) =>
            a.id != appointmentId &&
            (a.status == AppointmentStatus.approved ||
                a.status == AppointmentStatus.pending ||
                a.status == AppointmentStatus.rescheduleRequested))
        .toList();

    final newAppointment = Appointment(
      id: appointment.id,
      tenantId: appointment.tenantId,
      serviceId: appointment.serviceId,
      baseServiceId: appointment.baseServiceId,
      selectedAddonIds: appointment.selectedAddonIds,
      clientId: appointment.clientId,
      professionalId: appointment.professionalId,
      scheduledStart: newStart,
      scheduledEnd: newEnd,
      finalPrice: appointment.finalPrice,
      finalDuration: durationMinutes,
      status: appointment.status,
      createdAt: appointment.createdAt,
      proposedStart: appointment.proposedStart,
      proposedEnd: appointment.proposedEnd,
      rescheduleMessage: appointment.rescheduleMessage,
      cancelledAt: appointment.cancelledAt,
    );
    ScheduleValidator.validateConflict(
      newAppointment: newAppointment,
      approvedAppointments: blocked,
    );

    final manualBlocks = await manualBlockRepository.getByProfessionalAndPeriod(
      professionalId: appointment.professionalId,
      start: startOfDay,
      end: endOfDay,
    );
    for (final b in manualBlocks) {
      if (newStart.isBefore(b.end) && newEnd.isAfter(b.start)) {
        throw ScheduleConflictException();
      }
    }

    await schedulingRepository.updateAppointmentTime(
      appointmentId: appointmentId,
      newStart: newStart,
      newEnd: newEnd,
    );
  }
}
