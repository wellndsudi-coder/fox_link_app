import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

/// Modo do menu lateral conforme a role do usuário.
enum SidebarMode {
  admin,
  owner,
  professional,
  client,
}

/// Menu lateral conforme design FoxLink Studio.
class AppSidebar extends StatelessWidget {
  final SidebarMode mode;
  final int currentPageIndex;
  final bool canSwitchToProfessional;
  final String? tenantName;
  final String? logoUrl;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onSwitchToProfessional;
  final VoidCallback? onSwitchToAdmin;
  final VoidCallback? onSignOut;
  final bool wrapInDrawer;

  const AppSidebar({
    super.key,
    required this.mode,
    required this.currentPageIndex,
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
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final content = SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(context),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );

    if (wrapInDrawer) {
      return Drawer(
        backgroundColor: surfaceColor,
        child: content,
      );
    }
    return Material(
      color: surfaceColor,
      child: content,
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    switch (mode) {
      case SidebarMode.admin:
      case SidebarMode.owner:
        return _buildAdminMenuItems(context);
      case SidebarMode.professional:
        return _buildProfessionalMenuItems(context);
      case SidebarMode.client:
        return _buildClientMenuItems(context);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  'Agendamento inteligente',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground(context),
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
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, size: 20, color: AppColors.mutedForeground(context)),
        title: Text(
          'Sair',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground(context),
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
        color: AppColors.accent(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Icon(Icons.pets, color: AppColors.primary(context), size: 22),
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

  List<Widget> _buildProfessionalMenuItems(BuildContext context) {
    final items = [
      _MenuItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      _MenuItem(icon: Icons.calendar_month, label: 'Minha Agenda', index: 1),
      _MenuItem(icon: Icons.access_time, label: 'Horários', index: 2),
      _MenuItem(icon: Icons.people, label: 'Clientes', index: 3),
      _MenuItem(icon: Icons.design_services, label: 'Serviços', index: 4),
      _MenuItem(icon: Icons.analytics, label: 'Relatórios pessoais', index: 5),
      _MenuItem(icon: Icons.settings, label: 'Configurações', index: 6),
    ];

    final list = items.map(
      (item) => _buildMenuItem(
        context: context,
        icon: item.icon,
        label: item.label,
        selected: currentPageIndex == item.index,
        onTap: () => onPageSelected(item.index),
      ),
    ).toList();

    if (canSwitchToProfessional) {
      list.add(
        _buildMenuItem(
          context: context,
          icon: Icons.admin_panel_settings,
          label: 'Voltar para Admin',
          onTap: onSwitchToAdmin,
        ),
      );
    }
    return list;
  }

  List<Widget> _buildClientMenuItems(BuildContext context) {
    final items = [
      _MenuItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      _MenuItem(icon: Icons.add_circle_outline, label: 'Agendar serviço', index: 1),
      _MenuItem(icon: Icons.calendar_today, label: 'Meus agendamentos', index: 2),
      _MenuItem(icon: Icons.history, label: 'Histórico', index: 3),
      _MenuItem(icon: Icons.favorite_border, label: 'Favoritos', index: 4),
      _MenuItem(icon: Icons.person_outline, label: 'Perfil', index: 5),
    ];

    return items.map(
      (item) => _buildMenuItem(
        context: context,
        icon: item.icon,
        label: item.label,
        selected: currentPageIndex == item.index,
        onTap: () => onPageSelected(item.index),
      ),
    ).toList();
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
        : AppColors.mutedForeground(context);

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
          color: selected ? theme.colorScheme.primary : AppColors.textPrimary(context),
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
