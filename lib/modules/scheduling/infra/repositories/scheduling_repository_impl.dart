import 'package:fox_link_app/core/database/tenant_firestore.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../models/appointment_model.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {

  final TenantFirestore firestore;

  SchedulingRepositoryImpl(this.firestore);

  // ==========================================================
  // 🔹 Criar agendamento
  // ==========================================================
  @override
  Future<void> create(Appointment appointment) async {
    final model = AppointmentModel.fromEntity(appointment);

    await firestore
        .collection('appointments')
        .doc(model.id)
        .set(model.toMap());
  }

  // ==========================================================
  // 🔹 Atualizar status
  // ==========================================================
  @override
  Future<void> updateStatus(
      String appointmentId,
      AppointmentStatus status,
      ) async {
    await firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': status.name,
    });
  }

  // ==========================================================
  // 🔹 Buscar aprovados por profissional e data
  // ==========================================================
  @override
  Future<List<Appointment>> getApprovedByProfessionalAndDate({
    required String professionalId,
    required DateTime date,
  }) async {

    final startOfDay =
    DateTime(date.year, date.month, date.day);

    final endOfDay =
    startOfDay.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where(
      'status',
      isEqualTo: AppointmentStatus.approved.name,
    )
        .where(
      'scheduledStart',
      isGreaterThanOrEqualTo: startOfDay,
    )
        .where(
      'scheduledStart',
      isLessThan: endOfDay,
    )
        .get();

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Solicitar reagendamento
  // ==========================================================
  @override
  Future<void> requestReschedule({
    required String appointmentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
  }) async {

    await firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': AppointmentStatus.rescheduleRequested.name,
      'proposedStart': proposedStart,
      'proposedEnd': proposedEnd,
    });
  }

  // ==========================================================
  // 🔹 Confirmar reagendamento
  // ==========================================================
  @override
  Future<void> confirmReschedule({
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {

    await firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'scheduledStart': newStart,
      'scheduledEnd': newEnd,
      'status': AppointmentStatus.approved.name,
      'proposedStart': null,
      'proposedEnd': null,
    });
  }

  // ==========================================================
  // 🔹 Cancelar agendamento
  // ==========================================================
  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': AppointmentStatus.cancelled.name,
    });
  }

  // ==========================================================
  // 🔹 Buscar pendentes do profissional
  // ==========================================================
  @override
  Future<List<Appointment>> getPendingByProfessional(
      String professionalId,
      ) async {

    final snapshot = await firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where(
      'status',
      isEqualTo: AppointmentStatus.pending.name,
    )
        .get();

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}