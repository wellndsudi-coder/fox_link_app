import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/login_page.dart';
import '../../features/home/home_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn = state.matchedLocation == '/';

    if (user == null) {
      return loggingIn ? null : '/';
    }

    if (user != null && loggingIn) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);