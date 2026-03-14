import '../repositories/master_repository.dart';

/// Use case Master para verificar limites do plano.
/// Diferente do CheckPlanLimitUseCase do módulo subscription (tenant-scoped).
enum MasterPlanLimitType { professionals, services, users }

class MasterCheckPlanLimitUseCase {
  final MasterRepository repository;

  MasterCheckPlanLimitUseCase(this.repository);

  /// Retorna o limite do plano para o tipo especificado.
  /// -1 indica ilimitado.
  Future<int> getLimit(String planId, MasterPlanLimitType type) async {
    final plans = await repository.getPlans();
    final plan = plans.where((p) => p.id == planId).firstOrNull;
    if (plan == null) return 2;

    return switch (type) {
      MasterPlanLimitType.professionals => plan.maxProfessionals >= 999999 ? -1 : plan.maxProfessionals,
      MasterPlanLimitType.services => plan.maxServices >= 999999 ? -1 : plan.maxServices,
      MasterPlanLimitType.users => plan.maxUsers >= 999999 ? -1 : plan.maxUsers,
    };
  }
}
