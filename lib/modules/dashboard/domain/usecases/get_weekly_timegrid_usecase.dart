import 'package:fox_link_app/core/utils/appointment_status_label.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/users/domain/repositories/user_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';

class TimeGridBlock {
  final String appointmentId;
  final int weekday;
  final int startMinutes;
  final int durationMinutes;

  final AppointmentStatus status;
  final String statusLabel;

  final String clientLabel;
  final String serviceLabel;
  final String? notes;

  final double topFactor;
  final double heightFactor;

  TimeGridBlock({
    required this.appointmentId,
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
    required this.status,
    required this.statusLabel,
    required this.clientLabel,
    required this.serviceLabel,
    this.notes,
    required this.topFactor,
    required this.heightFactor,
  });
}

class GetWeeklyTimeGridUseCase {
  final SchedulingRepository repository;
  final UserRepository? userRepository;
  final ServiceRepository? serviceRepository;

  GetWeeklyTimeGridUseCase(
    this.repository, {
    UserRepository? userRepository,
    ServiceRepository? serviceRepository,
  })  : userRepository = userRepository,
        serviceRepository = serviceRepository;

  Future<List<TimeGridBlock>> call({
    required String professionalId,
    required DateTime referenceDate,
    String? tenantId,
  }) async {
    final startOfWeek =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Mesma query em web e APK (APK funciona; web deve usar o mesmo caminho).
    final appointments = await repository.getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: startOfWeek,
      end: endOfWeek,
    );

    Map<String, String> clientNames = {};
    Map<String, String> serviceNames = {};
    if (tenantId != null && tenantId.isNotEmpty) {
      if (userRepository != null) {
        final clientIds = appointments.map((a) => a.clientId).toSet().toList();
        if (clientIds.isNotEmpty) {
          final users = await userRepository!.getUsersByIds(clientIds);
          for (var i = 0; i < clientIds.length && i < users.length; i++) {
            final u = users[i];
            clientNames[clientIds[i]] = (u['name'] as String?) ??
                (u['displayName'] as String?) ??
                (u['email'] as String?) ??
                clientIds[i];
          }
        }
      }
      if (serviceRepository != null) {
        final services = await serviceRepository!.getAll(tenantId);
        for (final s in services) {
          serviceNames[s.id] = s.name.value;
        }
      }
    }

    const gridStart = 7 * 60;
    const gridEnd = 20 * 60;
    const totalMinutes = gridEnd - gridStart;
    final List<TimeGridBlock> blocks = [];

    final activeAppointments = appointments
        .where((a) => a.status != AppointmentStatus.cancelled)
        .toList();

    for (final appointment in activeAppointments) {
      final weekday = appointment.scheduledStart.weekday;
      final startMinutes =
          appointment.scheduledStart.hour * 60 +
          appointment.scheduledStart.minute;
      final topFactor =
          ((startMinutes - gridStart) / totalMinutes).clamp(0.0, 1.0);
      final heightFactor =
          (appointment.finalDuration / totalMinutes).clamp(0.0, 1.0);

      blocks.add(
        TimeGridBlock(
          appointmentId: appointment.id,
          weekday: weekday,
          startMinutes: startMinutes,
          durationMinutes: appointment.finalDuration,
          status: appointment.status,
          statusLabel: getAppointmentStatusLabel(appointment),
          clientLabel: clientNames[appointment.clientId] ?? 'Cliente',
          serviceLabel: serviceNames[appointment.serviceId] ?? 'Serviço',
          notes: appointment.notes,
          topFactor: topFactor,
          heightFactor: heightFactor,
        ),
      );
    }

    return blocks;
  }

  Stream<List<TimeGridBlock>> stream({
    required String professionalId,
    required DateTime referenceDate,
    String? tenantId,
  }) {
    final startOfWeek =
        referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return repository
        .streamByProfessionalAndPeriod(
          professionalId: professionalId,
          start: startOfWeek,
          end: endOfWeek,
        )
        .asyncMap((appointments) async {
      Map<String, String> clientNames = {};
      Map<String, String> serviceNames = {};
      if (tenantId != null && tenantId.isNotEmpty) {
        if (userRepository != null) {
          final clientIds = appointments.map((a) => a.clientId).toSet().toList();
          if (clientIds.isNotEmpty) {
            final users = await userRepository!.getUsersByIds(clientIds);
            for (var i = 0; i < clientIds.length && i < users.length; i++) {
              final u = users[i];
              clientNames[clientIds[i]] = (u['name'] as String?) ??
                  (u['displayName'] as String?) ??
                  (u['email'] as String?) ??
                  clientIds[i];
            }
          }
        }
        if (serviceRepository != null) {
          final services = await serviceRepository!.getAll(tenantId);
          for (final s in services) {
            serviceNames[s.id] = s.name.value;
          }
        }
      }

      const gridStart = 7 * 60;
      const gridEnd = 20 * 60;
      const totalMinutes = gridEnd - gridStart;
      final List<TimeGridBlock> blocks = [];
      final active = appointments
          .where((a) => a.status != AppointmentStatus.cancelled)
          .toList();

      for (final appointment in active) {
        final weekday = appointment.scheduledStart.weekday;
        final startMinutes =
            appointment.scheduledStart.hour * 60 + appointment.scheduledStart.minute;
        final topFactor = ((startMinutes - gridStart) / totalMinutes).clamp(0.0, 1.0);
        final heightFactor =
            (appointment.finalDuration / totalMinutes).clamp(0.0, 1.0);
        blocks.add(
          TimeGridBlock(
            appointmentId: appointment.id,
            weekday: weekday,
            startMinutes: startMinutes,
            durationMinutes: appointment.finalDuration,
            status: appointment.status,
            statusLabel: getAppointmentStatusLabel(appointment),
            clientLabel: clientNames[appointment.clientId] ?? 'Cliente',
            serviceLabel: serviceNames[appointment.serviceId] ?? 'Serviço',
            notes: appointment.notes,
            topFactor: topFactor,
            heightFactor: heightFactor,
          ),
        );
      }
      return blocks;
    });
  }
}
