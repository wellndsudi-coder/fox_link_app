import '../repositories/scheduling_repository.dart';

class CancelAppointmentUseCase {

  final SchedulingRepository repository;

  CancelAppointmentUseCase(this.repository);

  Future<void> execute({
    required String appointmentId,
    required String role,
    required DateTime scheduledStart,
  }) async {

    // ❌ Não pode cancelar se já passou
    if (DateTime.now().isAfter(scheduledStart)) {
      throw Exception("Não é possível cancelar após o horário.");
    }

    // 🔒 Cliente só pode cancelar até 2h antes (exemplo comercial)
    if (role == 'client') {
      final difference =
      scheduledStart.difference(DateTime.now());

      if (difference.inHours < 2) {
        throw Exception(
          "Cancelamento permitido apenas até 2h antes.",
        );
      }
    }

    await repository.cancelAppointment(appointmentId);
  }
}