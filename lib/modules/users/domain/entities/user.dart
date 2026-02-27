class AppUser {
  final String uid;
  final String email;
  final String role;
  final String tenantId;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.tenantId,
  });
}