class Tenant {
  final String id;
  final String name;
  final String planType;
  final DateTime createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.planType,
    required this.createdAt,
  });
}