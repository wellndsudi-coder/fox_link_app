import '../../../professionals/domain/usecases/get_professionals_by_service_usecase.dart';
import '../../../services/domain/repositories/service_repository.dart';
import '../../../scheduling/domain/usecases/get_available_slots_usecase.dart';

import '../../../../core/session/tenant_session.dart';
import '../entities/first_available_slot.dart';

class GetFirstAvailableSlotUseCase {
  final GetProfessionalsByServiceUseCase getProfessionalsByServiceUseCase;
  final ServiceRepository serviceRepository;
  final GetAvailableSlotsUseCase getAvailableSlotsUseCase;
  final TenantSession tenantSession;

  GetFirstAvailableSlotUseCase({
    required this.getProfessionalsByServiceUseCase,
    required this.serviceRepository,
    required this.getAvailableSlotsUseCase,
    required this.tenantSession,
  });

  /// Retorna até [limit] primeiros horários disponíveis, apenas de profissionais que executam o serviço.
  Future<List<FirstAvailableSlot>> getFirstAvailableSlots({
    required String serviceId,
    String? clientId,
    DateTime? forDate,
    int limit = 4,
  }) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return [];

    final services = await serviceRepository.getAll(tenantId);
    final service = services.where((s) => s.id == serviceId).firstOrNull;
    if (service == null) return [];

    final durationMinutes = service.baseDuration.minutes;
    final professionals = await getProfessionalsByServiceUseCase(serviceId);
    if (professionals.isEmpty) return [];

    final now = DateTime.now();
    final baseDate = forDate ?? now;
    var currentDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final maxDays = forDate != null ? 1 : 30;

    final collected = <FirstAvailableSlot>[];

    for (var dayOffset = 0; dayOffset < maxDays; dayOffset++) {
      final date = currentDate.add(Duration(days: dayOffset));

      for (final pro in professionals) {
        final proId = pro['id'] as String?;
        final proName = pro['name'] as String? ?? 'Profissional';
        if (proId == null) continue;

        final slots = await getAvailableSlotsUseCase(
          professionalId: proId,
          date: date,
          durationMinutes: durationMinutes,
        );

        for (final slot in slots) {
          collected.add(FirstAvailableSlot(
            professionalId: proId,
            professionalName: proName,
            slot: slot,
            serviceId: serviceId,
          ));
        }
      }
    }

    collected.sort((a, b) => a.slot.compareTo(b.slot));
    return collected.take(limit).toList();
  }

  Future<FirstAvailableSlot?> call({
    required String serviceId,
    String? clientId,
    DateTime? forDate,
  }) async {
    final list = await getFirstAvailableSlots(
      serviceId: serviceId,
      clientId: clientId,
      forDate: forDate,
      limit: 1,
    );
    return list.isNotEmpty ? list.first : null;
  }
}
