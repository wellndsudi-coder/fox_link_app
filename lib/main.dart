import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/core/routes/app_router.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR');

  await setupInjection();

  final router = createAppRouter();
  runApp(FoxLinkApp(router: router));
}

class FoxLinkApp extends StatelessWidget {
  const FoxLinkApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final whiteLabel = getIt<WhiteLabelService>();

    return ListenableBuilder(
      listenable: whiteLabel,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Fox Link App',
          debugShowCheckedModeBanner: false,
          theme: whiteLabel.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}