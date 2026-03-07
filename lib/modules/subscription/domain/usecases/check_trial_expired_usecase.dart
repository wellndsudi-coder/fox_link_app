import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class CheckTrialExpiredUseCase {
  final TenantRemoteDataSource _tenantRemote;

  CheckTrialExpiredUseCase(this._tenantRemote);

  Future<bool> call(String tenantId) async {
    final snapshot = await _tenantRemote.getTenant(tenantId);
    final data = snapshot.data();
    if (data == null) return false;

    final plan = data['plan'] as String? ?? PlanConfig.trial;
    if (plan != PlanConfig.trial) return false;

    final expireDate = data['planExpireDate'] ?? data['expiresAt'];
    if (expireDate == null) return false;

    final DateTime date;
    if (expireDate is Timestamp) {
      date = expireDate.toDate();
    } else if (expireDate is DateTime) {
      date = expireDate;
    } else {
      return false;
    }

    return DateTime.now().isAfter(date);
  }
}
