import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';

import '../entities/client_appointment_display.dart';

class GetClientAppointmentsDisplayUseCase {
  final SchedulingRepository schedulingRepository;
  final ServiceRepository serviceRepository;
  final ProfessionalRemoteDataSource professionalDataSource;
  final TenantSession tenantSession;

  GetClientAppointmentsDisplayUseCase({
    required this.schedulingRepository,
    required this.serviceRepository,
    required this.professionalDataSource,
    required this.tenantSession,
  });

  Future<List<ClientAppointmentDisplay>> call(String clientId) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return [];

    final appointments = await schedulingRepository.getByClient(clientId);
    if (appointments.isEmpty) return [];

    final services = await serviceRepository.getAll(tenantId);
    final serviceNames = {for (final s in services) s.id: s.name.value};

    final pros = await professionalDataSource.getProfessionals();
    final professionalNames = {
      for (final p in pros) p['id'] as String: p['name'] as String? ?? 'Profissional'
    };

    return appointments.map((a) {
      return ClientAppointmentDisplay(
        appointment: a,
        serviceName: serviceNames[a.serviceId] ?? 'Serviço',
        professionalName: professionalNames[a.professionalId] ?? 'Profissional',
      );
    }).toList();
  }
}
