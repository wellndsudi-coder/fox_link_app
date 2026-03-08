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
    super.category,
    super.categoryId,
    super.description,
    super.color,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      tenantId: map['tenantId'],
      name: ServiceName(map['name']),
      basePrice: Money(map['basePrice']),
      baseDuration: ServiceDuration(map['baseDuration']),
      allowProfessionalChangePrice: map['allowProfessionalChangePrice'],
      allowProfessionalChangeDuration: map['allowProfessionalChangeDuration'],
      isActive: map['isActive'],
      parentId: map['parentId'] as String?,
      category: map['category'] as String?,
      categoryId: map['categoryId'] as String?,
      description: map['description'] as String?,
      color: map['color'] as int?,
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
      category: service.category,
      categoryId: service.categoryId,
      description: service.description,
      color: service.color,
    );
  }
}