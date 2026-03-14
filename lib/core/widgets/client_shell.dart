import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/layout/app_layout.dart';
import 'package:fox_link_app/core/layout/app_sidebar.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fox_link_app/core/notification/fcm_token_service.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_appointments_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_favorites_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_history_page.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_profile_page.dart';
import 'package:fox_link_app/modules/scheduling/presentation/pages/create_appointment_page.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, this.initialPageIndex = 0});

  final int initialPageIndex;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

/// Dados do slot selecionado para pré-preencher a página de agendamento.
class _PendingBookingSlot {
  final DateTime slot;
  final String professionalId;
  final String professionalName;
  final String serviceId;

  const _PendingBookingSlot({
    required this.slot,
    required this.professionalId,
    required this.professionalName,
    required this.serviceId,
  });
}

class _ClientShellState extends State<ClientShell> {
  final _session = getIt<TenantSession>();
  final _whiteLabel = getIt<WhiteLabelService>();
  final _sessionManager = getIt<SessionManager>();

  late int _currentPageIndex;
  int _createAppointmentKey = 0;
  _PendingBookingSlot? _pendingSlot;

  static const _titles = [
    'Painel de controle',
    'Agendar serviço',
    'Meus agendamentos',
    'Histórico',
    'Favoritos',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex.clamp(0, 5);
    _session.setActiveMode('client');
    _ensureSessionAndLoadWhiteLabel();
  }

  Future<void> _ensureSessionAndLoadWhiteLabel() async {
    var tenantId = _session.tenantId;
    if (tenantId == null) {
      await _sessionManager.validateSessionForWeb();
      tenantId = _session.tenantId;
    }
    if (tenantId != null && mounted) {
      _whiteLabel.load(tenantId);
    }
    final uid = _session.uid;
    if (uid != null) {
      getIt<FcmTokenService>().registerToken(uid);
    }
    if (mounted) setState(() {});
  }

  void _onAgendarWithSlot({
    required DateTime slot,
    required String professionalId,
    required String professionalName,
    required String serviceId,
  }) {
    setState(() {
      _pendingSlot = _PendingBookingSlot(
        slot: slot,
        professionalId: professionalId,
        professionalName: professionalName,
        serviceId: serviceId,
      );
      _createAppointmentKey++;
      _currentPageIndex = 1;
    });
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.pop(context);
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
          ClientDashboardPage(
            onNavigateToPage: _onPageSelected,
            onAgendarWithSlot: _onAgendarWithSlot,
            isActive: _currentPageIndex == 0,
          ),
          CreateAppointmentPage(
            key: ValueKey(_createAppointmentKey),
            initialDate: _pendingSlot != null
                ? DateTime(_pendingSlot!.slot.year, _pendingSlot!.slot.month, _pendingSlot!.slot.day)
                : null,
            initialSlot: _pendingSlot?.slot,
            initialProfessionalId: _pendingSlot?.professionalId,
            initialProfessionalName: _pendingSlot?.professionalName,
            initialServiceId: _pendingSlot?.serviceId,
            embeddedInShell: true,
            onSuccess: () {
              setState(() {
                _pendingSlot = null;
                _createAppointmentKey++;
                _currentPageIndex = 0;
              });
            },
            onCancel: () {
              setState(() {
                _pendingSlot = null;
                _currentPageIndex = 0;
              });
            },
          ),
          ClientAppointmentsPage(
            isActive: _currentPageIndex == 2,
            onRefreshNeeded: () => setState(() {}),
            onNavigateToBook: () => _onPageSelected(1),
          ),
          const ClientHistoryPage(),
          const ClientFavoritesPage(),
          const ClientProfilePage(),
        ],
      ),
    );
  }
}
