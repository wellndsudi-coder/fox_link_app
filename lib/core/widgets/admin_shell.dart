import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professionals_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/admin_agenda_page.dart';
import 'package:fox_link_app/modules/services/presentation/pages/admin_services_page.dart';
import 'package:fox_link_app/modules/clients/presentation/pages/clients_page.dart';
import 'package:fox_link_app/modules/settings/presentation/pages/settings_page.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/plans_page.dart';
import 'package:fox_link_app/modules/subscription/presentation/widgets/trial_banner.dart';
import 'package:fox_link_app/modules/reports/presentation/pages/reports_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _sessionManager = getIt<SessionManager>();
  final _dashboardRefreshTrigger = ValueNotifier(0);

  int _currentPageIndex = 0;

  @override
  void dispose() {
    _dashboardRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _session.setActiveMode('admin');
    final tenantId = _session.tenantId;
    if (tenantId != null) {
      _whiteLabel.load(tenantId);
    }
  }

  void _onPageSelected(int index) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    setState(() => _currentPageIndex = index);
  }

  void _onSwitchToProfessional() {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    _session.setActiveMode('professional');
    if (!mounted) return;
    context.go('/professional');
  }

  void _onSwitchToAdmin() {
    Navigator.pop(context);
    setState(() => _session.setActiveMode('admin'));
  }

  Future<void> _onSignOut() async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    _whiteLabel.clear();
    await _sessionManager.logout();
    if (!mounted) return;
    context.go('/');
  }

  String _getTitle() {
    const titles = [
      'Dashboard',
      'Calendário',
      'Clientes',
      'Profissionais',
      'Serviços',
      'Relatórios',
      'Configurações',
      'Planos',
    ];
    return titles[_currentPageIndex.clamp(0, titles.length - 1)];
  }

  List<Widget>? _getActions() {
    if (_session.activeMode == 'admin' && _currentPageIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _dashboardRefreshTrigger.value++,
        ),
      ];
    }
    return null;
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentPageIndex,
      children: [
        AdminDashboard(
          refreshTrigger: _dashboardRefreshTrigger,
          onNavigateToPage: _onPageSelected,
          isActive: _currentPageIndex == 0,
        ),
        AdminAgendaPage(isActive: _currentPageIndex == 1),
        const ClientsPage(),
        const ProfessionalsPage(),
        const AdminServicesPage(),
        const ReportsPage(),
        const SettingsPage(),
        const PlansPage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: _getTitle(),
      actions: _getActions(),
      userInitials: _getUserInitials(),
      sidebarBuilder: (isTablet) => _buildDrawer(wrapInDrawer: !isTablet),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TrialBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}';
      }
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1);
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 2).toUpperCase();
    }
    return '?';
  }

  Widget _buildDrawer({bool wrapInDrawer = true}) {
    final config = _whiteLabel.config;
    const mode = SidebarMode.owner;
    return AppSidebar(
      mode: mode,
      currentPageIndex: _currentPageIndex,
      canSwitchToProfessional: _session.canSwitchToProfessional,
      tenantName: config.name,
      logoUrl: config.logoUrl,
      onPageSelected: _onPageSelected,
      onSwitchToProfessional: _onSwitchToProfessional,
      onSwitchToAdmin: _onSwitchToAdmin,
      onSignOut: _onSignOut,
      wrapInDrawer: wrapInDrawer,
    );
  }
}
