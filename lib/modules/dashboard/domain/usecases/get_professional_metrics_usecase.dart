import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

class ProfessionalMetrics {
  final int todayAppointments;
  final double todayRevenue;
  final double monthRevenue;
  final int totalSlots;
  final int monthAppointmentCount;
  final DateTime? nextAppointment;

  ProfessionalMetrics({
    required this.todayAppointments,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalSlots,
    this.monthAppointmentCount = 0,
    required this.nextAppointment,
  });
}

class GetProfessionalMetricsUseCase {
  final TenantFirestore tenantFirestore;
  final TenantSession session;

  GetProfessionalMetricsUseCase(
      this.tenantFirestore,
      this.session,
      );

  Future<ProfessionalMetrics> call() async {
    final now = DateTime.now();

    final startOfDay =
    DateTime(now.year, now.month, now.day);
    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfMonth =
    DateTime(now.year, now.month, 1);

    final professionalId = session.professionalId;
    if (professionalId == null) {
      return ProfessionalMetrics(
        todayAppointments: 0,
        todayRevenue: 0,
        monthRevenue: 0,
        totalSlots: 0,
        monthAppointmentCount: 0,
        nextAppointment: null,
      );
    }

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .get();

    int todayApproved = 0;
    int todayTotal = 0;
    int monthCount = 0;
    double todayRevenue = 0;
    double monthRevenue = 0;
    DateTime? next;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final price =
          (data['finalPrice'] as num?)?.toDouble() ?? 0;
      final start =
      (data['scheduledStart'] as Timestamp).toDate();

      if (start.isAfter(startOfDay) &&
          start.isBefore(endOfDay)) {
        todayTotal++;
      }

      if (status == 'completed') {
        if (start.isAfter(startOfDay) &&
            start.isBefore(endOfDay)) {
          todayApproved++;
          todayRevenue += price;
        }

        if (start.isAfter(startOfMonth)) {
          monthRevenue += price;
        }
      }
      if (start.isAfter(startOfMonth) && start.isBefore(DateTime(now.year, now.month + 1, 1))) {
        if (status != 'cancelled' && status != 'rejected') {
          monthCount++;
        }
      }

      if (status == 'approved' && start.isAfter(now)) {
        if (next == null || start.isBefore(next)) {
          next = start;
        }
      }
    }

    return ProfessionalMetrics(
      todayAppointments: todayApproved,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
      totalSlots: todayTotal,
      monthAppointmentCount: monthCount,
      nextAppointment: next,
    );
  }
}