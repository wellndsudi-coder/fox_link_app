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
    // 1️⃣ Buscar weekly base
    final Availability? weekly =
    await availabilityRepository.getWeeklyAvailabilityByWeekday(
      professionalId: professionalId,
      weekday: date.weekday,
    );

    if (weekly == null) {
      return [];
    }

    // 2️⃣ Buscar override do dia
    final DailyOverride? override =
    await availabilityRepository.getDailyOverride(
      professionalId: professionalId,
      date: date,
    );

    // 3️⃣ Buscar bloqueio do dia
    final BlockedDate? blocked =
    await availabilityRepository.getBlockedDate(
      professionalId: professionalId,
      date: date,
    );

    // 4️⃣ Buscar agendamentos aprovados
    final List<Appointment> approvedAppointments =
    await schedulingRepository
        .getApprovedByProfessionalAndDate(
      professionalId: professionalId,
      date: date,
    );

    // 5️⃣ Gerar slots (regra pura)
    return SlotGenerator.generateSlots(
      date: date,
      durationMinutes: durationMinutes,
      weeklyAvailability: weekly,
      dailyOverride: override,
      blockedDate: blocked,
      approvedAppointments: approvedAppointments,
    );
  }
}