import '../value_objects/service_name.dart';
import '../value_objects/money.dart';
import '../value_objects/service_duration.dart';

class Service {
  final String id;
  final String tenantId;
  final ServiceName name;
  final Money basePrice;
  final ServiceDuration baseDuration;
  final bool allowProfessionalChangePrice;
  final bool allowProfessionalChangeDuration;
  final bool isActive;
  /// ID do serviço pai. null = serviço base. Legado: usado para addons antigos.
  final String? parentId;
  /// IDs dos serviços base que oferecem este addon. Permite addon em vários serviços.
  final List<String> linkedBaseServiceIds;
  /// true = addon (extra), false = serviço base. Addons podem ser vinculados a vários serviços.
  final bool isAddon;
  /// Categoria para agrupamento (legacy string).
  @Deprecated('Use categoryId instead')
  final String? category;
  /// ID da categoria (service_categories).
  final String? categoryId;
  /// Descrição do serviço.
  final String? description;
  /// Cor em hex.
  final int? color;

  Service({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.basePrice,
    required this.baseDuration,
    required this.allowProfessionalChangePrice,
    required this.allowProfessionalChangeDuration,
    required this.isActive,
    this.parentId,
    List<String>? linkedBaseServiceIds,
    bool? isAddon,
    this.category,
    this.categoryId,
    this.description,
    this.color,
  }) : linkedBaseServiceIds = linkedBaseServiceIds ?? [],
       isAddon = isAddon ?? (parentId != null && parentId!.isNotEmpty) {
    if (tenantId.isEmpty) {
      throw Exception('TenantId não pode ser vazio');
    }
  }

  Service copyWith({
    ServiceName? name,
    Money? basePrice,
    ServiceDuration? baseDuration,
    bool? allowProfessionalChangePrice,
    bool? allowProfessionalChangeDuration,
    bool? isActive,
    String? parentId,
    List<String>? linkedBaseServiceIds,
    bool? isAddon,
    String? category,
    String? categoryId,
    String? description,
    int? color,
  }) {
    return Service(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      baseDuration: baseDuration ?? this.baseDuration,
      allowProfessionalChangePrice:
      allowProfessionalChangePrice ??
          this.allowProfessionalChangePrice,
      allowProfessionalChangeDuration:
      allowProfessionalChangeDuration ??
          this.allowProfessionalChangeDuration,
      isActive: isActive ?? this.isActive,
      parentId: parentId ?? this.parentId,
      linkedBaseServiceIds: linkedBaseServiceIds ?? this.linkedBaseServiceIds,
      isAddon: isAddon ?? this.isAddon,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  bool get isBase => !isAddon;
}