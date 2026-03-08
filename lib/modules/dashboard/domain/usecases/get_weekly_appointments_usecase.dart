import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class DailyAppointmentCount {
  final DateTime date;
  final int count;

  const DailyAppointmentCount({
    required this.date,
    required this.count,
  });
}

class GetWeeklyAppointmentsUseCase {
  final TenantFirestore tenantFirestore;

  GetWeeklyAppointmentsUseCase(this.tenantFirestore);

  Future<List<DailyAppointmentCount>> call() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 6));
    final startOfFirstDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfLastDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('scheduledStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfFirstDay))
        .where('scheduledStart',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfLastDay))
        .get();

    final countByDay = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      countByDay[_key(d)] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      if (status == 'cancelled' || status == 'rejected') continue;

      final start = (data['scheduledStart'] as Timestamp).toDate();
      final key = _key(DateTime(start.year, start.month, start.day));
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }

    final result = <DailyAppointmentCount>[];
    for (var i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      result.add(DailyAppointmentCount(
        date: d,
        count: countByDay[_key(d)] ?? 0,
      ));
    }
    return result;
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
