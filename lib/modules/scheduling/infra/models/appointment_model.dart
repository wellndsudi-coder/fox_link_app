import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    required super.id,
    required super.tenantId,
    required super.serviceId,
    required super.clientId,
    required super.professionalId,
    required super.scheduledStart,
    required super.scheduledEnd,
    required super.finalPrice,
    required super.finalDuration,
    required super.status,
    required super.createdAt,
    super.proposedStart,
    super.proposedEnd,
    super.cancelledAt,
  });

  factory AppointmentModel.fromEntity(Appointment appointment) {
    return AppointmentModel(
      id: appointment.id,
      tenantId: appointment.tenantId,
      serviceId: appointment.serviceId,
      clientId: appointment.clientId,
      professionalId: appointment.professionalId,
      scheduledStart: appointment.scheduledStart,
      scheduledEnd: appointment.scheduledEnd,
      finalPrice: appointment.finalPrice,
      finalDuration: appointment.finalDuration,
      status: appointment.status,
      createdAt: appointment.createdAt,
      proposedStart: appointment.proposedStart,
      proposedEnd: appointment.proposedEnd,
      cancelledAt: appointment.cancelledAt,
    );
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? proposedStart;
    if (map['proposedStart'] != null) {
      proposedStart = (map['proposedStart'] as Timestamp).toDate();
    }
    DateTime? proposedEnd;
    if (map['proposedEnd'] != null) {
      proposedEnd = (map['proposedEnd'] as Timestamp).toDate();
    }
    DateTime? cancelledAt;
    if (map['cancelledAt'] != null) {
      cancelledAt = (map['cancelledAt'] as Timestamp).toDate();
    }
    AppointmentStatus status = AppointmentStatus.pending;
    try {
      final statusStr = map['status'] as String?;
      if (statusStr != null) {
        status = AppointmentStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => AppointmentStatus.pending,
        );
      }
    } catch (_) {}

    return AppointmentModel(
      id: id,
      tenantId: map['tenantId'] as String,
      serviceId: map['serviceId'] as String,
      clientId: map['clientId'] as String,
      professionalId: map['professionalId'] as String,
      scheduledStart: (map['scheduledStart'] as Timestamp).toDate(),
      scheduledEnd: (map['scheduledEnd'] as Timestamp).toDate(),
      finalPrice: (map['finalPrice'] as num).toDouble(),
      finalDuration: map['finalDuration'] as int,
      status: status,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      proposedStart: proposedStart,
      proposedEnd: proposedEnd,
      cancelledAt: cancelledAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'tenantId': tenantId,
      'serviceId': serviceId,
      'clientId': clientId,
      'professionalId': professionalId,
      'scheduledStart': scheduledStart,
      'scheduledEnd': scheduledEnd,
      'finalPrice': finalPrice,
      'finalDuration': finalDuration,
      'status': status.name,
      'createdAt': createdAt,
    };
    if (proposedStart != null) map['proposedStart'] = proposedStart;
    if (proposedEnd != null) map['proposedEnd'] = proposedEnd;
    if (cancelledAt != null) map['cancelledAt'] = cancelledAt;
    return map;
  }
}
