import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_appointments_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_favorites_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_history_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_profile_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _authRepository = getIt<AuthRepository>();

  int _currentPageIndex = 0;

  static const _titles = [
    'Dashboard',
    'Agendar serviço',
    'Meus agendamentos',
    'Histórico',
    'Favoritos',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();
    _session.setActiveMode('client');
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

  Future<void> _onSignOut() async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    await _authRepository.signOut();
    _session.clear();
    _whiteLabel.clear();
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
        mode: SidebarMode.client,
        currentPageIndex: _currentPageIndex,
        canSwitchToProfessional: false,
        tenantName: config.name,
        logoUrl: config.logoUrl,
        onPageSelected: _onPageSelected,
        onSignOut: _onSignOut,
        wrapInDrawer: !isTablet,
      ),
      body: IndexedStack(
        index: _currentPageIndex,
        children: [
          ClientDashboardPage(onNavigateToPage: _onPageSelected),
          CreateAppointmentPage(
            embeddedInShell: true,
            onSuccess: () {
              setState(() => _currentPageIndex = 0);
            },
          ),
          ClientAppointmentsPage(
            isActive: _currentPageIndex == 2,
            onRefreshNeeded: () => setState(() {}),
          ),
          const ClientHistoryPage(),
          const ClientFavoritesPage(),
          const ClientProfilePage(),
        ],
      ),
    );
  }
}
