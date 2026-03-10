import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/tenant_config.dart';
import 'package:fox_link_app/modules/tenant/domain/usecases/get_tenant_config_usecase.dart';

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
  final GetTenantConfigUseCase getTenantConfigUseCase;
  final TenantSession tenantSession;

  GetAvailableSlotsUseCase({
    required this.availabilityRepository,
    required this.schedulingRepository,
    required this.manualBlockRepository,
    required this.getTenantConfigUseCase,
    required this.tenantSession,
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

    // Fallback to tenant opening hours when no professional availability
    if (availability == null || !availability.isActive) {
      final tenantId = tenantSession.tenantId;
      if (tenantId != null) {
        final config = await getTenantConfigUseCase(tenantId);
        availability = _availabilityFromTenantConfig(config, date.weekday);
      }
    }

    if (availability == null || !availability.isActive) return [];

    final allDay = await schedulingRepository.getByProfessionalAndDate(
      professionalId: professionalId,
      date: date,
    );
    final blockedAppointments = allDay
        .where((a) =>
            a.status == AppointmentStatus.approved ||
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.rescheduleRequested)
        .toList();

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

    final slots = SlotGenerator.generateSlots(
      date: date,
      now: DateTime.now(),
      serviceDurationMinutes: durationMinutes,
      availability: availability,
      approvedAppointments: blockedAppointments,
      manualBlockRanges: manualBlockRanges,
    );

    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return slots;

    final config = await getTenantConfigUseCase(tenantId);
    if (!config.isOpenOnWeekday(date.weekday)) return [];

    return slots.where((slot) {
      final startMin = slot.hour * 60 + slot.minute;
      final endMin = startMin + durationMinutes;
      return config.isWithinOpeningHours(date.weekday, startMin, endMin);
    }).toList();
  }

  /// Creates Availability from tenant opening hours when professional has no weekly availability.
  static Availability? _availabilityFromTenantConfig(
    TenantConfig config,
    int weekday,
  ) {
    if (!config.isOpenOnWeekday(weekday)) return null;
    final ranges = config.getOpeningRangesMinutes(weekday);
    if (ranges.isEmpty) return null;
    final shifts = ranges
        .map((r) => TimeRange(startMinutes: r.start, endMinutes: r.end))
        .toList();
    return Availability(
      id: 'tenant-fallback',
      professionalId: '',
      weekday: weekday,
      isActive: true,
      shifts: shifts,
      slotIntervalMinutes: 30,
      breakTimes: const [],
    );
  }
}