import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';

import '../entities/client_appointment_display.dart';

/// Stream de agendamentos do cliente para exibição em tempo real no dashboard.
class StreamClientAppointmentsDisplayUseCase {
  final SchedulingRepository schedulingRepository;
  final ServiceRepository serviceRepository;
  final ProfessionalRemoteDataSource professionalDataSource;
  final TenantSession tenantSession;

  StreamClientAppointmentsDisplayUseCase({
    required this.schedulingRepository,
    required this.serviceRepository,
    required this.professionalDataSource,
    required this.tenantSession,
  });

  Stream<List<ClientAppointmentDisplay>> call(String clientId) async* {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) {
      yield [];
      return;
    }

    final services = await serviceRepository.getAll(tenantId);
    final serviceNames = {for (final s in services) s.id: s.name.value};

    final pros = await professionalDataSource.getProfessionals();
    final professionalNames = {
      for (final p in pros) p['id'] as String: p['name'] as String? ?? 'Profissional'
    };

    await for (final appointments
        in schedulingRepository.streamByClient(clientId)) {
      if (appointments.isEmpty) {
        yield [];
        continue;
      }
      yield appointments.map((a) {
        return ClientAppointmentDisplay(
          appointment: a,
          serviceName: serviceNames[a.serviceId] ?? 'Serviço',
          professionalName: professionalNames[a.professionalId] ?? 'Profissional',
        );
      }).toList();
    }
  }
}
