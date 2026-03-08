import '../../../availability/domain/entities/availability.dart';
import '../../../availability/domain/repositories/availability_repository.dart';
import '../repositories/manual_block_repository.dart';
import '../repositories/scheduling_repository.dart';

class DayAgendaStats {
  final DateTime date;
  final int appointmentCount;
  final int bookedMinutes;
  final int capacityMinutes;
  final double occupancyPct;

  const DayAgendaStats({
    required this.date,
    required this.appointmentCount,
    required this.bookedMinutes,
    required this.capacityMinutes,
    required this.occupancyPct,
  });
}

class GetMonthlyAgendaStatsUseCase {
  final AvailabilityRepository _availabilityRepo;
  final SchedulingRepository _schedulingRepo;
  final ManualBlockRepository _manualBlockRepo;

  GetMonthlyAgendaStatsUseCase({
    required AvailabilityRepository availabilityRepository,
    required SchedulingRepository schedulingRepository,
    required ManualBlockRepository manualBlockRepository,
  })  : _availabilityRepo = availabilityRepository,
        _schedulingRepo = schedulingRepository,
        _manualBlockRepo = manualBlockRepository;

  Future<Map<DateTime, DayAgendaStats>> call({
    required String professionalId,
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0).day;
    final endOfMonth = DateTime(year, month, lastDay, 23, 59, 59);

    final appointments = await _schedulingRepo.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfMonth,
      end: endOfMonth,
    );

    final manualBlocks = await _manualBlockRepo.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfMonth,
      end: endOfMonth,
    );

    final result = <DateTime, DayAgendaStats>{};

    for (var day = 1; day <= lastDay; day++) {
      final date = DateTime(year, month, day);

      final override = await _availabilityRepo.getDailyOverride(
        professionalId: professionalId,
        date: date,
      );

      List<TimeRange> shifts;
      List<TimeRange> breakTimes;
      if (override != null && override.shifts.isNotEmpty) {
        shifts = override.shifts;
        breakTimes = [];
      } else {
        final avail = await _availabilityRepo.getWeeklyAvailabilityByWeekday(
          professionalId: professionalId,
          weekday: date.weekday,
        );
        if (avail == null || !avail.isActive || avail.shifts.isEmpty) {
          result[date] = DayAgendaStats(
            date: date,
            appointmentCount: 0,
            bookedMinutes: 0,
            capacityMinutes: 0,
            occupancyPct: 0,
          );
          continue;
        }
        shifts = avail.shifts;
        breakTimes = avail.breakTimes;
      }

      int capacity = 0;
      for (final s in shifts) {
        capacity += s.endMinutes - s.startMinutes;
      }
      for (final b in breakTimes) {
        capacity -= b.endMinutes - b.startMinutes;
      }
      capacity = capacity.clamp(0, 1440);

      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      for (final b in manualBlocks) {
        if (b.start.isBefore(dayEnd) && b.end.isAfter(dayStart)) {
          final blockStart = b.start.isBefore(dayStart) ? 0 : (b.start.hour * 60 + b.start.minute);
          final blockEnd = b.end.isAfter(dayEnd)
              ? 24 * 60
              : (b.end.hour * 60 + b.end.minute);
          capacity -= (blockEnd - blockStart).clamp(0, 1440);
        }
      }
      capacity = capacity.clamp(0, 1440);

      int booked = 0;
      int count = 0;
      for (final a in appointments) {
        if (a.status.name != 'cancelled' &&
            a.status.name != 'rejected' &&
            a.scheduledStart.year == year &&
            a.scheduledStart.month == month &&
            a.scheduledStart.day == day) {
          booked += a.finalDuration;
          count++;
        }
      }

      final pct = capacity > 0 ? (booked / capacity * 100) : 0.0;

      result[date] = DayAgendaStats(
        date: date,
        appointmentCount: count,
        bookedMinutes: booked,
        capacityMinutes: capacity,
        occupancyPct: pct.clamp(0.0, 100.0),
      );
    }

    return result;
  }
}
