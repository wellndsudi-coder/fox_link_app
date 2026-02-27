import '../entities/appointment.dart';
import '../repositories/scheduling_repository.dart';

class RequestRescheduleUseCase {
  final SchedulingRepository repository;

  RequestRescheduleUseCase(this.repository);

  Future<void> call({
    required Appointment appointment,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {

    await repository.requestReschedule(
      appointmentId: appointment.id,
      proposedStart: newStart,
      proposedEnd: newEnd,
    );
  }
}