import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/modules/master/domain/entities/financial_stats_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/platform_log_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/platform_settings_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/platform_stats_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/plan_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/tenant_entity.dart';
import 'package:fox_link_app/modules/master/domain/entities/user_entity.dart';
import 'package:fox_link_app/modules/master/domain/repositories/master_repository.dart';

/// Datasource Firebase para o módulo Master.
class MasterRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _platformSettingsDoc = 'config';

  Future<Map<String, int>> _getProfessionalCountByTenant() async {
    final snap = await _firestore
        .collectionGroup('professionals')
        .get(const GetOptions(source: Source.server));
    final map = <String, int>{};
    for (final d in snap.docs) {
      final path = d.reference.path;
      final parts = path.split('/');
      if (parts.length >= 2) {
        final tenantId = parts[1];
        map[tenantId] = (map[tenantId] ?? 0) + 1;
      }
    }
    return map;
  }

  Future<List<TenantEntity>> getTenants() async {
    final snapshot = await _firestore
        .collection('tenants')
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));

    final profCounts = await _getProfessionalCountByTenant();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      final createdAt = d['createdAt'];
      final trialStart = d['trialStart'];
      final trialEnd = d['trialEnd'];
      final subStart = d['subscriptionStart'];
      final subEnd = d['subscriptionEnd'];
      final blocked = d['blocked'] as bool? ?? false;
      return TenantEntity(
        id: doc.id,
        name: d['name'] as String? ?? 'Sem nome',
        plan: d['plan'] as String? ?? 'basic',
        status: d['status'] as String? ?? 'active',
        createdAt: createdAt is Timestamp
            ? createdAt.toDate()
            : (createdAt as DateTime? ?? DateTime.now()),
        subscriptionStatus: d['subscriptionStatus'] as String? ?? 'trial',
        trialStart: _toDate(trialStart),
        trialEnd: _toDate(trialEnd),
        subscriptionStart: _toDate(subStart),
        subscriptionEnd: _toDate(subEnd),
        blocked: blocked,
        professionalCount: profCounts[doc.id] ?? 0,
      );
    }).toList();
  }

  String _getRole(Map<String, dynamic> d) {
    final roles = d['roles'];
    if (roles is List && roles.isNotEmpty) {
      final r = roles.first;
      if (r is String) return r;
    }
    final r = d['role'];
    return r is String ? r : 'user';
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Future<void> updateTenantPlan({
    required String tenantId,
    required String plan,
  }) async {
    await _firestore.collection('tenants').doc(tenantId).update({'plan': plan});
  }

  Future<void> updateTenantStatus({
    required String tenantId,
    required String status,
  }) async {
    await _firestore.collection('tenants').doc(tenantId).update({'status': status});
  }

  Future<void> blockTenant({required String tenantId}) async {
    await _firestore.collection('tenants').doc(tenantId).update({'blocked': true});
  }

  Future<void> extendTrial({required String tenantId, required int days}) async {
    final doc = await _firestore.collection('tenants').doc(tenantId).get();
    final d = doc.data() ?? {};
    final now = DateTime.now();
    final currentEnd = _toDate(d['trialEnd']) ??
        _toDate(d['planExpireDate']) ??
        _toDate(d['expiresAt']) ??
        now.add(const Duration(days: 30));
    final base = currentEnd.isBefore(now) ? now : currentEnd;
    final newEnd = base.add(Duration(days: days));
    await _firestore.collection('tenants').doc(tenantId).update({
      'trialEnd': Timestamp.fromDate(newEnd),
      'planExpireDate': Timestamp.fromDate(newEnd),
      'expiresAt': Timestamp.fromDate(newEnd),
    });
  }

  Future<List<PlanEntity>> getPlans() async {
    final snapshot = await _firestore
        .collection('plans')
        .get(const GetOptions(source: Source.server));

    if (snapshot.docs.isEmpty) {
      return _defaultPlans();
    }

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return PlanEntity(
        id: doc.id,
        name: d['name'] as String? ?? doc.id,
        price: (d['price'] as num?)?.toDouble() ?? 0,
        maxProfessionals: d['maxProfessionals'] as int? ?? 2,
        maxServices: d['maxServices'] as int? ?? 15,
        maxAddonServices: d['maxAddonServices'] as int? ?? 10,
        maxUsers: d['maxUsers'] as int? ?? 10,
        features: List<String>.from(d['features'] as List? ?? []),
      );
    }).toList();
  }

  Future<void> updatePlan(PlanEntity plan) async {
    await _firestore.collection('plans').doc(plan.id).set(
      {
        'name': plan.name,
        'price': plan.price,
        'maxProfessionals': plan.maxProfessionals,
        'maxServices': plan.maxServices,
        'maxAddonServices': plan.maxAddonServices,
        'maxUsers': plan.maxUsers,
        'features': plan.features,
      },
      SetOptions(merge: true),
    );
  }

  List<PlanEntity> _defaultPlans() {
    return [
      const PlanEntity(
        id: 'basic',
        name: 'Basic',
        price: 29.99,
        maxProfessionals: 1,
        maxServices: 10,
        maxAddonServices: 5,
        maxUsers: 2,
        features: [],
      ),
      const PlanEntity(
        id: 'pro',
        name: 'Pro',
        price: 49.99,
        maxProfessionals: 5,
        maxServices: 50,
        maxAddonServices: 15,
        maxUsers: 10,
        features: [],
      ),
      const PlanEntity(
        id: 'premium',
        name: 'Premium',
        price: 89.99,
        maxProfessionals: 999999,
        maxServices: 999999,
        maxAddonServices: 999999,
        maxUsers: 999999,
        features: [],
      ),
    ];
  }

  Future<MasterMetrics> getMetrics() async {
    final tenantsSnapshot = await _firestore
        .collection('tenants')
        .get(const GetOptions(source: Source.server));

    int activeTenants = 0;
    for (final doc in tenantsSnapshot.docs) {
      if ((doc.data()['status'] ?? 'active') == 'active') {
        activeTenants++;
      }
    }

    final usersSnapshot = await _firestore
        .collection('users')
        .get(const GetOptions(source: Source.server));

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final appointmentsSnapshot = await _firestore
        .collectionGroup('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledStart', isLessThan: endOfDay)
        .get(const GetOptions(source: Source.server));

    int trialActive = 0;
    double monthlyRevenue = 0;
    final plansSnap = await _firestore.collection('plans').get();
    final planPrices = <String, double>{};
    for (final p in plansSnap.docs) {
      final data = p.data();
      planPrices[p.id] = (data['price'] as num?)?.toDouble() ?? 0;
    }
    for (final t in tenantsSnapshot.docs) {
      final d = t.data();
      if ((d['status'] ?? 'active') == 'active' && (d['blocked'] ?? false) != true) {
        final subStatus = d['subscriptionStatus'] as String? ?? 'trial';
        if (subStatus == 'trial') {
          final te = _toDate(d['trialEnd']);
          if (te != null && te.isAfter(DateTime.now())) trialActive++;
        } else {
          monthlyRevenue += planPrices[d['plan'] as String? ?? 'basic'] ?? 0;
        }
      }
    }

    return MasterMetrics(
      totalTenants: tenantsSnapshot.docs.length,
      activeTenants: activeTenants,
      totalUsers: usersSnapshot.docs.length,
      appointmentsToday: appointmentsSnapshot.docs.length,
      monthlyRevenue: monthlyRevenue,
      trialActive: trialActive,
    );
  }

  Future<List<MasterUserEntity>> getUsers() async {
    final usersSnap = await _firestore
        .collection('users')
        .get(const GetOptions(source: Source.server));
    final tenantNames = <String, String>{};
    final tenantsSnap = await _firestore.collection('tenants').get();
    for (final t in tenantsSnap.docs) {
      tenantNames[t.id] = t.data()['name'] as String? ?? t.id;
    }
    return usersSnap.docs.map((doc) {
      final d = doc.data();
      final tenantId = d['tenantId'] as String? ?? d['tenant_id'] as String?;
      return MasterUserEntity(
        id: doc.id,
        name: d['name'] as String? ?? d['displayName'] as String? ?? 'Sem nome',
        email: d['email'] as String? ?? '',
        tenantId: tenantId,
        tenantName: tenantId != null ? (tenantNames[tenantId] ?? '') : '',
        role: _getRole(d),
        status: d['status'] as String? ?? 'active',
      );
    }).toList();
  }

  Future<PlatformStatsEntity> getPlatformStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final appointmentsTodaySnap = await _firestore
        .collectionGroup('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledStart', isLessThan: endOfDay)
        .get(const GetOptions(source: Source.server));

    final appointmentsMonthSnap = await _firestore
        .collectionGroup('appointments')
        .where('scheduledStart', isGreaterThanOrEqualTo: startOfMonth)
        .where('scheduledStart', isLessThan: endOfMonth)
        .get(const GetOptions(source: Source.server));

    final professionalsSnap = await _firestore
        .collectionGroup('professionals')
        .get(const GetOptions(source: Source.server));

    final tenantsSnap = await _firestore.collection('tenants').get();
    int activeTenants = 0;
    for (final t in tenantsSnap.docs) {
      if ((t.data()['status'] ?? 'active') == 'active' && (t.data()['blocked'] ?? false) != true) {
        activeTenants++;
      }
    }

    final serviceIds = <String>[];
    for (final a in appointmentsMonthSnap.docs) {
      final sid = a.data()['serviceId'] as String?;
      if (sid != null) serviceIds.add(sid);
    }
    final topServices = <String, int>{};
    for (final s in serviceIds) {
      topServices[s] = (topServices[s] ?? 0) + 1;
    }
    final sorted = topServices.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMap = Map.fromEntries(sorted.take(10));

    return PlatformStatsEntity(
      appointmentsToday: appointmentsTodaySnap.docs.length,
      appointmentsMonth: appointmentsMonthSnap.docs.length,
      activeProfessionals: professionalsSnap.docs.length,
      topServices: topMap,
      activeTenants: activeTenants,
    );
  }

  Future<FinancialStatsEntity> getFinancialStats() async {
    final tenantsSnap = await _firestore.collection('tenants').get();
    final plansSnap = await _firestore.collection('plans').get();
    final planPrices = <String, double>{};
    for (final p in plansSnap.docs) {
      planPrices[p.id] = (p.data()['price'] as num?)?.toDouble() ?? 0;
    }
    double mrr = 0;
    int paidCount = 0;
    for (final t in tenantsSnap.docs) {
      final d = t.data();
      if ((d['status'] ?? 'active') == 'active' &&
          (d['blocked'] ?? false) != true &&
          (d['subscriptionStatus'] ?? 'trial') != 'trial') {
        final price = planPrices[d['plan'] as String? ?? 'basic'] ?? 0;
        mrr += price;
        paidCount++;
      }
    }
    return FinancialStatsEntity(
      mrr: mrr,
      totalRevenue: mrr,
      cancellations: 0,
      averageTicket: paidCount > 0 ? mrr / paidCount : 0,
    );
  }

  Future<List<PlatformLogEntity>> getLogs({int limit = 100}) async {
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _firestore
          .collection('platform_logs')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
    } catch (_) {
      return [];
    }
    return snap.docs.map((doc) {
      final d = doc.data();
      final createdAt = d['createdAt'];
      return PlatformLogEntity(
        id: doc.id,
        type: d['type'] as String? ?? 'info',
        message: d['message'] as String? ?? '',
        createdAt: createdAt is Timestamp
            ? createdAt.toDate()
            : (createdAt as DateTime? ?? DateTime.now()),
        userId: d['userId'] as String?,
      );
    }).toList();
  }

  Future<PlatformSettingsEntity> getSettings() async {
    final doc = await _firestore
        .collection('platform_config')
        .doc(_platformSettingsDoc)
        .get(const GetOptions(source: Source.server));
    final d = doc.data();
    if (d == null) return const PlatformSettingsEntity();
    return PlatformSettingsEntity(
      platformName: d['platformName'] as String? ?? 'Fox Link',
      supportEmail: d['supportEmail'] as String? ?? '',
      defaultTrialDays: d['defaultTrialDays'] as int? ?? 30,
      defaultPlan: d['defaultPlan'] as String? ?? 'basic',
      platformDomain: d['platformDomain'] as String? ?? '',
    );
  }

  Future<void> saveSettings(PlatformSettingsEntity settings) async {
    await _firestore
        .collection('platform_config')
        .doc(_platformSettingsDoc)
        .set({
      'platformName': settings.platformName,
      'supportEmail': settings.supportEmail,
      'defaultTrialDays': settings.defaultTrialDays,
      'defaultPlan': settings.defaultPlan,
      'platformDomain': settings.platformDomain,
    }, SetOptions(merge: true));
  }
}
