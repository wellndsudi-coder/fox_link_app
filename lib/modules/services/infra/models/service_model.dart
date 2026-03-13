import '../../domain/entities/service.dart';
import '../../domain/value_objects/service_name.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/service_duration.dart';

class ServiceModel extends Service {
  ServiceModel({
    required super.id,
    required super.tenantId,
    required super.name,
    required super.basePrice,
    required super.baseDuration,
    required super.allowProfessionalChangePrice,
    required super.allowProfessionalChangeDuration,
    required super.isActive,
    super.parentId,
    List<String>? linkedBaseServiceIds,
    bool? isAddon,
    super.category,
    super.categoryId,
    super.description,
    super.color,
  }) : super(
    linkedBaseServiceIds: linkedBaseServiceIds ?? [],
    isAddon: isAddon ?? (parentId != null && parentId!.isNotEmpty),
  );

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id, [String? tenantIdFromPath]) {
    final t = map['tenantId'] as String? ?? tenantIdFromPath ?? '';
    final bp = (map['basePrice'] is num) ? (map['basePrice'] as num).toDouble() : 0.0;
    final bd = (map['baseDuration'] is num) ? (map['baseDuration'] as num).toInt() : 30;
    final nameStr = map['name']?.toString() ?? 'Serviço';
    final parentId = map['parentId'] as String?;
    List<String>? linkedIds;
    if (map['linkedBaseServiceIds'] is List) {
      linkedIds = (map['linkedBaseServiceIds'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final isAddonVal = map['isAddon'] as bool? ??
        (parentId != null && parentId.isNotEmpty) ||
        (linkedIds != null && linkedIds.isNotEmpty);
    return ServiceModel(
      id: id,
      tenantId: t.isNotEmpty ? t : (tenantIdFromPath ?? ''),
      name: ServiceName(nameStr.length >= 3 ? nameStr : 'Serviço $id'),
      basePrice: Money(bp),
      baseDuration: ServiceDuration(bd < 5 ? 30 : (bd > 600 ? 600 : bd)),
      allowProfessionalChangePrice: map['allowProfessionalChangePrice'] == true,
      allowProfessionalChangeDuration: map['allowProfessionalChangeDuration'] == true,
      isActive: map['isActive'] != false,
      parentId: parentId,
      linkedBaseServiceIds: linkedIds,
      isAddon: isAddonVal,
      category: map['category'] as String?,
      categoryId: map['categoryId'] as String?,
      description: map['description'] as String?,
      color: (map['color'] is int) ? map['color'] as int : ((map['color'] is num) ? (map['color'] as num).toInt() : null),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'tenantId': tenantId,
      'name': name.value,
      'basePrice': basePrice.value,
      'baseDuration': baseDuration.minutes,
      'allowProfessionalChangePrice':
      allowProfessionalChangePrice,
      'allowProfessionalChangeDuration':
      allowProfessionalChangeDuration,
      'isActive': isActive,
    };
    if (parentId != null && parentId!.isNotEmpty) map['parentId'] = parentId;
    if (linkedBaseServiceIds.isNotEmpty) {
      map['linkedBaseServiceIds'] = linkedBaseServiceIds;
    }
    map['isAddon'] = isAddon;
    if (category != null && category!.isNotEmpty) map['category'] = category;
    if (categoryId != null && categoryId!.isNotEmpty) map['categoryId'] = categoryId;
    if (description != null && description!.isNotEmpty) map['description'] = description;
    if (color != null) map['color'] = color;
    return map;
  }

  factory ServiceModel.fromEntity(Service service) {
    return ServiceModel(
      id: service.id,
      tenantId: service.tenantId,
      name: service.name,
      basePrice: service.basePrice,
      baseDuration: service.baseDuration,
      allowProfessionalChangePrice:
      service.allowProfessionalChangePrice,
      allowProfessionalChangeDuration:
      service.allowProfessionalChangeDuration,
      isActive: service.isActive,
      parentId: service.parentId,
      linkedBaseServiceIds: service.linkedBaseServiceIds,
      isAddon: service.isAddon,
      category: service.category,
      categoryId: service.categoryId,
      description: service.description,
      color: service.color,
    );
  }
}