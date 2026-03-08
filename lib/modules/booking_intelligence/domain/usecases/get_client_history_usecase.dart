import '../../../professionals/infra/datasources/professional_remote_datasource.dart';
import '../../../scheduling/domain/entities/appointment.dart';
import '../../../scheduling/domain/repositories/scheduling_repository.dart';
import '../../../services/domain/repositories/service_repository.dart';

import '../../../../core/session/tenant_session.dart';
import '../entities/client_history_item.dart';

class GetClientHistoryUseCase {
  final SchedulingRepository schedulingRepository;
  final ServiceRepository serviceRepository;
  final ProfessionalRemoteDataSource professionalDataSource;
  final TenantSession tenantSession;

  GetClientHistoryUseCase({
    required this.schedulingRepository,
    required this.serviceRepository,
    required this.professionalDataSource,
    required this.tenantSession,
  });

  Future<List<ClientHistoryItem>> call(String clientId) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return [];

    final appointments = await schedulingRepository.getByClient(clientId);
    final past = appointments
        .where((a) =>
            a.scheduledStart.isBefore(DateTime.now()) ||
            a.status == AppointmentStatus.completed ||
            a.status == AppointmentStatus.cancelled)
        .toList();
    past.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    final services = await serviceRepository.getAll(tenantId);
    final serviceNames = {for (final s in services) s.id: s.name.value};

    final pros = await professionalDataSource.getProfessionals();
    final professionalNames = {for (final p in pros) p['id'] as String: p['name'] as String? ?? 'Profissional'};

    return past
        .map((a) => ClientHistoryItem(
              appointmentId: a.id,
              serviceId: a.serviceId,
              serviceName: serviceNames[a.serviceId] ?? 'Serviço',
              professionalId: a.professionalId,
              professionalName: professionalNames[a.professionalId] ?? 'Profissional',
              scheduledStart: a.scheduledStart,
              scheduledEnd: a.scheduledEnd,
            ))
        .toList();
  }
}
