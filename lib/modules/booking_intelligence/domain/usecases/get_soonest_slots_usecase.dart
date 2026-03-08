import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../professionals/domain/usecases/get_professionals_by_service_usecase.dart';
import '../../../services/domain/repositories/service_repository.dart';
import '../../../scheduling/domain/usecases/get_available_slots_usecase.dart';

import '../../../../core/session/tenant_session.dart';
import '../entities/soonest_slots.dart';

class GetSoonestSlotsUseCase {
  final ProfessionalRemoteDataSource professionalDataSource;
  final GetProfessionalsByServiceUseCase getProfessionalsByServiceUseCase;
  final ServiceRepository serviceRepository;
  final GetAvailableSlotsUseCase getAvailableSlotsUseCase;
  final TenantSession tenantSession;

  GetSoonestSlotsUseCase({
    required this.professionalDataSource,
    required this.getProfessionalsByServiceUseCase,
    required this.serviceRepository,
    required this.getAvailableSlotsUseCase,
    required this.tenantSession,
  });

  Future<SoonestSlots> call({
    required String serviceId,
    List<String>? addonIds,
    String? professionalId,
  }) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return const SoonestSlots(slots: []);

    final services = await serviceRepository.getAll(tenantId);
    final baseService = services.where((s) => s.id == serviceId).firstOrNull;
    if (baseService == null) return const SoonestSlots(slots: []);

    var durationMinutes = baseService.baseDuration.minutes;
    if (addonIds != null && addonIds.isNotEmpty) {
      for (final aid in addonIds) {
        final addon = services.where((s) => s.id == aid).firstOrNull;
        if (addon != null) durationMinutes += addon.baseDuration.minutes;
      }
    }
    final now = DateTime.now();

    List<Map<String, dynamic>> professionals;
    if (professionalId != null) {
      final all = await getProfessionalsByServiceUseCase(serviceId);
      final pro = all.where((p) => p['id'] == professionalId).firstOrNull;
      professionals = pro != null ? [pro] : all;
    } else {
      professionals = await getProfessionalsByServiceUseCase(serviceId);
    }

    final candidates = <SoonestSlot>[];

    for (var daysAhead = 0; daysAhead < 14 && candidates.length < 3; daysAhead++) {
      final date = now.add(Duration(days: daysAhead));
      final targetDate = DateTime(date.year, date.month, date.day);

      for (final pro in professionals) {
        if (candidates.length >= 3) break;
        final proId = pro['id'] as String?;
        final proName = pro['name'] as String? ?? 'Profissional';
        if (proId == null) continue;

        final slots = await getAvailableSlotsUseCase(
          professionalId: proId,
          date: targetDate,
          durationMinutes: durationMinutes,
        );

        for (final slot in slots) {
          if (slot.isBefore(now)) continue;
          if (candidates.length >= 3) break;
          final mins = slot.difference(now).inMinutes;
          candidates.add(SoonestSlot(
            dateTime: slot,
            professionalId: proId,
            professionalName: proName,
            serviceId: serviceId,
            minutesFromNow: mins,
          ));
        }
      }
    }

    candidates.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return SoonestSlots(
      slots: candidates.take(3).toList(),
    );
  }
}
