import 'package:equatable/equatable.dart';

/// Entidade de plano SaaS para o painel Master.
class PlanEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  final int maxProfessionals;
  final int maxServices;
  final int maxAddonServices;
  final int maxUsers;
  final List<String> features;

  const PlanEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.maxProfessionals,
    required this.maxServices,
    this.maxAddonServices = 10,
    required this.maxUsers,
    this.features = const [],
  });

  @override
  List<Object?> get props =>
      [id, name, price, maxProfessionals, maxServices, maxAddonServices, maxUsers, features];
}
