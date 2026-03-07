import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed,
  rescheduleRequested,
  noShow,
}

class Appointment extends Equatable {
  final String id;
  final String tenantId;
  final String serviceId;
  final String clientId;
  final String professionalId;

  final DateTime scheduledStart;
  final DateTime scheduledEnd;

  final double finalPrice;
  final int finalDuration;

  final AppointmentStatus status;
  final DateTime createdAt;

  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  final DateTime? cancelledAt;

  const Appointment({
    required this.id,
    required this.tenantId,
    required this.serviceId,
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
    this.cancelledAt,
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
    );
  }

  Appointment reject() {
    return copyWith(status: AppointmentStatus.rejected);
  }

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? proposedStart,
    DateTime? proposedEnd,
    DateTime? cancelledAt,
  }) {
    return Appointment(
      id: id,
      tenantId: tenantId,
      serviceId: serviceId,
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
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    serviceId,
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
    cancelledAt,
  ];
}