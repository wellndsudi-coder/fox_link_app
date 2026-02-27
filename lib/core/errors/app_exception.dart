class InviteNotFoundException implements Exception {}

class InviteAlreadyExistsException implements Exception {}

class TenantSuspendedException implements Exception {}

class TrialExpiredException implements Exception {}

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;

}