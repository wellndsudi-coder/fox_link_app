import 'package:equatable/equatable.dart';

/// Entidade de tenant para o painel Master.
class TenantEntity extends Equatable {
  final String id;
  final String name;
  final String plan;
  final String status;
  final DateTime createdAt;
  final String subscriptionStatus;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool blocked;
  final int professionalCount;

  const TenantEntity({
    required this.id,
    required this.name,
    required this.plan,
    required this.status,
    required this.createdAt,
    this.subscriptionStatus = 'trial',
    this.trialStart,
    this.trialEnd,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.blocked = false,
    this.professionalCount = 0,
  });

  int? get trialDaysRemaining {
    if (trialEnd == null) return null;
    final diff = trialEnd!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  @override
  List<Object?> get props => [
        id, name, plan, status, createdAt, subscriptionStatus,
        trialStart, trialEnd, subscriptionStart, subscriptionEnd, blocked, professionalCount
      ];
}
