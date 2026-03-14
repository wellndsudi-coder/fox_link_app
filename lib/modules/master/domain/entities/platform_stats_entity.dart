import 'package:equatable/equatable.dart';

/// Estatísticas de uso da plataforma para o painel Master.
class PlatformStatsEntity extends Equatable {
  final int appointmentsToday;
  final int appointmentsMonth;
  final int activeProfessionals;
  final Map<String, int> topServices;
  final int activeTenants;

  const PlatformStatsEntity({
    required this.appointmentsToday,
    required this.appointmentsMonth,
    required this.activeProfessionals,
    this.topServices = const {},
    required this.activeTenants,
  });

  @override
  List<Object?> get props =>
      [appointmentsToday, appointmentsMonth, activeProfessionals, topServices, activeTenants];
}
