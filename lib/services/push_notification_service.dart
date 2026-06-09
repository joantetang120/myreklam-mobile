import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myreklam/firebase_options.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/deep_link_service.dart';
import 'package:myreklam/services/profile_service.dart';
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

  /// Register the current FCM token with the backend.
  ///
  /// Call this *after* the user is authenticated (login / OTP / social /
  /// session restore). The `/push-tokens` endpoint requires auth, so calling
  /// it at cold start before login silently fails.
  Future<void> registerToken() async {
    try {
      _fcmToken ??= await _messaging.getToken();
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      print('❌ registerToken failed: $e');
    }
  }

  /// Show a local notification using the shared plugin/channel.
  ///
  /// `payload` is the routing string consumed by [_onNotificationTap]
  /// (see [_navigateFromData] for the supported schema).
  Future<void> showLocalNotification({
    required String? title,
    required String? body,
    required String payload,
  }) async {
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
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
      payload: payload,
    );
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

  /// Handle notification tap (local notification opened by the user)
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Legacy chat payload format: "chat_<conversationId>"
    if (payload.startsWith('chat_')) {
      _navigateFromData({
        'type': 'chat',
        'conversation_id': payload.substring('chat_'.length),
      });
      return;
    }

    _navigateFromData(_decodePayload(payload));
  }

  /// Navigate based on notification data.
  ///
  /// Supported payload schemas (keys are tolerant of common aliases):
  ///   • Chat       : type=chat, conversation_id=<id>, name=<sender>, avatar=<url>
  ///   • Content    : reference_type=<bons-plans|emplois|formations|evenements|demandes>,
  ///                  reference_id=<id>
  ///   • Follower   : type=new_follower, follower_id=<id>
  ///   • Fallback   : opens the in-app notifications screen
  void _navigateFromData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('❌ Context not available for navigation');
      return;
    }

    final type = (data['type'] ?? '').toString();
    final referenceType =
        (data['reference_type'] ?? data['ref_type'] ?? '').toString();
    final referenceId =
        (data['reference_id'] ?? data['ref_id'] ?? data['id'] ?? '').toString();

    print('🔔 Navigating from notification: type=$type, ref=$referenceType, id=$referenceId');

    // 1. Chat message → open the conversation.
    if (type == 'chat' || type == 'new_message') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? referenceId)
              .toString();
      if (conversationId.isEmpty) {
        _openNotificationsScreen(context);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            conversationId: conversationId,
            name: (data['name'] ?? data['sender_name'] ?? 'Conversation')
                .toString(),
            avatar: data['avatar']?.toString(),
          ),
        ),
      );
      return;
    }

    // 2. New follower → open the follower's public profile.
    if (type == 'new_follower') {
      final followerId =
          (data['follower_id'] ?? data['follower'] ?? referenceId).toString();
      if (followerId.isNotEmpty) {
        _openFollowerProfile(context, followerId);
      } else {
        _openNotificationsScreen(context);
      }
      return;
    }

    // 3. Content reference → reuse the deep-link routing.
    if (referenceType.isNotEmpty && referenceId.isNotEmpty) {
      DeepLinkService.instance.openEntity(referenceType, referenceId);
      return;
    }

    // 4. Anything else → the in-app notifications list.
    _openNotificationsScreen(context);
  }

  void _openNotificationsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openFollowerProfile(
    BuildContext context,
    String followerId,
  ) async {
    try {
      final profile = await ProfileService().getUserProfile(followerId);
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      final user = profile['user'] as Map<String, dynamic>?;
      final accountType = user?['account_type']?.toString().toLowerCase() ?? '';
      final isPro = accountType == 'pro' || accountType == 'professionnel';
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => isPro
              ? ProPublicViewScreen(userId: followerId)
              : ParticulierPublicViewScreen(userId: followerId),
        ),
      );
    } catch (e) {
      print('❌ Failed to open follower profile: $e');
    }
  }

  /// Encode FCM data into a "key=value&key=value" payload (values URL-encoded).
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  /// Decode a "key=value&key=value" payload (values are URL-encoded).
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      final key = pair.substring(0, i);
      final value = pair.substring(i + 1);
      map[key] = Uri.decodeComponent(value);
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
