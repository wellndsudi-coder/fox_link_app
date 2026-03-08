import '../../../availability/domain/entities/availability.dart';
import '../../../availability/domain/repositories/availability_repository.dart';
import '../../../scheduling/domain/repositories/scheduling_repository.dart';
import '../../../scheduling/domain/repositories/manual_block_repository.dart';

import '../entities/best_fit_slot.dart';

class FindBestFitSlotUseCase {
  final AvailabilityRepository availabilityRepository;
  final SchedulingRepository schedulingRepository;
  final ManualBlockRepository manualBlockRepository;

  FindBestFitSlotUseCase({
    required this.availabilityRepository,
    required this.schedulingRepository,
    required this.manualBlockRepository,
  });

  Future<BestFitSlot?> call({
    required String professionalId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    final blocked = await availabilityRepository.getBlockedDate(
      professionalId: professionalId,
      date: date,
    );
    if (blocked != null) return null;

    final override = await availabilityRepository.getDailyOverride(
      professionalId: professionalId,
      date: date,
    );

    Availability? availability;
    if (override != null) {
      availability = Availability(
        id: 'override-${override.id}',
        professionalId: professionalId,
        weekday: date.weekday,
        isActive: true,
        shifts: override.shifts,
        slotIntervalMinutes: override.slotIntervalMinutes,
        breakTimes: const [],
      );
    } else {
      availability = await availabilityRepository.getWeeklyAvailabilityByWeekday(
        professionalId: professionalId,
        weekday: date.weekday,
      );
    }

    if (availability == null || !availability.isActive) return null;

    final appointments =
        await schedulingRepository.getApprovedByProfessionalAndDate(
      professionalId: professionalId,
      date: date,
    );

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final manualBlocks = await manualBlockRepository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfDay,
      end: endOfDay,
    );

    final occupied = <_TimeSegment>[];
    for (final a in appointments) {
      occupied.add(_TimeSegment(a.scheduledStart, a.scheduledEnd));
    }
    for (final b in manualBlocks) {
      final blockStart = b.start.isBefore(startOfDay) ? startOfDay : b.start;
      final blockEnd = b.end.isAfter(endOfDay) ? endOfDay : b.end;
      if (!blockStart.isBefore(blockEnd)) continue;
      occupied.add(_TimeSegment(blockStart, blockEnd));
    }

    for (final shift in availability.shifts) {
      final shiftStart = startOfDay.add(Duration(minutes: shift.startMinutes));
      final shiftEnd = startOfDay.add(Duration(minutes: shift.endMinutes));

      final gaps = _findGaps(shiftStart, shiftEnd, occupied);
      for (final gap in gaps) {
        final gapDuration = gap.end.difference(gap.start).inMinutes;
        if (gapDuration >= durationMinutes) {
          return BestFitSlot(start: gap.start, end: gap.start.add(Duration(minutes: durationMinutes)));
        }
      }
    }

    return null;
  }

  List<_TimeSegment> _findGaps(
    DateTime rangeStart,
    DateTime rangeEnd,
    List<_TimeSegment> occupied,
  ) {
    final relevant = occupied
        .where((o) => o.start.isBefore(rangeEnd) && o.end.isAfter(rangeStart))
        .toList();
    relevant.sort((a, b) => a.start.compareTo(b.start));

    final gaps = <_TimeSegment>[];
    var current = rangeStart;

    for (final o in relevant) {
      final oStart = o.start.isBefore(rangeStart) ? rangeStart : o.start;
      final oEnd = o.end.isAfter(rangeEnd) ? rangeEnd : o.end;
      if (current.isBefore(oStart)) {
        gaps.add(_TimeSegment(current, oStart));
      }
      if (oEnd.isAfter(current)) {
        current = oEnd;
      }
    }
    if (current.isBefore(rangeEnd)) {
      gaps.add(_TimeSegment(current, rangeEnd));
    }

    return gaps;
  }
}

class _TimeSegment {
  final DateTime start;
  final DateTime end;
  _TimeSegment(this.start, this.end);
}
