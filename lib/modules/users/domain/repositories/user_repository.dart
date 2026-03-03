abstract class UserRepository {
  Future<Map<String, dynamic>> getUser(String uid);

  Future<List<Map<String, dynamic>>> getUsersByIds(
      List<String> ids);
}