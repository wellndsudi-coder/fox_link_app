import 'package:equatable/equatable.dart';

/// Entidade de assinatura para o painel Master.
class SubscriptionEntity extends Equatable {
  final String id;
  final String tenantId;
  final String tenantName;
  final String plan;
  final String status;
  final DateTime startDate;
  final DateTime? renewalDate;
  final double value;

  const SubscriptionEntity({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.plan,
    required this.status,
    required this.startDate,
    this.renewalDate,
    this.value = 0,
  });

  @override
  List<Object?> get props =>
      [id, tenantId, tenantName, plan, status, startDate, renewalDate, value];
}
