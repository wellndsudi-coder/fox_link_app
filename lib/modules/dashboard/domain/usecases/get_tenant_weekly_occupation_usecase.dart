import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

class DayOccupation {
  final DateTime date;
  final int bookedMinutes;
  final double occupancyPercent;

  const DayOccupation({
    required this.date,
    required this.bookedMinutes,
    required this.occupancyPercent,
  });
}

/// Tenant-wide weekly occupancy: booked minutes per day vs 8h capacity.
class GetTenantWeeklyOccupationUseCase {
  final TenantFirestore tenantFirestore;

  static const int _capacityMinutesPerDay = 8 * 60; // 8 hours

  GetTenantWeeklyOccupationUseCase(this.tenantFirestore);

  Future<List<DayOccupation>> call() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfFirstDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfLastDay =
        startOfFirstDay.add(const Duration(days: 6, hours: 23, minutes: 59));

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('scheduledStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfFirstDay))
        .where('scheduledStart',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfLastDay))
        .get();

    final minutesByDay = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      minutesByDay[_key(d)] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      if (status == 'cancelled' || status == 'rejected') continue;

      final duration = data['finalDuration'] as int? ?? 0;
      final start = (data['scheduledStart'] as Timestamp).toDate();
      final key = _key(DateTime(start.year, start.month, start.day));
      minutesByDay[key] = (minutesByDay[key] ?? 0) + duration;
    }

    final result = <DayOccupation>[];
    for (var i = 0; i < 7; i++) {
      final d = startOfFirstDay.add(Duration(days: i));
      final mins = minutesByDay[_key(d)] ?? 0;
      final pct =
          ((mins / _capacityMinutesPerDay) * 100).clamp(0.0, 100.0).toDouble();
      result.add(DayOccupation(
        date: d,
        bookedMinutes: mins,
        occupancyPercent: pct,
      ));
    }
    return result;
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
