import '../entities/appointment.dart';

class ScheduleValidator {
  static void validateConflict({
    required Appointment newAppointment,
    required List<Appointment> approvedAppointments,
  }) {
    for (final appointment in approvedAppointments) {
      final overlap =
          newAppointment.scheduledStart.isBefore(appointment.scheduledEnd) &&
              newAppointment.scheduledEnd.isAfter(appointment.scheduledStart);

      if (overlap) {
        throw ScheduleConflictException();
      }
    }
  }
}

class ScheduleConflictException implements Exception {
  @override
  String toString() => 'Já existe um agendamento nesse horário.';
}