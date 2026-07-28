import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:myreklam/firebase_options.dart';
import 'package:myreklam/screens/splash_screen.dart';
import 'package:myreklam/services/chat_service.dart';
import 'package:myreklam/services/chat_notification_service.dart';
import 'package:myreklam/services/push_notification_service.dart';
import 'package:myreklam/screens/login_screen.dart';
import 'package:myreklam/providers/conversation_provider.dart';
import 'package:myreklam/services/auth_state_manager.dart';
import 'package:myreklam/services/deep_link_service.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/widgets/delegation_banner.dart';
import 'package:myreklam/services/stripe_payment_service.dart';
import 'package:myreklam/widgets/force_update_gate.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initializeService(
    'Firebase',
    () =>
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  );

  await _initializeService('Stripe', StripePaymentService.initialize);

  // Set navigator key for AuthStateManager
  AuthStateManager().setNavigatorKey(navigatorKey);

  await _initializeService('Pusher', ChatService.initializePusher);
  await _initializeService(
    'Notifications chat',
    ChatNotificationService.instance.init,
  );

  // Initialisation du service de push notifications (FCM)
  if (firebaseReady) {
    await _initializeService(
      'Notifications push',
      PushNotificationService.instance.init,
    );
  }

  await _initializeService('Liens profonds', DeepLinkService.instance.init);
  await _initializeService('Délégation', DelegationManager.instance.init);

  runApp(const MyApp());
}

Future<bool> _initializeService(
  String name,
  Future<dynamic> Function() initialize,
) async {
  try {
    await initialize();
    debugPrint('$name initialisé');
    return true;
  } catch (error, stackTrace) {
    debugPrint('$name indisponible (non bloquant): $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
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
        builder: (context, child) {
          return AnimatedBuilder(
            animation: DelegationManager.instance,
            builder: (context, _) {
              if (!DelegationManager.instance.isActive || child == null) {
                return child ?? const SizedBox.shrink();
              }
              return Column(
                children: [
                  const DelegationBanner(),
                  Expanded(child: child),
                ],
              );
            },
          );
        },
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
        home: const ForceUpdateGate(child: SplashScreen()),
      ),
    );
  }
}
