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
  });

  factory AppointmentModel.fromEntity(
      Appointment appointment) {
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
    );
  }

  factory AppointmentModel.fromMap(
      Map<String, dynamic> map,
      String id,
      ) {
    return AppointmentModel(
      id: id,
      tenantId: map['tenantId'],
      serviceId: map['serviceId'],
      clientId: map['clientId'],
      professionalId: map['professionalId'],
      scheduledStart:
      (map['scheduledStart'] as Timestamp).toDate(),
      scheduledEnd:
      (map['scheduledEnd'] as Timestamp).toDate(),
      finalPrice: map['finalPrice'],
      finalDuration: map['finalDuration'],
      status:
      AppointmentStatus.values.firstWhere(
            (e) => e.name == map['status'],
      ),
      createdAt:
      (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }
}