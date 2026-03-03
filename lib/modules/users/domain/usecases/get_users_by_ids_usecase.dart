import '../repositories/user_repository.dart';

class GetUsersByIdsUseCase {
  final UserRepository repository;

  GetUsersByIdsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(
      List<String> ids) {
    return repository.getUsersByIds(ids);
  }
}