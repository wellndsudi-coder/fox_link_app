import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/entities/waiting_list_entry.dart';
import 'package:fox_link_app/modules/booking_intelligence/domain/repositories/waiting_list_repository.dart';
import 'package:uuid/uuid.dart';

/// Creates an appointment from a waiting list entry with an offered slot,
/// then cancels the waiting list entry.
class ConfirmWaitingListSlotUseCase {
  final SchedulingRepository schedulingRepo;
  final WaitingListRepository waitingListRepo;
  final ServiceRepository serviceRepo;

  ConfirmWaitingListSlotUseCase({
    required this.schedulingRepo,
    required this.waitingListRepo,
    required this.serviceRepo,
  });

  Future<void> call({
    required WaitingListEntry entry,
    required String tenantId,
  }) async {
    if (entry.offeredSlotStart == null || entry.offeredSlotEnd == null) {
      throw Exception('Horário não ofertado para esta entrada.');
    }
    if (entry.professionalId == null || entry.professionalId!.isEmpty) {
      throw Exception('Profissional não definido.');
    }

    final services = await serviceRepo.getAll(tenantId);
    final service = services.where((s) => s.id == entry.serviceId).firstOrNull;
    if (service == null) {
      throw Exception('Serviço não encontrado.');
    }

    final price = service.basePrice.value;
    final duration = service.baseDuration.minutes;

    final appointment = Appointment(
      id: const Uuid().v4(),
      tenantId: tenantId,
      serviceId: service.id,
      baseServiceId: service.id,
      selectedAddonIds: const [],
      clientId: entry.clientId,
      professionalId: entry.professionalId!,
      scheduledStart: entry.offeredSlotStart!,
      scheduledEnd: entry.offeredSlotEnd!,
      finalPrice: price,
      finalDuration: duration,
      status: AppointmentStatus.approved,
      createdAt: DateTime.now(),
    );

    await schedulingRepo.create(appointment);
    await waitingListRepo.updateStatus(entry.id, WaitingListStatus.cancelled);
  }
}
