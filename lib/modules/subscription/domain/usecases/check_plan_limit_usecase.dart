import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/subscription/infra/datasources/plan_limits_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

enum PlanLimitType { professionals, services, addonServices }

class CheckPlanLimitUseCase {
  final TenantRemoteDataSource _tenantRemote;
  final PlanLimitsRemoteDataSource _planLimitsRemote;

  CheckPlanLimitUseCase(
    this._tenantRemote, {
    PlanLimitsRemoteDataSource? planLimitsRemote,
  }) : _planLimitsRemote = planLimitsRemote ?? PlanLimitsRemoteDataSource();

  Future<void> assertCanAdd({
    required String tenantId,
    required PlanLimitType limitType,
    required int currentCount,
  }) async {
    final snapshot = await _tenantRemote.getTenant(tenantId);
    final data = snapshot.data();
    final plan = data?['plan'] as String? ?? PlanConfig.trial;

    int max;
    final limits = await _planLimitsRemote.getPlanLimits(plan);
    if (limits != null) {
      max = switch (limitType) {
        PlanLimitType.professionals => limits.maxProfessionals,
        PlanLimitType.services => limits.maxServices,
        PlanLimitType.addonServices => limits.maxAddonServices,
      };
    } else {
      max = switch (limitType) {
        PlanLimitType.professionals => PlanConfig.maxProfessionals(plan),
        PlanLimitType.services => PlanConfig.maxServices(plan),
        PlanLimitType.addonServices => PlanConfig.maxAddonServices(plan),
      };
    }

    if (currentCount >= max) {
      switch (limitType) {
        case PlanLimitType.professionals:
          throw Exception(
            'Seu plano não permite adicionar mais profissionais.',
          );
        case PlanLimitType.services:
          throw Exception(
            'Seu plano não permite adicionar mais serviços.',
          );
        case PlanLimitType.addonServices:
          throw Exception(
            'Seu plano não permite adicionar mais serviços adicionais.',
          );
      }
    }
  }
}
