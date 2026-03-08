import 'dart:async';

class TenantSession {
  String? _tenantId;
  String? _role;
  List<String> _roles = [];
  String _activeMode = 'admin';
  String? _uid;
  String? _email;
  String? _professionalId;

  final _activeModeController = StreamController<String>.broadcast();

  String? get tenantId => _tenantId;
  String? get role => _role;
  List<String> get roles => List.unmodifiable(_roles);
  String get activeMode => _activeMode;
  String? get uid => _uid;
  String? get email => _email;
  String? get professionalId => _professionalId;

  Stream<String> get activeModeStream => _activeModeController.stream;

  bool get isLogged => _tenantId != null;

  bool hasRole(String r) => _roles.contains(r);

  /// Dono do salão (admin unificado em owner)
  bool get isOwner =>
      _roles.contains('owner') || _roles.contains('admin');

  bool get canSwitchToProfessional =>
      isOwner && _roles.contains('professional');

  void setSession({
    required String tenantId,
    required String role,
    required String uid,
    required String email,
  }) {
    _tenantId = tenantId;
    _role = role == 'admin' ? 'owner' : role;
    _roles = [_role!];
    _uid = uid;
    _email = email;
  }

  void setSessionWithRoles({
    required String tenantId,
    required List<String> roles,
    required String uid,
    required String email,
  }) {
    _tenantId = tenantId;
    _roles = List.from(roles);
    _role = _roles.contains('owner') || _roles.contains('admin')
        ? 'owner'
        : _roles.isNotEmpty
            ? _roles.first
            : null;
    _uid = uid;
    _email = email;
  }

  void setProfessionalId(String professionalId) {
    _professionalId = professionalId;
  }

  void setActiveMode(String mode) {
    if (mode == 'admin' || mode == 'professional' || mode == 'client') {
      _activeMode = mode;
      _activeModeController.add(_activeMode);
    }
  }

  void clear() {
    _tenantId = null;
    _role = null;
    _roles = [];
    _activeMode = 'admin';
    _uid = null;
    _email = null;
    _professionalId = null;
  }
}
