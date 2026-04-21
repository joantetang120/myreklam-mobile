import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myreklam/firebase_options.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';
import 'dart:async';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔔 Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'myreklam_notifications';
  static const _channelName = 'Myreklam Notifications';

  String? _fcmToken;

  /// Initialize push notifications (Firebase must already be initialized)
  Future<void> init() async {
    print('🔔 Initializing PushNotificationService...');

    // Firebase is already initialized in main(), just get the instance
    _messaging = FirebaseMessaging.instance;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS)
    await _requestPermission();

    // Initialize local notifications for foreground messages
    await _initLocalNotifications();

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    print('🔔 FCM Token: ${_fcmToken?.substring(0, 30)}...');

    // Register token with backend
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      print('🔔 FCM Token refreshed');
      _fcmToken = token;
      _registerTokenWithBackend(token);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    print('✅ PushNotificationService initialized');
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('🔔 iOS permission status: ${settings.authorizationStatus}');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiClient().authenticatedPost('/push-tokens', body: {'token': token});
      print('🔔 FCM token registered with backend');
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
    }
  }

  /// Unregister FCM token (on logout)
  Future<void> unregisterToken() async {
    if (_fcmToken == null) return;
    try {
      await ApiClient().authenticatedDelete('/push-tokens?token=$_fcmToken');
      print('🔔 FCM token unregistered from backend');
    } catch (e) {
      print('❌ Failed to unregister FCM token: $e');
    }
  }

  /// Handle foreground message (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Increment notification badge count
    _incrementNotificationCount();

    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Message opened app: ${message.notification?.title}');
    _navigateFromData(message.data);
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final data = _decodePayload(payload);
    _navigateFromData(data);
  }

  /// Navigate based on notification data
  void _navigateFromData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Context not available for navigation');
      return;
    }

    final type = data['type'] as String?;
    final referenceType = data['reference_type'] as String?;
    final referenceId = data['reference_id'] as String?;

    print('🔔 Navigating from notification: type=$type, ref=$referenceType, id=$referenceId');

    // TODO: Add navigation logic based on notification type
    // Example: navigate to notifications screen, specific content, etc.
  }

  /// Encode payload for local notification
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from local notification
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  /// Get current FCM token
  String? get token => _fcmToken;

  /// Increment notification count when a new notification arrives
  void _incrementNotificationCount() {
    final currentCount = CustomBottomBar.notificationCountNotifier.value;
    CustomBottomBar.notificationCountNotifier.value = currentCount + 1;
  }

  /// Refresh notification count from backend (call when app comes to foreground)
  void refreshNotificationCount() {
    CustomBottomBar.refreshNotificationNotifier.value = !CustomBottomBar.refreshNotificationNotifier.value;
  }
}
