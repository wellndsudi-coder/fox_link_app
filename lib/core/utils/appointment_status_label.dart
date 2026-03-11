import 'package:fox_link_app/core/utils/date_formatter.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';

/// Retorna o rótulo amigável do status do agendamento para exibição.
String getAppointmentStatusLabel(Appointment appointment) {
  switch (appointment.status) {
    case AppointmentStatus.pending:
      return 'Aguardando confirmação';
    case AppointmentStatus.approved:
      return 'Agendado';
    case AppointmentStatus.rescheduleRequested:
      final from = AppDateFormatter.friendlyTime(appointment.scheduledStart);
      final to = appointment.proposedStart != null
          ? AppDateFormatter.friendlyTime(appointment.proposedStart!)
          : '?';
      return 'Alterado de $from para $to';
    case AppointmentStatus.completed:
      return 'Concluído';
    case AppointmentStatus.cancelled:
      return 'Cancelado';
    case AppointmentStatus.rejected:
      return 'Rejeitado';
    case AppointmentStatus.noShow:
      return 'Não compareceu';
    case AppointmentStatus.waitingList:
      return 'Lista de espera';
  }
}
