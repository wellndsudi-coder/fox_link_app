import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../injection/injection.dart';
import '../../core/auth/auth_state.dart';
import '../../features/session/presentation/session_check_screen.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/register_page.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/professional_shell.dart';
import '../../core/widgets/client_shell.dart';
import '../../modules/master/presentation/pages/master_dashboard.dart';
import '../../modules/subscription/presentation/pages/trial_expired_page.dart';
import '../../modules/subscription/presentation/pages/plans_page.dart';
import '../../modules/onboarding/presentation/pages/onboarding_page.dart';
import '../../modules/auth/domain/entities/onboarding_data.dart';
import '../../modules/availability/presentation/pages/admin_professional_availability_page.dart';

GoRouter createAppRouter() => GoRouter(
  initialLocation: '/session-check',
  refreshListenable: getIt<AuthState>(),
  redirect: (context, state) {
    final authState = getIt<AuthState>();
    final loc = state.matchedLocation;

    if (loc == '/session-check') return null;

    if (loc == '/' || loc == '/register') {
      if (authState.isAuthenticated) return '/admin';
      return null;
    }

    // Permite onboarding sem auth (usuário acabou de criar conta)
    if (loc == '/onboarding') return null;

    if (authState.isUnauthenticated) return '/';

    // Na carga/refresh em rota protegida sem validação: forçar session-check primeiro
    if (authState.isChecking &&
        (loc == '/admin' || loc == '/professional' || loc == '/client' || loc == '/master')) {
      return '/session-check';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/session-check',
      builder: (context, state) => const SessionCheckScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminShell(),
      routes: [
        GoRoute(
          path: 'professional-availability/:professionalId',
          builder: (context, state) {
            final id = state.pathParameters['professionalId'] ?? '';
            final name = state.uri.queryParameters['name'];
            return AdminProfessionalAvailabilityPage(
              professionalId: id,
              professionalName: name,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/professional',
      builder: (context, state) => const ProfessionalShell(),
    ),
    GoRoute(
      path: '/client',
      builder: (context, state) {
        final initialPage = state.extra as int?;
        return ClientShell(initialPageIndex: initialPage ?? 0);
      },
    ),
    GoRoute(
      path: '/master',
      builder: (context, state) => const MasterDashboard(),
    ),
    GoRoute(
      path: '/trial-expired',
      builder: (context, state) => const TrialExpiredPage(),
    ),
    GoRoute(
      path: '/plans',
      builder: (context, state) => const PlansPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) {
        final data = state.extra as OnboardingData?;
        if (data == null) return const SizedBox.shrink();
        return OnboardingPage(data: data);
      },
    ),
  ],
);
