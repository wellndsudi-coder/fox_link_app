import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../models/appointment_model.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {

  final TenantFirestore firestore;

  SchedulingRepositoryImpl(this.firestore);

  // ==========================================================
  // 🔹 Obter por ID
  // ==========================================================
  @override
  Future<Appointment?> getById(String appointmentId) async {
    final doc = await firestore
        .collection('appointments')
        .doc(appointmentId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return AppointmentModel.fromMap(doc.data()!, doc.id);
  }

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
  // 🔹 Buscar por profissional + data
  // ==========================================================
  @override
  Future<List<Appointment>> getByProfessionalAndDate({
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
        .where('scheduledStart',
        isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledStart',
        isLessThan: endOfDay)
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
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
        .where('status',
        isEqualTo: AppointmentStatus.approved.name)
        .where('scheduledStart',
        isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledStart',
        isLessThan: endOfDay)
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Buscar pendentes
  // ==========================================================
  @override
  Future<List<Appointment>> getPendingByProfessional(
      String professionalId) async {

    final snapshot = await firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('status',
        isEqualTo: AppointmentStatus.pending.name)
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Buscar por tenant e período
  // ==========================================================
  @override
  Future<List<Appointment>> getByTenantAndPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: start)
        .where('scheduledStart', isLessThan: end)
        .orderBy('scheduledStart')
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Buscar por tenant e data
  // ==========================================================
  @override
  Future<List<Appointment>> getByTenantAndDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await firestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledStart', isLessThan: endOfDay)
        .orderBy('scheduledStart')
        .get();

    return snapshot.docs
        .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Buscar por cliente  ✅ (ADICIONADO)
  // ==========================================================
  @override
  Future<List<Appointment>> getByClient(String clientId) async {

    final snapshot = await firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('scheduledStart')
        .get();

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<Appointment>> streamByClient(String clientId) {
    return firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('scheduledStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==========================================================
  // 🔹 Buscar por profissional + status
  // ==========================================================
  @override
  Future<List<Appointment>> getByProfessionalAndStatus({
    required String professionalId,
    required AppointmentStatus status,
  }) async {
    final snapshot = await firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('status', isEqualTo: status.name)
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ==========================================================
  // 🔹 Buscar por profissional e período (OFICIAL)
  // ==========================================================
  @override
  Future<List<Appointment>> getByProfessionalAndPeriod({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) async {

    final snapshot = await firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('scheduledStart',
        isGreaterThanOrEqualTo: start)
        .where('scheduledStart',
        isLessThan: end)
        .orderBy('scheduledStart')
        .get();

    return snapshot.docs
        .map((doc) =>
        AppointmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<Appointment>> streamByProfessionalAndPeriod({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) {
    return firestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('scheduledStart', isGreaterThanOrEqualTo: start)
        .where('scheduledStart', isLessThan: end)
        .orderBy('scheduledStart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ==========================================================
  // 🔹 Compatibilidade DateRange
  // ==========================================================
  @override
  Future<List<Appointment>> getByProfessionalAndDateRange({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) {
    return getByProfessionalAndPeriod(
      professionalId: professionalId,
      start: start,
      end: end,
    );
  }

  // ==========================================================
  // 🔹 Cancelamento
  // ==========================================================
  @override
  Future<void> cancelAppointment({
    required String appointmentId,
  }) async {
    await firestore
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': AppointmentStatus.cancelled.name,
      'cancelledAt': DateTime.now(),
    });
  }

  // ==========================================================
  // 🔹 Solicitar reagendamento
  // ==========================================================
  @override
  Future<void> requestReschedule({
    required String appointmentId,
    required DateTime proposedStart,
    required DateTime proposedEnd,
    String? message,
  }) async {
    final data = <String, dynamic>{
      'status': AppointmentStatus.rescheduleRequested.name,
      'proposedStart': proposedStart,
      'proposedEnd': proposedEnd,
    };
    if (message != null && message.trim().isNotEmpty) {
      data['rescheduleMessage'] = message.trim();
    }
    await firestore.collection('appointments').doc(appointmentId).update(data);
    // Cliente é notificado via Cloud Function quando status muda para rescheduleRequested
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
      'rescheduleMessage': null,
    });
  }

  // ==========================================================
  // 🔹 Atualizar horário (drag/resize)
  // ==========================================================
  @override
  Future<void> updateAppointmentTime({
    required String appointmentId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    final durationMinutes = newEnd.difference(newStart).inMinutes;
    await firestore.collection('appointments').doc(appointmentId).update({
      'scheduledStart': newStart,
      'scheduledEnd': newEnd,
      'finalDuration': durationMinutes,
    });
  }

  // ==========================================================
  // 🔹 Atualizar anotações
  // ==========================================================
  @override
  Future<void> updateAppointmentNotes({
    required String appointmentId,
    String? notes,
  }) async {
    await firestore.collection('appointments').doc(appointmentId).update({
      'notes': notes ?? '',
    });
  }
}