import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/white_label/white_label_service.dart';
import 'package:fox_link_app/core/routes/app_router.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void _setupFcmForegroundHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      debugPrint('FCM: ${message.notification?.title} - ${message.notification?.body}');
    }
  });
}

bool _isRescheduleNotification(RemoteMessage message) {
  return message.data['type'] == 'reschedule_requested';
}

void _setupFcmNotificationTapHandler(GoRouter router) {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (_isRescheduleNotification(message)) {
      router.go('/client', extra: 2);
    }
  });

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && _isRescheduleNotification(message)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/client', extra: 2);
      });
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  _setupFcmForegroundHandler();

  await initializeDateFormatting('pt_BR');

  await setupInjection();

  final router = createAppRouter();
  _setupFcmNotificationTapHandler(router);
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
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en'),
          ],
        );
      },
    );
  }
}