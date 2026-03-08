import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

/// Marca um agendamento aprovado como concluído (serviço realizado).
class CompleteAppointmentUseCase {
  final SchedulingRepository _repository;

  CompleteAppointmentUseCase(this._repository);

  Future<void> call(Appointment appointment) async {
    if (appointment.status != AppointmentStatus.approved) {
      throw Exception('Apenas agendamentos aprovados podem ser concluídos.');
    }

    await _repository.updateStatus(appointment.id, AppointmentStatus.completed);
  }
}
