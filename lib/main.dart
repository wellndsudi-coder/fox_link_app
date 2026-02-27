import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'firebase_options.dart';
import 'package:fox_link_app/modules/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup de injeção de dependência
  await setupInjection();

  runApp(const FoxLinkApp());
}

class FoxLinkApp extends StatelessWidget {
  const FoxLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fox Link App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginPage(),
    );
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Fox Link App 🦊',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}