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
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      tenantId: map['tenantId'],
      name: ServiceName(map['name']),
      basePrice: Money(map['basePrice']),
      baseDuration: ServiceDuration(map['baseDuration']),
      allowProfessionalChangePrice: map['allowProfessionalChangePrice'],
      allowProfessionalChangeDuration:
      map['allowProfessionalChangeDuration'],
      isActive: map['isActive'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
    );
  }
}