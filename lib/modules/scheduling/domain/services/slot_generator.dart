import '../../../availability/domain/entities/availability.dart';
import '../entities/appointment.dart';

class SlotGenerator {

  static List<DateTime> generateSlots({
    required DateTime date,
    required DateTime now,
    required int serviceDurationMinutes,
    required Availability availability,
    required List<Appointment> approvedAppointments,
  }) {

    if (!availability.isActive) return [];

    final List<DateTime> slots = [];

    final interval =
    availability.slotIntervalMinutes == 0
        ? serviceDurationMinutes
        : availability.slotIntervalMinutes;

    for (final shift in availability.shifts) {

      int current = shift.startMinutes;

      while (current + serviceDurationMinutes <= shift.endMinutes) {

        final slotStart = DateTime(
          date.year,
          date.month,
          date.day,
        ).add(Duration(minutes: current));

        final slotEnd =
        slotStart.add(Duration(minutes: serviceDurationMinutes));

        // ❌ Não permitir passado
        if (slotStart.isBefore(now)) {
          current += interval;
          continue;
        }

        // ❌ Conflito com breakTimes
        bool conflictBreak = false;

        for (final breakTime in availability.breakTimes) {
          final breakStart = DateTime(
            date.year,
            date.month,
            date.day,
          ).add(Duration(minutes: breakTime.startMinutes));

          final breakEnd = DateTime(
            date.year,
            date.month,
            date.day,
          ).add(Duration(minutes: breakTime.endMinutes));

          if (slotStart.isBefore(breakEnd) &&
              slotEnd.isAfter(breakStart)) {
            conflictBreak = true;
            break;
          }
        }

        if (conflictBreak) {
          current += interval;
          continue;
        }

        // ❌ Conflito com agendamentos aprovados
        bool conflictAppointment = false;

        for (final appointment in approvedAppointments) {
          if (slotStart.isBefore(appointment.scheduledEnd) &&
              slotEnd.isAfter(appointment.scheduledStart)) {
            conflictAppointment = true;
            break;
          }
        }

        if (conflictAppointment) {
          current += interval;
          continue;
        }

        slots.add(slotStart);

        current += interval;
      }
    }

    return slots;
  }
}