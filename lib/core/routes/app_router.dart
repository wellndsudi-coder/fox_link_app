import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/register_page.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/professional_shell.dart';
import '../../core/widgets/client_shell.dart';
import '../../modules/master/presentation/pages/master_dashboard.dart';
import '../../modules/subscription/presentation/pages/trial_expired_page.dart';
import '../../modules/subscription/presentation/pages/plans_page.dart';
import '../../modules/onboarding/presentation/pages/onboarding_page.dart';
import '../../modules/auth/domain/entities/onboarding_data.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;

    // Rotas públicas
    if (loc == '/' || loc == '/register') {
      if (user == null) return null;
      // Logado: redirecionar será feito pelo LoginPage após carregar roles
      return null;
    }

    // Rotas protegidas
    if (user == null) return '/';

    return null;
  },
  routes: [
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
    ),
    GoRoute(
      path: '/professional',
      builder: (context, state) => const ProfessionalShell(),
    ),
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientShell(),
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
