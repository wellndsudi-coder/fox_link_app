import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fox_link_app/core/auth/session_manager.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/injection/injection.dart';

/// Screen shown during app startup while validating session.
/// Redirects to dashboard if valid, login if not.
/// Na web, evita FlutterSecureStorage (pode travar) indo direto ao login.
class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    _validateAndRedirect();
  }

  Future<void> _validateAndRedirect() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.go('/');
      return;
    }

    final sessionManager = getIt<SessionManager>();
    final valid = await sessionManager.validateSession().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    if (!mounted) return;
    if (valid) {
      final session = getIt<TenantSession>();
      final roles = session.roles;
      if (roles.contains('master')) {
        context.go('/master');
      } else if (roles.contains('owner') || roles.contains('admin')) {
        context.go('/admin');
      } else if (roles.contains('professional')) {
        context.go('/professional');
      } else {
        context.go('/client');
      }
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
