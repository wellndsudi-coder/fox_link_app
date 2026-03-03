import '../../../availability/domain/entities/availability.dart';
import '../../../availability/domain/entities/daily_override.dart';
import '../../../availability/domain/entities/blocked_date.dart';
import '../../../availability/domain/repositories/availability_repository.dart';

import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';
import '../services/slot_generator.dart';

class GetAvailableSlotsUseCase {

  final AvailabilityRepository availabilityRepository;
  final SchedulingRepository schedulingRepository;

  GetAvailableSlotsUseCase({
    required this.availabilityRepository,
    required this.schedulingRepository,
  });

  Future<List<DateTime>> call({
    required String professionalId,
    required DateTime date,
    required int durationMinutes,
  }) async {

    // 🔒 BLOCKED DATE
    final BlockedDate? blocked =
    await availabilityRepository.getBlockedDate(
      professionalId: professionalId,
      date: date,
    );

    if (blocked != null) return [];

    // 📅 DAILY OVERRIDE
    final DailyOverride? override =
    await availabilityRepository.getDailyOverride(
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

      availability =
      await availabilityRepository
          .getWeeklyAvailabilityByWeekday(
        professionalId: professionalId,
        weekday: date.weekday,
      );
    }

    if (availability == null || !availability.isActive) {
      return [];
    }

    final List<Appointment> approvedAppointments =
    await schedulingRepository
        .getApprovedByProfessionalAndDate(
      professionalId: professionalId,
      date: date,
    );

    return SlotGenerator.generateSlots(
      date: date,
      now: DateTime.now(),
      serviceDurationMinutes: durationMinutes,
      availability: availability,
      approvedAppointments: approvedAppointments,
    );
  }
}