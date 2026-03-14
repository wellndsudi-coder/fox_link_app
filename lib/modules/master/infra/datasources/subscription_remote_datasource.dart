import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/modules/master/domain/entities/subscription_entity.dart';

/// Datasource Firebase para assinaturas.
class SubscriptionRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SubscriptionEntity>> getSubscriptions() async {
    try {
      final tenantsSnap = await _firestore
          .collection('tenants')
          .get(const GetOptions(source: Source.server));

    final subs = <SubscriptionEntity>[];
    for (final t in tenantsSnap.docs) {
      final d = t.data();
      final plan = d['plan'] as String? ?? 'basic';
      final status = d['subscriptionStatus'] as String? ?? 'trial';
      final trialStart = d['trialStart'];
      final trialEnd = d['trialEnd'];
      final subStart = d['subscriptionStart'];
      final subEnd = d['subscriptionEnd'];
      final planData = await _getPlanPrice(plan);

      subs.add(SubscriptionEntity(
        id: t.id,
        tenantId: t.id,
        tenantName: d['name'] as String? ?? 'Sem nome',
        plan: plan,
        status: status,
        startDate: _toDate(trialStart) ?? _toDate(subStart) ?? (d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now()),
        renewalDate: _toDate(subEnd) ?? _toDate(trialEnd),
        value: planData,
      ));
    }
    return subs;
    } catch (_) {
      return [];
    }
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Future<double> _getPlanPrice(String planId) async {
    final doc = await _firestore.collection('plans').doc(planId).get();
    final d = doc.data();
    return (d?['price'] as num?)?.toDouble() ?? 0;
  }
}
