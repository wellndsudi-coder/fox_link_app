import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';

/// DTO para exibicao de agendamento na agenda do dia.
class TodayAppointmentDisplay {
  final String appointmentId;
  final String clientName;
  final AppointmentStatus status;
  final String time;
  final String serviceName;
  final String professionalName;

  const TodayAppointmentDisplay({
    required this.appointmentId,
    required this.clientName,
    required this.status,
    required this.time,
    required this.serviceName,
    required this.professionalName,
  });
}

class GetTodayAgendaUseCase {
  final SchedulingRepository schedulingRepository;
  final UserRepository? userRepository;
  final ServiceRepository? serviceRepository;
  final ProfessionalRemoteDataSource professionalDataSource;
  final TenantSession session;

  GetTodayAgendaUseCase(
    this.schedulingRepository,
    this.professionalDataSource,
    this.session, {
    UserRepository? userRepository,
    ServiceRepository? serviceRepository,
  })  : userRepository = userRepository,
        serviceRepository = serviceRepository;

  Future<List<TodayAppointmentDisplay>> call() async {
    final tenantId = session.tenantId;
    if (tenantId == null) return [];

    final today = DateTime.now();
    final appointments =
        await schedulingRepository.getByTenantAndDate(today);

    if (appointments.isEmpty) return [];

    final clientIds = appointments.map((a) => a.clientId).toSet().toList();

    final clientNames = <String, String>{};
    if (userRepository != null && clientIds.isNotEmpty) {
      final users = await userRepository!.getUsersByIds(clientIds);
      for (var i = 0; i < clientIds.length && i < users.length; i++) {
        final u = users[i];
        clientNames[clientIds[i]] = (u['name'] as String?) ??
            (u['displayName'] as String?) ??
            (u['email'] as String?) ??
            'Cliente';
      }
    }

    final serviceNames = <String, String>{};
    if (serviceRepository != null) {
      final services = await serviceRepository!.getAll(tenantId);
      for (final s in services) {
        serviceNames[s.id] = s.name.value;
      }
    }

    final professionalNames = <String, String>{};
    final professionals = await professionalDataSource.getProfessionals();
    for (final p in professionals) {
      final id = p['id'] as String?;
      if (id != null) {
        professionalNames[id] = p['name'] as String? ?? 'Profissional';
      }
    }

    return appointments.map((a) {
      final timeStr =
          '${a.scheduledStart.hour.toString().padLeft(2, '0')}:${a.scheduledStart.minute.toString().padLeft(2, '0')}';
      return TodayAppointmentDisplay(
        appointmentId: a.id,
        clientName: clientNames[a.clientId] ?? 'Cliente',
        status: a.status,
        time: timeStr,
        serviceName: serviceNames[a.serviceId] ?? 'Serviço',
        professionalName: professionalNames[a.professionalId] ?? 'Profissional',
      );
    }).toList();
  }
}
