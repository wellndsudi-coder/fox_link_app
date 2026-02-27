import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class AdminMetrics {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayRevenue;
  final double monthRevenue;

  AdminMetrics({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.todayRevenue,
    required this.monthRevenue,
  });
}

class GetAdminMetricsUseCase {
  final TenantFirestore tenantFirestore;

  GetAdminMetricsUseCase(this.tenantFirestore);

  Future<AdminMetrics> call() async {
    final now = DateTime.now();

    final startOfDay =
    DateTime(now.year, now.month, now.day);

    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    final startOfMonth =
    DateTime(now.year, now.month, 1);

    final appointmentsSnapshot =
    await tenantFirestore.collection('appointments').get();

    int todayCount = 0;
    int pendingCount = 0;
    double todayRevenue = 0;
    double monthRevenue = 0;

    for (final doc in appointmentsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final price =
          (data['finalPrice'] as num?)?.toDouble() ?? 0;
      final start =
      (data['scheduledStart'] as Timestamp).toDate();

      if (status == 'pending') {
        pendingCount++;
      }

      if (status == 'approved') {
        if (start.isAfter(startOfDay) &&
            start.isBefore(endOfDay)) {
          todayCount++;
          todayRevenue += price;
        }

        if (start.isAfter(startOfMonth)) {
          monthRevenue += price;
        }
      }
    }

    return AdminMetrics(
      todayAppointments: todayCount,
      pendingAppointments: pendingCount,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
    );
  }
}