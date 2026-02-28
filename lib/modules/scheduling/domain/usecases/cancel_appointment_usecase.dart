import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class CancelAppointmentUseCase {

  final SchedulingRepository repository;

  CancelAppointmentUseCase(this.repository);

  Future<void> execute({
    required Appointment appointment,
    required String role,
  }) async {

    // 🔥 1️⃣ Não permitir cancelar completed
    if (appointment.status == AppointmentStatus.completed) {
      throw Exception("Não é possível cancelar agendamento concluído.");
    }

    // 🔥 2️⃣ Não permitir cancelar se já passou
    if (DateTime.now().isAfter(appointment.scheduledStart)) {
      throw Exception("Não é possível cancelar após o horário.");
    }

    // 🔥 3️⃣ Regra comercial para cliente
    if (role == 'client') {
      final difference =
      appointment.scheduledStart.difference(DateTime.now());

      if (difference.inHours < 2) {
        throw Exception(
          "Cancelamento permitido apenas até 2h antes.",
        );
      }
    }

    await repository.cancelAppointment(
      appointmentId: appointment.id,
    );
  }
}