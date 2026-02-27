import '../../../availability/domain/entities/availability.dart';
import '../../../availability/domain/entities/daily_override.dart';
import '../../../availability/domain/entities/blocked_date.dart';
import '../entities/appointment.dart';

class SlotGenerator {
  static List<DateTime> generateSlots({
    required DateTime date,
    required int durationMinutes,
    required Availability weeklyAvailability,
    DailyOverride? dailyOverride,
    BlockedDate? blockedDate,
    required List<Appointment> approvedAppointments,
  }) {
    final slots = <DateTime>[];

    // 🔒 1️⃣ Dia bloqueado
    if (blockedDate != null) {
      return [];
    }

    // 🔎 2️⃣ Validar weekday
    if (weeklyAvailability.weekday != _mapWeekday(date.weekday)) {
      return [];
    }

    // 🕒 3️⃣ Definir intervalo base
    final startMinutes =
        dailyOverride?.startMinutes ?? weeklyAvailability.startMinutes;

    final endMinutes =
        dailyOverride?.endMinutes ?? weeklyAvailability.endMinutes;

    final dayStart = DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: startMinutes));

    final dayEnd = DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: endMinutes));

    DateTime current = dayStart;

    while (current.add(Duration(minutes: durationMinutes)).isBefore(dayEnd) ||
        current.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(dayEnd)) {

      final slotEnd = current.add(Duration(minutes: durationMinutes));

      // ⏳ 4️⃣ Remover horário passado
      if (slotEnd.isBefore(DateTime.now())) {
        current = current.add(Duration(minutes: durationMinutes));
        continue;
      }

      // ☕ 5️⃣ Remover intervalo de pausa (apenas weekly base)
      final currentMinutes = current.hour * 60 + current.minute;

      final isBreak =
          weeklyAvailability.breakStartMinutes != null &&
              weeklyAvailability.breakEndMinutes != null &&
              currentMinutes >= weeklyAvailability.breakStartMinutes! &&
              currentMinutes < weeklyAvailability.breakEndMinutes!;

      if (isBreak) {
        current = current.add(Duration(minutes: durationMinutes));
        continue;
      }

      // 📅 6️⃣ Verificar conflito com agendamentos aprovados
      final hasConflict = approvedAppointments.any((appointment) {
        return _isOverlapping(
          current,
          slotEnd,
          appointment.scheduledStart,
          appointment.scheduledEnd,
        );
      });

      if (!hasConflict) {
        slots.add(current);
      }

      current = current.add(Duration(minutes: durationMinutes));
    }

    return slots;
  }

  static bool _isOverlapping(
      DateTime startA,
      DateTime endA,
      DateTime startB,
      DateTime endB,
      ) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }

  static int _mapWeekday(int dartWeekday) {
    // Dart: 1 = Monday, 7 = Sunday
    return dartWeekday;
  }
}