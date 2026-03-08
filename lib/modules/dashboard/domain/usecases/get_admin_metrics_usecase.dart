import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class AdminMetrics {
  final int todayAppointments;
  final int pendingAppointments;
  final double todayRevenue;
  final double monthRevenue;

  /// Total de agendamentos do dia (todos os status)
  final int totalSlots;

  /// Clientes únicos atendidos hoje (aprovados)
  final int clientsServed;

  /// Serviços realizados hoje (aprovados)
  final int servicesCompleted;

  /// Tendência do faturamento vs ontem (ex: '+12%' ou null)
  final String? revenueTrend;

  AdminMetrics({
    required this.todayAppointments,
    required this.pendingAppointments,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.totalSlots,
    this.clientsServed = 0,
    this.servicesCompleted = 0,
    this.revenueTrend,
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

    final yesterdayStart =
        DateTime(now.year, now.month, now.day - 1);
    final yesterdayEnd =
        DateTime(now.year, now.month, now.day - 1, 23, 59, 59);

    final snapshot =
        await tenantFirestore.collection('appointments').get();

    int todayApprovedCount = 0;
    int todayTotalCount = 0;
    int pendingCount = 0;
    double todayRevenue = 0;
    double monthRevenue = 0;
    double yesterdayRevenue = 0;
    final todayClientIds = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final price = (data['finalPrice'] as num?)?.toDouble() ?? 0;
      final clientId = data['clientId'] as String? ?? '';
      final start = (data['scheduledStart'] as Timestamp).toDate();

      if (status == 'pending') {
        pendingCount++;
      }

      if (start.isAfter(startOfDay) && start.isBefore(endOfDay)) {
        todayTotalCount++;
      }

      if (status == 'completed') {
        if (start.isAfter(startOfDay) && start.isBefore(endOfDay)) {
          todayApprovedCount++;
          todayRevenue += price;
          if (clientId.isNotEmpty) todayClientIds.add(clientId);
        }
        if (start.isAfter(yesterdayStart) &&
            start.isBefore(yesterdayEnd)) {
          yesterdayRevenue += price;
        }
        if (start.isAfter(startOfMonth)) {
          monthRevenue += price;
        }
      }
    }

    String? revenueTrend;
    if (yesterdayRevenue > 0) {
      final pct = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      revenueTrend = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}% vs ontem';
    }

    return AdminMetrics(
      todayAppointments: todayApprovedCount,
      pendingAppointments: pendingCount,
      todayRevenue: todayRevenue,
      monthRevenue: monthRevenue,
      totalSlots: todayTotalCount,
      clientsServed: todayClientIds.length,
      servicesCompleted: todayApprovedCount,
      revenueTrend: revenueTrend,
    );
  }
}