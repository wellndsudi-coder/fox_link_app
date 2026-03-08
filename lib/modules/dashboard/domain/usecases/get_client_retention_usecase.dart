import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

/// Returns count of clients with 2+ completed appointments in the last [daysBack] days.
class GetClientRetentionUseCase {
  final TenantFirestore tenantFirestore;

  GetClientRetentionUseCase(this.tenantFirestore);

  Future<int> call({int daysBack = 30}) async {
    final start = DateTime.now().subtract(Duration(days: daysBack));

    final snapshot = await tenantFirestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final clientCounts = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] != 'completed') continue;
      final clientId = data['clientId'] as String? ?? '';
      if (clientId.isEmpty) continue;
      clientCounts[clientId] = (clientCounts[clientId] ?? 0) + 1;
    }

    return clientCounts.values.where((c) => c >= 2).length;
  }
}
