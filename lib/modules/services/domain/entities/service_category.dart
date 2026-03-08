class ServiceCategory {
  final String id;
  final String tenantId;
  final String name;

  const ServiceCategory({
    required this.id,
    required this.tenantId,
    required this.name,
  });

  ServiceCategory copyWith({String? id, String? tenantId, String? name}) {
    return ServiceCategory(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
    );
  }
}
