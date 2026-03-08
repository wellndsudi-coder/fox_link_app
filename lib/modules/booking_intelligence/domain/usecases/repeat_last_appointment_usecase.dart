import '../../../scheduling/domain/entities/appointment.dart';
import '../../../scheduling/domain/repositories/scheduling_repository.dart';

import '../entities/first_available_slot.dart';
import 'get_first_available_slot_usecase.dart';

class RepeatLastAppointmentResult {
  final Appointment? lastAppointment;
  final FirstAvailableSlot? firstAvailableSlot;

  const RepeatLastAppointmentResult({
    this.lastAppointment,
    this.firstAvailableSlot,
  });
}

class RepeatLastAppointmentUseCase {
  final SchedulingRepository schedulingRepository;
  final GetFirstAvailableSlotUseCase getFirstAvailableSlotUseCase;

  RepeatLastAppointmentUseCase({
    required this.schedulingRepository,
    required this.getFirstAvailableSlotUseCase,
  });

  Future<RepeatLastAppointmentResult> call(String clientId) async {
    final all = await schedulingRepository.getByClient(clientId);
    final completedOrApproved = all.where((a) =>
        a.status == AppointmentStatus.completed ||
        a.status == AppointmentStatus.approved).toList();
    completedOrApproved.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    final last = completedOrApproved.isNotEmpty ? completedOrApproved.first : null;
    if (last == null) return const RepeatLastAppointmentResult();

    final firstSlot = await getFirstAvailableSlotUseCase(
      serviceId: last.serviceId,
      clientId: clientId,
    );

    return RepeatLastAppointmentResult(
      lastAppointment: last,
      firstAvailableSlot: firstSlot,
    );
  }
}
