class TenantSession {
  String? _tenantId;
  String? _role;
  String? _uid;
  String? _email;

  String? get tenantId => _tenantId;
  String? get role => _role;
  String? get uid => _uid;
  String? get email => _email;

  bool get isLogged => _tenantId != null;

  void setSession({
    required String tenantId,
    required String role,
    required String uid,
    required String email,
  }) {
    _tenantId = tenantId;
    _role = role;
    _uid = uid;
    _email = email;
  }

  void clear() {
    _tenantId = null;
    _role = null;
    _uid = null;
    _email = null;
  }
}