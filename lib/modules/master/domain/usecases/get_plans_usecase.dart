import '../entities/plan_entity.dart';
import '../repositories/master_repository.dart';

class GetPlansUseCase {
  final MasterRepository repository;

  GetPlansUseCase(this.repository);

  Future<List<PlanEntity>> call() => repository.getPlans();
}
