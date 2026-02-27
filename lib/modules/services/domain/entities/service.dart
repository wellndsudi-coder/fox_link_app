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

  Service({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.basePrice,
    required this.baseDuration,
    required this.allowProfessionalChangePrice,
    required this.allowProfessionalChangeDuration,
    required this.isActive,
  }) {
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
    );
  }
}