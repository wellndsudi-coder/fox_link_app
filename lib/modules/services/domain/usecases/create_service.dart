import '../entities/service.dart';
import '../repositories/service_repository.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_plan_limit_usecase.dart';
import 'package:fox_link_app/modules/subscription/domain/usecases/check_trial_expired_usecase.dart';

import 'get_services.dart';

class CreateService {
  final ServiceRepository repository;
  final CheckPlanLimitUseCase checkPlanLimit;
  final CheckTrialExpiredUseCase checkTrialExpired;
  final GetServices getServices;

  CreateService(
    this.repository, {
    required this.checkPlanLimit,
    required this.checkTrialExpired,
    required this.getServices,
  });

  Future<void> call(Service service) async {
    final tenantId = service.tenantId;

    final expired = await checkTrialExpired(tenantId);
    if (expired) {
      throw Exception(
          'Seu período de teste expirou. Escolha um plano para continuar.',
      );
    }

    final services = await getServices(tenantId);
    await checkPlanLimit.assertCanAdd(
      tenantId: tenantId,
      limitType: PlanLimitType.services,
      currentCount: services.length,
    );

    return repository.create(service);
  }
}
