import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/professional_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/professional_reports_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/professional_agenda_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_clients_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_services_page.dart';
import 'package:fox_link_app/modules/professionals/presentation/pages/professional_settings_page.dart';
import 'package:fox_link_app/modules/availability/presentation/pages/professional_availability_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/professional_appointments_page.dart';
import 'package:fox_link_app/modules/subscription/presentation/widgets/trial_banner.dart';

class ProfessionalShell extends StatefulWidget {
  const ProfessionalShell({super.key});

  @override
  State<ProfessionalShell> createState() => _ProfessionalShellState();
}

class _ProfessionalShellState extends State<ProfessionalShell> {
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _sessionManager = getIt<SessionManager>();

  int _currentPageIndex = 0;
  DateTime? _agendaInitialDate;

  static const _titles = [
    'Dashboard',
    'Minha Agenda',
    'Agendamentos',
    'Horários',
    'Clientes',
    'Serviços',
    'Relatórios pessoais',
    'Configurações',
  ];

  @override
  void initState() {
    super.initState();
    _session.setActiveMode('professional');
    _ensureSessionAndLoadWhiteLabel();
  }

  Future<void> _ensureSessionAndLoadWhiteLabel() async {
    var tenantId = _session.tenantId;
    // Sempre validar sessão ao entrar no modo professional para garantir
    // tenantId e professionalId corretos (evita pendentes não aparecerem na agenda web).
    final needRefresh = tenantId == null ||
        (_session.professionalId == null && _session.hasRole('professional'));
    if (needRefresh) {
      await _sessionManager.validateSessionForWeb();
      tenantId = _session.tenantId;
    }
    if (tenantId != null && mounted) {
      _whiteLabel.load(tenantId);
    }
    if (mounted) setState(() {});
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}';
      }
      return parts[0].length >= 2 ? parts[0].substring(0, 2) : parts[0];
    }
    final email = user?.email;
    if (email != null && email.length >= 2) {
      return email.substring(0, 2).toUpperCase();
    }
    return '?';
  }

  void _onPageSelected(int index) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    setState(() {
      if (index != 1) _agendaInitialDate = null;
      _currentPageIndex = index;
    });
  }

  void _navigateToAgendaWithDate(DateTime date) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    setState(() {
      _agendaInitialDate = date;
      _currentPageIndex = 1;
    });
  }

  void _onSwitchToAdmin() {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    _session.setActiveMode('admin');
    if (!mounted) return;
    context.go('/admin');
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

  @override
  Widget build(BuildContext context) {
    final config = _whiteLabel.config;

    return AppLayout(
      title: _titles[_currentPageIndex.clamp(0, _titles.length - 1)],
      userInitials: _getUserInitials(),
      sidebarBuilder: (isTablet) => AppSidebar(
        mode: SidebarMode.professional,
        currentPageIndex: _currentPageIndex,
        canSwitchToProfessional: _session.canSwitchToProfessional,
        tenantName: config.name,
        logoUrl: config.logoUrl,
        onPageSelected: _onPageSelected,
        onSwitchToAdmin: _onSwitchToAdmin,
        onSignOut: _onSignOut,
        wrapInDrawer: !isTablet,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TrialBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentPageIndex,
              children: [
                ProfessionalDashboard(
                  isActive: _currentPageIndex == 0,
                  onNavigateToAgenda: () => setState(() => _currentPageIndex = 1),
                  onNavigateToPage: _onPageSelected,
                ),
                ProfessionalAgendaPage(
                  isActive: _currentPageIndex == 1,
                  initialDate: _agendaInitialDate,
                ),
                ProfessionalAppointmentsPage(
                  isActive: _currentPageIndex == 2,
                  onNavigateToAgendaWithDate: _navigateToAgendaWithDate,
                ),
                const ProfessionalAvailabilityPage(),
                const ProfessionalClientsPage(),
                const ProfessionalServicesPage(),
                const ProfessionalReportsPage(),
                const ProfessionalSettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
