import 'package:flutter/material.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/tenant/domain/entities/white_label_config.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/presentation/pages/edit_tenant_page.dart';
import 'package:fox_link_app/modules/settings/presentation/widgets/salon_color_card.dart';
import 'package:fox_link_app/modules/settings/presentation/widgets/settings_list_item.dart';
import 'package:fox_link_app/modules/settings/presentation/widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _session = getIt<TenantSession>();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _whiteLabel = getIt<WhiteLabelService>();

  static const String _appVersion = '1.0.0';

  Future<void> _onColorSelected(Color color) async {
    final tenantId = _session.tenantId;
    if (tenantId == null) return;

    try {
      final hex = WhiteLabelConfig.toHex(color);
      await _tenantRemote.updateTenantConfig(
        tenantId: tenantId,
        primaryColor: hex,
      );
      await _whiteLabel.load(tenantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cor do salão atualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar cor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _whiteLabel,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SalonColorCard(
              selectedColor: _whiteLabel.config.primaryColor,
              onColorSelected: _onColorSelected,
            ),

            const SizedBox(height: 24),

            SettingsSection(
              label: 'Salão',
              children: [
              SettingsListItem(
                icon: Icons.business,
                title: 'Dados do salão',
                subtitle: 'Nome, endereço, telefone',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditTenantPage(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SettingsListItem(
                icon: Icons.palette_outlined,
                title: 'Aparência',
                subtitle: 'Cores e personalização',
                onTap: () {
                  // Mesma tela de configurações ou modal de aparência
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Em breve')),
                  );
                },
              ),
              ],
            ),

            const SizedBox(height: 24),

            SettingsSection(
              label: 'Conta',
              children: [
              SettingsListItem(
                icon: Icons.notifications_outlined,
                title: 'Notificações',
                subtitle: 'Push, e-mail, SMS',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Em breve')),
                  );
                },
              ),
              const SizedBox(height: 12),
              SettingsListItem(
                icon: Icons.security,
                title: 'Segurança',
                subtitle: 'Senha e autenticação',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Em breve')),
                  );
                },
              ),
              ],
            ),

            const SizedBox(height: 24),

            SettingsSection(
              label: 'Sobre',
              children: [
              SettingsListItem(
                icon: Icons.help_outline,
                title: 'Ajuda',
                subtitle: 'Central de ajuda',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Em breve')),
                  );
                },
              ),
              const SizedBox(height: 12),
              SettingsListItem(
                icon: Icons.info_outline,
                title: 'Sobre o app',
                subtitle: 'Versão $_appVersion',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('FOX LINK v$_appVersion')),
                  );
                },
              ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
