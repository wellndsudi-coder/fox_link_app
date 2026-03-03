class TenantSession {
  String? _tenantId;
  String? _role;
  String? _uid;
  String? _email;

  // 🔥 NOVO: vínculo com documento professional
  String? _professionalId;

  String? get tenantId => _tenantId;
  String? get role => _role;
  String? get uid => _uid;
  String? get email => _email;

  // 🔥 NOVO getter
  String? get professionalId => _professionalId;

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

  // 🔥 NOVO método para definir professional vinculado
  void setProfessionalId(String professionalId) {
    _professionalId = professionalId;
  }

  void clear() {
    _tenantId = null;
    _role = null;
    _uid = null;
    _email = null;
    _professionalId = null; // 🔥 limpa também
  }
}