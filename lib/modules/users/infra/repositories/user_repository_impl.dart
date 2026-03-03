import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remote;

  UserRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> getUser(String uid) {
    return remote.getUser(uid);
  }

  @override
  Future<List<Map<String, dynamic>>> getUsersByIds(
      List<String> ids) async {
    final List<Map<String, dynamic>> users = [];

    for (final id in ids) {
      final user = await remote.getUser(id);
      users.add(user);
    }

    return users;
  }
}