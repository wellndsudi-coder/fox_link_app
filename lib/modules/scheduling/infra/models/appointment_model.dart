import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  AppointmentModel({
    required super.id,
    required super.tenantId,
    required super.serviceId,
    super.baseServiceId,
    super.selectedAddonIds = const [],
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
    super.rescheduleMessage,
    super.cancelledAt,
  });

  factory AppointmentModel.fromEntity(Appointment appointment) {
    return AppointmentModel(
      id: appointment.id,
      tenantId: appointment.tenantId,
      serviceId: appointment.serviceId,
      baseServiceId: appointment.baseServiceId,
      selectedAddonIds: appointment.selectedAddonIds,
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
      rescheduleMessage: appointment.rescheduleMessage,
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
    final rescheduleMessage = map['rescheduleMessage'] as String?;
    AppointmentStatus status = AppointmentStatus.pending;
    try {
      final statusStr = map['status'] as String?;
      if (statusStr != null) {
        if (statusStr == 'confirmed') {
          status = AppointmentStatus.approved;
        } else {
          status = AppointmentStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => AppointmentStatus.pending,
          );
        }
      }
    } catch (_) {}

    final serviceId = map['serviceId'] as String? ?? map['baseServiceId'] as String? ?? '';
    final baseServiceId = map['baseServiceId'] as String? ?? serviceId;
    final selectedAddonIdsRaw = map['selectedAddonIds'];
    final selectedAddonIds = selectedAddonIdsRaw is List
        ? (selectedAddonIdsRaw).map((e) => e.toString()).toList()
        : <String>[];
    return AppointmentModel(
      id: id,
      tenantId: map['tenantId'] as String,
      serviceId: serviceId,
      baseServiceId: baseServiceId,
      selectedAddonIds: selectedAddonIds,
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
      rescheduleMessage: rescheduleMessage,
      cancelledAt: cancelledAt,
    );
  }

  Map<String, dynamic> toMap() {
    final baseId = baseServiceId ?? serviceId;
    final map = <String, dynamic>{
      'tenantId': tenantId,
      'serviceId': serviceId,
      'baseServiceId': baseId,
      'selectedAddonIds': selectedAddonIds,
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
    if (rescheduleMessage?.isNotEmpty == true) map['rescheduleMessage'] = rescheduleMessage!;
    if (cancelledAt != null) map['cancelledAt'] = cancelledAt;
    return map;
  }
}
