import 'package:fox_link_app/modules/tenant/domain/entities/white_label_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class GetWhiteLabelConfigUseCase {
  final TenantRemoteDataSource _tenantRemote;

  GetWhiteLabelConfigUseCase(this._tenantRemote);

  Future<WhiteLabelConfig> call(String tenantId) async {
    final snapshot = await _tenantRemote.getTenant(tenantId);
    final data = snapshot.data();
    if (data == null) {
      return const WhiteLabelConfig(name: 'FOX LINK');
    }

    final name = data['name'] as String? ?? 'FOX LINK';
    final logoUrl = data['logoUrl'] as String?;
    final primaryColorHex = data['primaryColor'] as String?;
    final primaryColor = WhiteLabelConfig.parsePrimaryColor(primaryColorHex);

    return WhiteLabelConfig(
      name: name,
      logoUrl: logoUrl,
      primaryColor: primaryColor,
    );
  }
}
