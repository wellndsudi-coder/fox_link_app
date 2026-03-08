import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

/// DTO para exibição de agendamento do cliente com nomes enriquecidos.
class ClientAppointmentDisplay {
  final Appointment appointment;
  final String serviceName;
  final String professionalName;

  const ClientAppointmentDisplay({
    required this.appointment,
    required this.serviceName,
    required this.professionalName,
  });
}
