import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class DailyRevenue {
  final DateTime date;
  final double revenue;

  const DailyRevenue({
    required this.date,
    required this.revenue,
  });
}

class GetWeeklyRevenueUseCase {
  final TenantFirestore tenantFirestore;

  GetWeeklyRevenueUseCase(this.tenantFirestore);

  Future<List<DailyRevenue>> call() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 6));
    final startOfFirstDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfLastDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfFirstDay))
        .where('scheduledStart', isLessThanOrEqualTo: Timestamp.fromDate(endOfLastDay))
        .get();

    final revenueByDay = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      revenueByDay[_key(d)] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      if (status != 'approved' && status != 'completed') continue;

      final price = (data['finalPrice'] as num?)?.toDouble() ?? 0;
      final start = (data['scheduledStart'] as Timestamp).toDate();
      final key = _key(DateTime(start.year, start.month, start.day));
      revenueByDay[key] = (revenueByDay[key] ?? 0) + price;
    }

    final result = <DailyRevenue>[];
    for (int i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      result.add(DailyRevenue(
        date: d,
        revenue: revenueByDay[_key(d)] ?? 0,
      ));
    }
    return result;
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
