import '../../../availability/domain/entities/availability.dart';
import '../entities/appointment.dart';

class SlotGenerator {

  static List<DateTime> generateSlots({
    required DateTime date,
    required DateTime now,
    required int serviceDurationMinutes,
    required int slotStepMinutes,
    required Availability availability,
    required List<Appointment> approvedAppointments,
  }) {

    final slots = <DateTime>[];

    if (!availability.isActive) return [];

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

        if (current.isBefore(now)) {
          current =
              current.add(Duration(minutes: slotStepMinutes));
          continue;
        }

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