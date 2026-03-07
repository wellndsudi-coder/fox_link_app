import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

/// Menu lateral conforme design FoxLink Studio.
class AppSidebar extends StatelessWidget {
  final int currentPageIndex;
  final bool isProfessionalMode;
  final bool canSwitchToProfessional;
  final String? tenantName;
  final String? logoUrl;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onSwitchToProfessional;
  final VoidCallback? onSwitchToAdmin;
  final VoidCallback? onSignOut;
  /// Se false, retorna apenas o conteúdo (para sidebar persistente em tablet).
  final bool wrapInDrawer;

  const AppSidebar({
    super.key,
    required this.currentPageIndex,
    required this.isProfessionalMode,
    required this.canSwitchToProfessional,
    required this.onPageSelected,
    this.onSwitchToAdmin,
    this.onSwitchToProfessional,
    this.onSignOut,
    this.tenantName,
    this.logoUrl,
    this.wrapInDrawer = true,
  });

  static const double width = 280;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (isProfessionalMode)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.admin_panel_settings,
                    label: 'Modo Admin',
                    onTap: onSwitchToAdmin,
                  )
                else
                  ..._buildAdminMenuItems(context),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );

    if (wrapInDrawer) {
      return Drawer(
        backgroundColor: Colors.white,
        child: content,
      );
    }
    return Material(
      color: Colors.white,
      child: content,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (logoUrl != null && logoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Image.network(
                logoUrl!,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackLogo(context),
              ),
            )
          else
            _buildFallbackLogo(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantName ?? 'FOX LINK',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                Text(
                  'Agendamento inteligente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, size: 20, color: AppTheme.mutedForeground),
        title: Text(
          'Sair',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedForeground,
          ),
        ),
        onTap: onSignOut,
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Icon(Icons.pets, color: AppTheme.primaryColor, size: 22),
    );
  }

  List<Widget> _buildAdminMenuItems(BuildContext context) {
    final items = [
      _MenuItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      _MenuItem(icon: Icons.calendar_month, label: 'Agenda', index: 1),
      _MenuItem(icon: Icons.people, label: 'Clientes', index: 2),
      _MenuItem(icon: Icons.person, label: 'Profissionais', index: 3),
      _MenuItem(icon: Icons.design_services, label: 'Serviços', index: 4),
      _MenuItem(icon: Icons.analytics, label: 'Relatórios', index: 5),
      _MenuItem(icon: Icons.settings, label: 'Configurações', index: 6),
      _MenuItem(icon: Icons.star, label: 'Planos', index: 7),
    ];

    return [
      ...items.map(
        (item) => _buildMenuItem(
          context: context,
          icon: item.icon,
          label: item.label,
          selected: currentPageIndex == item.index,
          onTap: () => onPageSelected(item.index),
        ),
      ),
      if (canSwitchToProfessional)
        _buildMenuItem(
          context: context,
          icon: Icons.person_pin,
          label: 'Modo Profissional',
          onTap: onSwitchToProfessional,
        ),
    ];
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : const Color(0xFF64748B);

    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: color,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? theme.colorScheme.primary : const Color(0xFF0F172A),
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;

  _MenuItem({required this.icon, required this.label, required this.index});
}
