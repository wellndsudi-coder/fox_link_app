import '../../../scheduling/domain/repositories/scheduling_repository.dart';
import '../../../scheduling/domain/usecases/get_available_slots_usecase.dart';

import '../../../services/domain/repositories/service_repository.dart';
import '../../../../core/session/tenant_session.dart';

class QuickRescheduleUseCase {
  final SchedulingRepository schedulingRepository;
  final GetAvailableSlotsUseCase getAvailableSlotsUseCase;
  final ServiceRepository serviceRepository;
  final TenantSession tenantSession;

  QuickRescheduleUseCase({
    required this.schedulingRepository,
    required this.getAvailableSlotsUseCase,
    required this.serviceRepository,
    required this.tenantSession,
  });

  Future<List<DateTime>> call({
    required String appointmentId,
    required String clientId,
    int maxDays = 14,
  }) async {
    final appointment = await schedulingRepository.getById(appointmentId);
    if (appointment == null) return [];
    if (appointment.clientId != clientId) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return [];

    final services = await serviceRepository.getAll(tenantId);
    final service = services.where((s) => s.id == appointment.serviceId).firstOrNull;
    if (service == null) return [];

    final durationMinutes = service.baseDuration.minutes;
    final allSlots = <DateTime>[];

    for (var d = 0; d < maxDays; d++) {
      final date = today.add(Duration(days: d));
      final slots = await getAvailableSlotsUseCase(
        professionalId: appointment.professionalId,
        date: date,
        durationMinutes: durationMinutes,
      );
      allSlots.addAll(slots);
    }

    return allSlots;
  }
}
