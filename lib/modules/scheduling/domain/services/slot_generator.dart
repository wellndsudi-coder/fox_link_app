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

    final slots = <DateTime>[];

    if (!availability.isActive) return [];

    final slotStepMinutes =
    availability.slotIntervalMinutes == 0
        ? serviceDurationMinutes
        : availability.slotIntervalMinutes;

    for (final shift in availability.shifts) {

      final shiftStart = DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: shift.startMinutes));

      final shiftEnd = DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: shift.endMinutes));

      DateTime current = shiftStart;

      while (true) {

        final slotEnd =
        current.add(Duration(minutes: serviceDurationMinutes));

        if (slotEnd.isAfter(shiftEnd)) break;

        // 🔒 Não permitir horário passado
        if (current.isBefore(now)) {
          current =
              current.add(Duration(minutes: slotStepMinutes));
          continue;
        }

        // 🍽 Ignorar múltiplos intervalos de refeição
        bool overlapsAnyBreak = false;

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

          final overlapsBreak =
              current.isBefore(breakEnd) &&
                  slotEnd.isAfter(breakStart);

          if (overlapsBreak) {
            overlapsAnyBreak = true;
            break;
          }
        }

        if (overlapsAnyBreak) {
          current =
              current.add(Duration(minutes: slotStepMinutes));
          continue;
        }

        // 🔒 Conflito com agendamentos aprovados
        final hasConflict =
        approvedAppointments.any((appointment) {
          return current.isBefore(appointment.scheduledEnd) &&
              slotEnd.isAfter(appointment.scheduledStart);
        });

        if (!hasConflict) {
          slots.add(current);
        }

        current =
            current.add(Duration(minutes: slotStepMinutes));
      }
    }

    return slots;
  }
}