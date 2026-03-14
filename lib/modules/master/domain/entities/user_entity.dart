import 'package:equatable/equatable.dart';

/// Entidade de usuário para o painel Master.
class MasterUserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? tenantId;
  final String tenantName;
  final String role;
  final String status;

  const MasterUserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.tenantId,
    this.tenantName = '',
    this.role = 'user',
    this.status = 'active',
  });

  @override
  List<Object?> get props => [id, name, email, tenantId, tenantName, role, status];
}
