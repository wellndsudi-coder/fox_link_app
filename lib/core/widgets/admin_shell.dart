import 'package:flutter/material.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_panel.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professionals_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/multi_professional_agenda_page.dart';
import 'package:fox_link_app/modules/services/presentation/pages/admin_services_page.dart';
import 'package:fox_link_app/modules/clients/presentation/pages/clients_page.dart';
import 'package:fox_link_app/modules/settings/presentation/pages/settings_page.dart';
import 'package:fox_link_app/modules/subscription/presentation/pages/plans_page.dart';
import 'package:fox_link_app/modules/subscription/presentation/widgets/trial_banner.dart';
import 'package:fox_link_app/modules/auth/presentation/pages/login_page.dart';
import 'package:fox_link_app/modules/reports/presentation/pages/reports_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _authRepository = getIt<AuthRepository>();
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
    Navigator.pop(context);
    setState(() => _currentPageIndex = index);
  }

  void _onSwitchToProfessional() {
    Navigator.pop(context);
    setState(() => _session.setActiveMode('professional'));
  }

  void _onSwitchToAdmin() {
    Navigator.pop(context);
    setState(() => _session.setActiveMode('admin'));
  }

  Future<void> _onSignOut() async {
    Navigator.pop(context);
    await _authRepository.signOut();
    _session.clear();
    _whiteLabel.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  String _getTitle() {
    if (_session.activeMode == 'professional') return 'Modo Profissional';
    const titles = [
      'Dashboard',
      'Agenda',
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
    if (_session.activeMode == 'professional') {
      return const ProfessionalPanel();
    }
    return IndexedStack(
      index: _currentPageIndex,
      children: [
        AdminDashboard(
          refreshTrigger: _dashboardRefreshTrigger,
          onNavigateToPage: _onPageSelected,
        ),
        const MultiProfessionalAgendaPage(),
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
    if (_session.activeMode == 'professional') {
      final isTablet = MediaQuery.of(context).size.width >= 600;
      final sidebar = _buildDrawer(wrapInDrawer: !isTablet);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modo Profissional'),
          leading: isTablet ? null : Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: isTablet ? null : sidebar,
        body: isTablet
            ? Row(
                children: [
                  sidebar,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const TrialBanner(),
                        Expanded(child: _buildBody()),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TrialBanner(),
                  Expanded(child: _buildBody()),
                ],
              ),
      );
    }

    return AppLayout(
      title: _getTitle(),
      actions: _getActions(),
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

  Widget _buildDrawer({bool wrapInDrawer = true}) {
    final config = _whiteLabel.config;
    return AppSidebar(
      currentPageIndex: _currentPageIndex,
      isProfessionalMode: _session.activeMode == 'professional',
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
