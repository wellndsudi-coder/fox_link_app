import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class ProfessionalMetrics {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayRevenue;
  final double monthRevenue;

  ProfessionalMetrics({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.todayRevenue,
    required this.monthRevenue,
  });
}

class GetProfessionalMetricsUseCase {
  final TenantFirestore tenantFirestore;

  GetProfessionalMetricsUseCase(this.tenantFirestore);

  Future<ProfessionalMetrics> call(String professionalId) async {
    final now = DateTime.now();

    final startOfDay =
    DateTime(now.year, now.month, now.day);

    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59);

    final startOfMonth =
    DateTime(now.year, now.month, 1);

    // ===============================
    // PENDENTES
    // ===============================

    final pendingSnapshot =
    await tenantFirestore.collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('status', isEqualTo: 'pending')
        .get();

    // ===============================
    // APROVADOS HOJE
    // ===============================

    final todayApprovedSnapshot =
    await tenantFirestore.collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('status', isEqualTo: 'approved')
        .where('scheduledStart',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledStart',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // ===============================
    // APROVADOS MÊS
    // ===============================

    final monthApprovedSnapshot =
    await tenantFirestore.collection('appointments')
        .where('professionalId', isEqualTo: professionalId)
        .where('status', isEqualTo: 'approved')
        .where('scheduledStart',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    // ===============================
    // CALCULOS
    // ===============================

    int todayCount = todayApprovedSnapshot.docs.length;
    int pendingCount = pendingSnapshot.docs.length;

    double todayRevenue = 0;
    for (final doc in todayApprovedSnapshot.docs) {
      final price =
          (doc.data()['finalPrice'] as num?)?.toDouble() ?? 0;
      todayRevenue += price;
    }

    double monthRevenue = 0;
    for (final doc in monthApprovedSnapshot.docs) {
      final price =
          (doc.data()['finalPrice'] as num?)?.toDouble() ?? 0;
      monthRevenue += price;
    }

    return ProfessionalMetrics(
      todayAppointments: todayCount,
      pendingAppointments: pendingCount,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
    );
  }
}