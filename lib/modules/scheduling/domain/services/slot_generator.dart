import '../../../availability/domain/entities/availability.dart';
import '../entities/appointment.dart';

class SlotGenerator {

  static List<DateTime> generateSlots({
    required DateTime date,
    required DateTime now,
    required int serviceDurationMinutes,
    required Availability availability,
    required List<Appointment> approvedAppointments,
    List<TimeRange> manualBlockRanges = const [],
  }) {
    if (!availability.isActive) return [];

    final List<DateTime> slots = [];
    final interval =
        availability.slotIntervalMinutes == 0
            ? serviceDurationMinutes
            : availability.slotIntervalMinutes;
    final dayStart = DateTime(date.year, date.month, date.day);

    for (final shift in availability.shifts) {
      int current = shift.startMinutes;

      while (current + serviceDurationMinutes <= shift.endMinutes) {
        final slotStart = dayStart.add(Duration(minutes: current));
        final slotEnd = slotStart.add(Duration(minutes: serviceDurationMinutes));

        if (slotStart.isBefore(now)) {
          current += interval;
          continue;
        }

        bool conflictBreak = false;
        for (final breakTime in availability.breakTimes) {
          final breakStart = dayStart.add(Duration(minutes: breakTime.startMinutes));
          final breakEnd = dayStart.add(Duration(minutes: breakTime.endMinutes));
          if (slotStart.isBefore(breakEnd) && slotEnd.isAfter(breakStart)) {
            conflictBreak = true;
            break;
          }
        }
        if (conflictBreak) {
          current += interval;
          continue;
        }

        for (final block in manualBlockRanges) {
          final blockStart = dayStart.add(Duration(minutes: block.startMinutes));
          final blockEnd = dayStart.add(Duration(minutes: block.endMinutes));
          if (slotStart.isBefore(blockEnd) && slotEnd.isAfter(blockStart)) {
            conflictBreak = true;
            break;
          }
        }
        if (conflictBreak) {
          current += interval;
          continue;
        }

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