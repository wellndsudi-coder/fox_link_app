import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/tenant/presentation/pages/edit_tenant_page.dart';
import 'package:fox_link_app/modules/settings/presentation/pages/appearance_page.dart';
import 'package:fox_link_app/modules/settings/presentation/widgets/settings_list_item.dart';
import 'package:fox_link_app/modules/settings/presentation/widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                subtitle: 'Logo, cores e personalização',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppearancePage(),
                  ),
                ),
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
    );
  }
}
