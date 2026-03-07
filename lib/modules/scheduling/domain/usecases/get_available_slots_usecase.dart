import '../../../availability/domain/entities/availability.dart';
import '../../../availability/domain/entities/daily_override.dart';
import '../../../availability/domain/entities/blocked_date.dart';
import '../../../availability/domain/repositories/availability_repository.dart';

import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';
import '../repositories/manual_block_repository.dart';
import '../services/slot_generator.dart';

class GetAvailableSlotsUseCase {
  final AvailabilityRepository availabilityRepository;
  final SchedulingRepository schedulingRepository;
  final ManualBlockRepository manualBlockRepository;

  GetAvailableSlotsUseCase({
    required this.availabilityRepository,
    required this.schedulingRepository,
    required this.manualBlockRepository,
  });

  Future<List<DateTime>> call({
    required String professionalId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    final BlockedDate? blocked = await availabilityRepository.getBlockedDate(
      professionalId: professionalId,
      date: date,
    );
    if (blocked != null) return [];

    final DailyOverride? override = await availabilityRepository.getDailyOverride(
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
        shifts: [
          TimeRange(
            startMinutes: override.startMinutes,
            endMinutes: override.endMinutes,
          ),
        ],
        slotIntervalMinutes: 0,
        breakTimes: const [],
      );
    } else {
      availability = await availabilityRepository.getWeeklyAvailabilityByWeekday(
        professionalId: professionalId,
        weekday: date.weekday,
      );
    }

    if (availability == null || !availability.isActive) return [];

    final List<Appointment> approvedAppointments =
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
    final manualBlockRanges = <TimeRange>[];
    for (final b in manualBlocks) {
      final blockStart = b.start.isBefore(startOfDay) ? startOfDay : b.start;
      final blockEnd = b.end.isAfter(endOfDay) ? endOfDay : b.end;
      if (!blockStart.isBefore(blockEnd)) continue;
      manualBlockRanges.add(TimeRange(
        startMinutes: blockStart.hour * 60 + blockStart.minute,
        endMinutes: blockEnd.hour * 60 + blockEnd.minute,
      ));
    }

    return SlotGenerator.generateSlots(
      date: date,
      now: DateTime.now(),
      serviceDurationMinutes: durationMinutes,
      availability: availability,
      approvedAppointments: approvedAppointments,
      manualBlockRanges: manualBlockRanges,
    );
  }
}