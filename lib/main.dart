import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:myreklam/firebase_options.dart';
import 'package:myreklam/screens/profile_pro/pro_profile_screen.dart';
import 'package:myreklam/screens/splash_screen.dart';
import 'package:myreklam/services/chat_service.dart';
import 'package:myreklam/services/chat_notification_service.dart';
import 'package:myreklam/services/push_notification_service.dart';
import 'package:myreklam/screens/login_screen.dart';
import 'package:myreklam/providers/conversation_provider.dart';
import 'package:myreklam/services/auth_state_manager.dart';
import 'package:myreklam/services/deep_link_service.dart';
import 'package:myreklam/services/stripe_payment_service.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST before any other service
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialisé');

  // Initialize Stripe for payments
  await StripePaymentService.initialize();
  print('✅ Stripe initialisé');

  // Set navigator key for AuthStateManager
  AuthStateManager().setNavigatorKey(navigatorKey);

  // Initialisation de pusher
  await ChatService.initializePusher();
  print('✅ Pusher initialisé');

  // Initialisation du service de notifications chat
  await ChatNotificationService.instance.init();
  print('✅ ChatNotificationService initialisé');

  // Initialisation du service de push notifications (FCM)
  await PushNotificationService.instance.init();
  print('✅ PushNotificationService initialisé');

  // Initialisation du service de deep links
  await DeepLinkService.instance.init();
  print('✅ DeepLinkService initialisé');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConversationProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        debugShowCheckedModeBanner: false,
        title: 'Myreklam',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B8D4B)),
          useMaterial3: true,
        ),
        // Define routes for navigation
        routes: {'/login': (context) => const LoginScreen()},
        home: const SplashScreen(),
      ),
    );
  }
}
