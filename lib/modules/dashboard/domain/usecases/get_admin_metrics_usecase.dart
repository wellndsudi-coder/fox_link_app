import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class AdminMetrics {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayRevenue;
  final double monthRevenue;

  // 🔥 NOVO CAMPO
  final int totalSlots;

  AdminMetrics({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalSlots, // 🔥 NOVO
  });
}

class GetAdminMetricsUseCase {
  final TenantFirestore tenantFirestore;

  GetAdminMetricsUseCase(this.tenantFirestore);

  Future<AdminMetrics> call() async {
    final now = DateTime.now();

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot =
    await tenantFirestore.collection('appointments').get();

    int todayApprovedCount = 0;
    int todayTotalCount = 0; // 🔥 NOVO
    int pendingCount = 0;
    double todayRevenue = 0;
    double monthRevenue = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final price =
          (data['finalPrice'] as num?)?.toDouble() ?? 0;
      final start =
      (data['scheduledStart'] as Timestamp).toDate();

      if (status == 'pending') {
        pendingCount++;
      }

      // 🔥 Conta todos os agendamentos do dia como slots existentes
      if (start.isAfter(startOfDay) &&
          start.isBefore(endOfDay)) {
        todayTotalCount++;
      }

      if (status == 'approved') {
        if (start.isAfter(startOfDay) &&
            start.isBefore(endOfDay)) {
          todayApprovedCount++;
          todayRevenue += price;
        }

        if (start.isAfter(startOfMonth)) {
          monthRevenue += price;
        }
      }
    }

    return AdminMetrics(
      todayAppointments: todayApprovedCount,
      pendingAppointments: pendingCount,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
      totalSlots: todayTotalCount, // 🔥 NOVO
    );
  }
}