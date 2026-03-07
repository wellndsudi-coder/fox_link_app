import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class UpdateTenantPlanUseCase {
  final TenantRemoteDataSource _tenantRemote;

  UpdateTenantPlanUseCase(this._tenantRemote);

  Future<void> call({
    required String tenantId,
    required String plan,
  }) async {
    if (!PlanConfig.plans.contains(plan)) {
      throw Exception('Plano inválido: $plan');
    }
    await _tenantRemote.updatePlan(tenantId: tenantId, plan: plan);
  }
}
