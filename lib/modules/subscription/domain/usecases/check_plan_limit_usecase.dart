import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

enum PlanLimitType { professionals, services }

class CheckPlanLimitUseCase {
  final TenantRemoteDataSource _tenantRemote;

  CheckPlanLimitUseCase(this._tenantRemote);

  Future<void> assertCanAdd({
    required String tenantId,
    required PlanLimitType limitType,
    required int currentCount,
  }) async {
    final snapshot = await _tenantRemote.getTenant(tenantId);
    final data = snapshot.data();
    final plan = data?['plan'] as String? ?? PlanConfig.trial;

    final max = limitType == PlanLimitType.professionals
        ? PlanConfig.maxProfessionals(plan)
        : PlanConfig.maxServices(plan);

    if (currentCount >= max) {
      if (limitType == PlanLimitType.professionals) {
        throw Exception(
            'Seu plano não permite adicionar mais profissionais.',
        );
      } else {
        throw Exception(
            'Seu plano não permite adicionar mais serviços.',
        );
      }
    }
  }
}
