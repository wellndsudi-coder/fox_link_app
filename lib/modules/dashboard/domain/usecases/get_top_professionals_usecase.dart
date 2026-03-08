import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';

class TopProfessionalItem {
  final String professionalId;
  final String name;
  final double revenue;

  const TopProfessionalItem({
    required this.professionalId,
    required this.name,
    required this.revenue,
  });
}

class GetTopProfessionalsUseCase {
  final TenantFirestore _firestore;
  final TenantSession _session;

  GetTopProfessionalsUseCase(this._firestore, this._session);

  Future<List<TopProfessionalItem>> call({
    int limit = 5,
    int? daysBack,
  }) async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return [];

    final now = DateTime.now();
    final start = daysBack != null
        ? now.subtract(Duration(days: daysBack))
        : DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final revenueByProf = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['status'] as String?) != 'completed') continue;
      final profId = data['professionalId'] as String? ?? '';
      if (profId.isEmpty) continue;
      final price = (data['finalPrice'] as num?)?.toDouble() ?? 0;
      revenueByProf[profId] = (revenueByProf[profId] ?? 0) + price;
    }

    if (revenueByProf.isEmpty) return [];

    final profIds = revenueByProf.keys.toList();
    final profDocs = await Future.wait(
      profIds.map((id) => _firestore.collection('professionals').doc(id).get()),
    );

    final nameById = <String, String>{};
    for (var i = 0; i < profIds.length; i++) {
      final d = profDocs[i].data();
      nameById[profIds[i]] = d?['name'] as String? ?? 'Profissional';
    }

    return revenueByProf.entries
        .map((e) => TopProfessionalItem(
              professionalId: e.key,
              name: nameById[e.key] ?? 'Profissional',
              revenue: e.value,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }
}
