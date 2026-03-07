import 'package:flutter/material.dart';
import 'package:fox_link_app/core/widgets/client_shell.dart';

/// Wrapper para ClientShell. Use ClientShell diretamente em novas navegações.
class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClientShell();
  }
}