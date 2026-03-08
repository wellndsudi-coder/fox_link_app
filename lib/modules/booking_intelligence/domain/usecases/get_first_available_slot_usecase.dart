import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../services/domain/repositories/service_repository.dart';
import '../../../scheduling/domain/usecases/get_available_slots_usecase.dart';

import '../../../../core/session/tenant_session.dart';
import '../entities/first_available_slot.dart';

class GetFirstAvailableSlotUseCase {
  final ProfessionalRemoteDataSource professionalDataSource;
  final ServiceRepository serviceRepository;
  final GetAvailableSlotsUseCase getAvailableSlotsUseCase;
  final TenantSession tenantSession;

  GetFirstAvailableSlotUseCase({
    required this.professionalDataSource,
    required this.serviceRepository,
    required this.getAvailableSlotsUseCase,
    required this.tenantSession,
  });

  Future<FirstAvailableSlot?> call({
    required String serviceId,
    String? clientId,
    DateTime? forDate,
  }) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return null;

    final services = await serviceRepository.getAll(tenantId);
    final service = services.where((s) => s.id == serviceId).firstOrNull;
    if (service == null) return null;

    final durationMinutes = service.baseDuration.minutes;
    final professionals = await professionalDataSource.getProfessionals();

    final now = DateTime.now();
    final baseDate = forDate ?? now;
    var currentDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final maxDays = forDate != null ? 1 : 30;

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

        if (slots.isNotEmpty) {
          return FirstAvailableSlot(
            professionalId: proId,
            professionalName: proName,
            slot: slots.first,
            serviceId: serviceId,
          );
        }
      }
    }

    return null;
  }
}
