import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoxLink Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go('/');
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Usuário autenticado 🚀',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}