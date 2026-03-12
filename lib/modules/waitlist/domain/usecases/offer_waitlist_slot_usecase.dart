import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/scheduling/domain/entities/appointment.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/create_appointment_usecase.dart';
import 'package:fox_link_app/modules/scheduling/domain/usecases/get_available_slots_usecase.dart';
import 'package:fox_link_app/modules/services/domain/repositories/service_repository.dart';
import 'package:fox_link_app/modules/waitlist/domain/entities/waitlist_entry.dart';
import 'package:fox_link_app/modules/waitlist/domain/repositories/waitlist_repository.dart';
import 'package:uuid/uuid.dart';

class OfferWaitlistSlotUseCase {
  final WaitlistRepository waitlistRepo;
  final GetAvailableSlotsUseCase getSlotsUseCase;
  final CreateAppointmentUseCase createAppointmentUseCase;
  final ServiceRepository serviceRepo;
  final TenantSession tenantSession;

  OfferWaitlistSlotUseCase({
    required this.waitlistRepo,
    required this.getSlotsUseCase,
    required this.createAppointmentUseCase,
    required this.serviceRepo,
    required this.tenantSession,
  });

  Future<List<DateTime>> getAvailableSlots({
    required WaitlistEntry entry,
    required String professionalId,
  }) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) return [];
    final serviceId = entry.serviceId;
    if (serviceId == null || serviceId.isEmpty) return [];

    final services = await serviceRepo.getAll(tenantId);
    final service = services.where((s) => s.id == serviceId).firstOrNull;
    if (service == null) return [];

    return getSlotsUseCase(
      professionalId: professionalId,
      date: entry.desiredDate,
      durationMinutes: service.baseDuration.minutes,
    );
  }

  Future<void> offerSlot({
    required WaitlistEntry entry,
    required String professionalId,
    required DateTime slotStart,
  }) async {
    final tenantId = tenantSession.tenantId;
    if (tenantId == null) throw Exception('Sessão não definida.');

    final clientId = entry.clientId;
    if (clientId == null || clientId.isEmpty) {
      throw Exception('Cliente não vinculado. Não é possível criar agendamento.');
    }

    final serviceId = entry.serviceId;
    if (serviceId == null || serviceId.isEmpty) {
      throw Exception('Serviço não encontrado na lista de espera.');
    }

    final services = await serviceRepo.getAll(tenantId);
    final service = services.where((s) => s.id == serviceId).firstOrNull;
    if (service == null) throw Exception('Serviço não encontrado.');

    final duration = service.baseDuration.minutes;
    final slotEnd = slotStart.add(Duration(minutes: duration));

    final appointment = Appointment(
      id: const Uuid().v4(),
      tenantId: tenantId,
      serviceId: service.id,
      baseServiceId: service.id,
      selectedAddonIds: const [],
      clientId: clientId,
      professionalId: professionalId,
      scheduledStart: slotStart,
      scheduledEnd: slotEnd,
      finalPrice: service.basePrice.value,
      finalDuration: duration,
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      initiatedBy: 'professional',
    );

    await createAppointmentUseCase(appointment);
    await waitlistRepo.updateStatus(entry.id, WaitlistStatus.scheduled);
  }
}
