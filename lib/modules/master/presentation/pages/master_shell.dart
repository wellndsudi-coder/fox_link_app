import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/core/layout/layout_breakpoints.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/subscription_controller.dart';
import 'master_dashboard_page.dart';
import 'tenants_page.dart';
import 'plans_page.dart' as master_plans;
import 'subscriptions_page.dart';
import 'users_page.dart';
import 'platform_usage_page.dart';
import 'financial_page.dart';
import 'logs_page.dart';
import 'settings_page.dart';

/// Shell do painel Master com menu lateral.
class MasterShell extends StatefulWidget {
  const MasterShell({super.key});

  @override
  State<MasterShell> createState() => _MasterShellState();
}

class _MasterShellState extends State<MasterShell> {
  final _sessionManager = getIt<SessionManager>();
  late MasterController _controller;
  late SubscriptionController _subscriptionController;

  int _currentIndex = 0;

  static const _routes = [
    ('Dashboard', Icons.dashboard),
    ('Tenants', Icons.business),
    ('Planos', Icons.star),
    ('Assinaturas', Icons.subscriptions),
    ('Usuários', Icons.people),
    ('Uso da plataforma', Icons.analytics),
    ('Financeiro', Icons.attach_money),
    ('Logs', Icons.description),
    ('Configurações', Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _controller = getIt<MasterController>();
    _subscriptionController = getIt<SubscriptionController>();
  }

  void _onPageSelected(int index) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _onSignOut() async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    await _sessionManager.logout();
    if (!mounted) return;
    context.go('/');
  }

  String _getTitle() => _routes[_currentIndex.clamp(0, _routes.length - 1)].$1;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return TenantsPage(controller: _controller);
      case 2:
        return master_plans.MasterPlansPage(controller: _controller);
      case 3:
        return MasterSubscriptionsPage(controller: _subscriptionController);
      case 4:
        return MasterUsersPage(controller: _controller);
      case 5:
        return MasterPlatformUsagePage(controller: _controller);
      case 6:
        return MasterFinancialPage(controller: _controller);
      case 7:
        return MasterLogsPage(controller: _controller);
      case 8:
        return MasterSettingsPage(controller: _controller);
      default:
        return MasterDashboardPage(controller: _controller);
    }
  }

  Widget _buildMasterSidebar(bool wrapInDrawer) {
    final theme = Theme.of(context);
    final content = SafeArea(
      child: SizedBox(
        width: AppSidebar.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fox Link Master',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: List.generate(_routes.length, (i) => _buildMasterMenuItem(_routes[i].$2, _routes[i].$1, i)),
              ),
            ),
            Container(
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
                onTap: () => _onSignOut(),
              ),
            ),
          ],
        ),
      ),
    );

    if (wrapInDrawer) {
      return Drawer(
        backgroundColor: theme.colorScheme.surface,
        child: content,
      );
    }
    return Material(
      color: theme.colorScheme.surface,
      child: content,
    );
  }

  Widget _buildMasterMenuItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : AppColors.mutedForeground(context);

    return ListTile(
      leading: Icon(icon, size: 22, color: color),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => _onPageSelected(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useDrawer = LayoutBreakpoints.useDrawer(context);

    return AppLayout(
      title: _getTitle(),
      sidebarBuilder: (_) => _buildMasterSidebar(useDrawer),
      body: _buildBody(),
      userInitials: _getUserInitials(),
    );
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, 1).toUpperCase();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}
