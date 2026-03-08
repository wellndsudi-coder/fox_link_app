import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

/// Returns tenant-wide occupancy: total booked minutes / total capacity (estimated).
/// Capacity = sum of appointment durations if we had 100% utilization; we use a simple heuristic.
class GetOccupancyRateUseCase {
  final TenantFirestore tenantFirestore;

  GetOccupancyRateUseCase(this.tenantFirestore);

  Future<double> call({int daysBack = 30}) async {
    final start = DateTime.now().subtract(Duration(days: daysBack));

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    int bookedMinutes = 0;
    int totalAppointments = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      if (status == 'cancelled' || status == 'rejected') continue;
      final duration = data['finalDuration'] as int? ?? 0;
      bookedMinutes += duration;
      totalAppointments++;
    }

    if (totalAppointments == 0) return 0.0;
    final estimatedCapacity = daysBack * 8 * 60;
    if (estimatedCapacity <= 0) return 0.0;
    return (bookedMinutes / estimatedCapacity * 100).clamp(0.0, 100.0);
  }
}
