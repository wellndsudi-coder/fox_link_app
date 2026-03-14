import 'package:equatable/equatable.dart';

/// Estatísticas financeiras para o painel Master.
class FinancialStatsEntity extends Equatable {
  final double mrr;
  final double totalRevenue;
  final int cancellations;
  final double averageTicket;

  const FinancialStatsEntity({
    required this.mrr,
    required this.totalRevenue,
    this.cancellations = 0,
    this.averageTicket = 0,
  });

  @override
  List<Object?> get props => [mrr, totalRevenue, cancellations, averageTicket];
}
