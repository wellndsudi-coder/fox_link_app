import '../entities/plan_entity.dart';
import '../repositories/master_repository.dart';

class UpdatePlanUseCase {
  final MasterRepository repository;

  UpdatePlanUseCase(this.repository);

  Future<void> call(PlanEntity plan) =>
      repository.updatePlan(plan);
}
