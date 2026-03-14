import 'package:equatable/equatable.dart';

/// Log da plataforma para o painel Master.
class PlatformLogEntity extends Equatable {
  final String id;
  final String type;
  final String message;
  final DateTime createdAt;
  final String? userId;

  const PlatformLogEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.userId,
  });

  @override
  List<Object?> get props => [id, type, message, createdAt, userId];
}
