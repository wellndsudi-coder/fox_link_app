import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
  rescheduleRequested,
  noShow,
  waitingList, // agendamento criado a partir da lista de espera
}

class Appointment extends Equatable {
  final String id;
  final String tenantId;
  /// Base service ID. Legacy: same as serviceId when baseServiceId was not stored.
  final String serviceId;
  final String? baseServiceId;
  final List<String> selectedAddonIds;
  final String clientId;
  final String professionalId;

  final DateTime scheduledStart;
  final DateTime scheduledEnd;

  final double finalPrice;
  final int finalDuration;

  /// Alias for finalPrice (total = base + addons).
  double get totalPrice => finalPrice;
  /// Alias for finalDuration (base + addons).
  int get totalDuration => finalDuration;

  final AppointmentStatus status;
  final DateTime createdAt;

  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  /// Mensagem do profissional ao solicitar reagendamento (motivo).
  final String? rescheduleMessage;
  final DateTime? cancelledAt;
  /// Anotações do admin (ex: "Larissa atender Cleid", observações internas).
  final String? notes;
  /// Quem criou o agendamento: 'client' = cliente escolheu o horário; 'professional' = profissional/admin propôs.
  /// Quando null, trata-se como 'client' (compatibilidade com dados antigos).
  final String? initiatedBy;

  const Appointment({
    required this.id,
    required this.tenantId,
    required this.serviceId,
    this.baseServiceId,
    this.selectedAddonIds = const [],
    required this.clientId,
    required this.professionalId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.finalPrice,
    required this.finalDuration,
    required this.status,
    required this.createdAt,
    this.proposedStart,
    this.proposedEnd,
    this.rescheduleMessage,
    this.cancelledAt,
    this.notes,
    this.initiatedBy,
  });

  bool get isPending => status == AppointmentStatus.pending;
  bool get isApproved => status == AppointmentStatus.approved;
  bool get isRescheduleRequested =>
      status == AppointmentStatus.rescheduleRequested;

  Appointment approve({
    required double price,
    required int duration,
  }) {
    return Appointment(
      id: id,
      tenantId: tenantId,
      serviceId: serviceId,
      baseServiceId: baseServiceId,
      selectedAddonIds: selectedAddonIds,
      clientId: clientId,
      professionalId: professionalId,
      scheduledStart: scheduledStart,
      scheduledEnd:
      scheduledStart.add(Duration(minutes: duration)),
      finalPrice: price,
      finalDuration: duration,
      status: AppointmentStatus.approved,
      createdAt: createdAt,
      proposedStart: null,
      proposedEnd: null,
      cancelledAt: cancelledAt,
      notes: notes,
      initiatedBy: initiatedBy,
    );
  }

  Appointment reject() {
    return copyWith(status: AppointmentStatus.rejected);
  }

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? proposedStart,
    DateTime? proposedEnd,
    String? rescheduleMessage,
    DateTime? cancelledAt,
    String? notes,
    String? initiatedBy,
  }) {
    return Appointment(
      id: id,
      tenantId: tenantId,
      serviceId: serviceId,
      baseServiceId: baseServiceId,
      selectedAddonIds: selectedAddonIds,
      clientId: clientId,
      professionalId: professionalId,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      finalPrice: finalPrice,
      finalDuration: finalDuration,
      status: status ?? this.status,
      createdAt: createdAt,
      proposedStart: proposedStart ?? this.proposedStart,
      proposedEnd: proposedEnd ?? this.proposedEnd,
      rescheduleMessage: rescheduleMessage ?? this.rescheduleMessage,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      notes: notes ?? this.notes,
      initiatedBy: initiatedBy ?? this.initiatedBy,
    );
  }

  /// Base service ID (serviceId for legacy, baseServiceId for new).
  String get effectiveBaseServiceId => baseServiceId ?? serviceId;

  @override
  List<Object?> get props => [
    id,
    tenantId,
    serviceId,
    baseServiceId,
    selectedAddonIds,
    clientId,
    professionalId,
    scheduledStart,
    scheduledEnd,
    finalPrice,
    finalDuration,
    status,
    createdAt,
    proposedStart,
    proposedEnd,
    rescheduleMessage,
    cancelledAt,
    notes,
    initiatedBy,
  ];
}