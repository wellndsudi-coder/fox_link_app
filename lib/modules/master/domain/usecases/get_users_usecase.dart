import '../entities/user_entity.dart';
import '../repositories/master_repository.dart';

class GetMasterUsersUseCase {
  final MasterRepository repository;

  GetMasterUsersUseCase(this.repository);

  Future<List<MasterUserEntity>> call() => repository.getUsers();
}
