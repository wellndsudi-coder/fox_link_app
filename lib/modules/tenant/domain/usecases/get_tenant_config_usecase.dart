import 'package:fox_link_app/modules/tenant/domain/entities/tenant_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class GetTenantConfigUseCase {
  final TenantRemoteDataSource _tenantRemote;

  GetTenantConfigUseCase(this._tenantRemote);

  Future<TenantConfig> call(String tenantId) async {
    final snapshot = await _tenantRemote.getTenant(tenantId);
    final data = snapshot.data();
    if (data == null) {
      return const TenantConfig(name: '');
    }

    return TenantConfig(
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      phone: data['phone'] as String?,
      description: data['description'] as String?,
      openingHours: TenantConfig.openingHoursFromMap(
        data['openingHours'] as Map<String, dynamic>?,
      ),
    );
  }
}
