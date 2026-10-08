import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myreklam/firebase_options.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/notification_preferences_screen.dart';
import 'package:myreklam/screens/pro_subscription_screen.dart';
import 'package:myreklam/screens/settings_screen.dart';
import 'package:myreklam/screens/reels_screen.dart';
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
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  late final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'myreklam_notifications';
  static const _channelName = 'Myreklam Notifications';

  String? _fcmToken;
  Map<String, dynamic>? _pendingNavigationData;
  Timer? _navigationRetry;

  /// Initialize push notifications (Firebase must already be initialized)
  Future<void> init() async {
    debugPrint('🔔 Initializing PushNotificationService...');

    // Firebase is already initialized in main(), just get the instance
    _messaging = FirebaseMessaging.instance;

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS)
    await _requestPermission();

    // Initialize local notifications for foreground messages
    await _initLocalNotifications();

    // Get FCM token (with error handling for simulator or unconfigured devices)
    try {
      // On iOS, wait for APNS token first — getToken() throws if APNS isn't ready
      if (Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 5; i++) {
          try {
            apnsToken = await _messaging.getAPNSToken();
          } catch (_) {}
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          debugPrint(
            '🔔 APNS not available (simulator or APNS not configured) — skipping FCM token',
          );
          _setupMessageHandlers();
          debugPrint('✅ PushNotificationService initialized (no FCM token)');
          return;
        }
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('🔔 FCM Token: ${_fcmToken!.substring(0, 30)}...');
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('🔔 Push notifications not available: $e');
      debugPrint(
        '   (This is normal on simulator or if APNS is not configured)',
      );
    }

    _setupMessageHandlers();

    debugPrint('✅ PushNotificationService initialized');
  }

  /// Wire up token-refresh and message listeners (safe to call even without FCM token)
  void _setupMessageHandlers() {
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('🔔 FCM Token refreshed');
      _fcmToken = token;
      _registerTokenWithBackend(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _messaging.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) _handleMessageOpenedApp(initialMessage);
    });
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔔 iOS permission status: ${settings.authorizationStatus}');
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
            AndroidFlutterLocalNotificationsPlugin
          >()
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
      await ApiClient().authenticatedPost(
        '/push-tokens',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      debugPrint('🔔 FCM token registered with backend');
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
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
      debugPrint('❌ registerToken failed: $e');
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
      await ApiClient().authenticatedDelete(
        '/push-tokens',
        body: {'token': _fcmToken},
      );
      debugPrint('🔔 FCM token unregistered from backend');
    } catch (e) {
      debugPrint('❌ Failed to unregister FCM token: $e');
    }
  }

  /// Handle foreground message (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (_isChatNotification(message.data)) {
      _incrementChatCount();
      refreshChatCount();
    }
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
    if (_isChatNotification(message.data)) {
      refreshChatCount();
    }
    debugPrint('🔔 Message opened app: ${message.notification?.title}');
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

  /// Reuses the exact same routing for an item opened from the in-app center.
  void openNotificationData(Map<String, dynamic> data) {
    _navigateFromData(data);
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
      _pendingNavigationData = Map<String, dynamic>.from(data);
      _schedulePendingNavigation();
      return;
    }
    _pendingNavigationData = null;

    final type = (data['type'] ?? '').toString().toLowerCase();
    final referenceType = (data['reference_type'] ?? data['ref_type'] ?? '')
        .toString();
    final referenceId =
        (data['reference_id'] ?? data['ref_id'] ?? data['id'] ?? '').toString();

    final notificationId = data['notification_id']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      unawaited(_markNotificationAsRead(notificationId));
    }

    debugPrint(
      '🔔 Navigating from notification: type=$type, ref=$referenceType, id=$referenceId',
    );

    // 1. Chat message → open the conversation.
    if ({
      'chat',
      'new_message',
      'message_received',
      'direct_message_received',
      'message_request_received',
      'conversation_mentioned',
      'unread_messages_reminder',
    }.contains(type)) {
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
    if (type == 'new_follower' || type == 'follow_request_received') {
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

    final target =
        (data['link'] ?? data['target_url'] ?? data['deep_link'] ?? '')
            .toString();
    if (_openTargetLink(context, target)) return;

    // 4. Anything else → the in-app notifications list.
    _openNotificationsScreen(context);
  }

  bool _openTargetLink(BuildContext context, String target) {
    if (target.isEmpty) return false;

    final uri = Uri.tryParse(target);
    if (uri == null) return false;
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.isEmpty) return false;

    final entityRoutes = <String>{
      'bons-plans',
      'offres-emploi',
      'emplois',
      'formations',
      'evenements',
      'demandes',
      'publications',
      'stories',
      'reels',
    };
    if (segments.length >= 2 && entityRoutes.contains(segments.first)) {
      unawaited(
        DeepLinkService.instance.openEntity(segments.first, segments[1]),
      );
      return true;
    }

    if (segments.first == 'reels') {
      final reelId =
          uri.queryParameters['reel'] ??
          (segments.length >= 2 ? segments[1] : null);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReelsScreen(initialReelId: reelId)),
      );
      return true;
    }

    if (segments.first == 'profil' && segments.length >= 2) {
      unawaited(_openFollowerProfile(context, segments[1]));
      return true;
    }

    if (segments.contains('abonnement')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProSubscriptionScreen()),
      );
      return true;
    }

    if (segments.contains('notifications') && segments.contains('parametres')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationPreferencesScreen(),
        ),
      );
      return true;
    }

    if (segments.contains('parametres')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return true;
    }

    return false;
  }

  void _schedulePendingNavigation() {
    if (_navigationRetry?.isActive == true) return;
    var attempts = 0;
    _navigationRetry = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      attempts++;
      final pending = _pendingNavigationData;
      if (pending == null || attempts >= 40) {
        timer.cancel();
        return;
      }
      if (navigatorKey.currentContext != null) {
        timer.cancel();
        _navigateFromData(pending);
      }
    });
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await ApiClient().authenticatedPut(
        '/notifications/$notificationId/read',
        body: const {},
      );
      refreshNotificationCount();
    } catch (e) {
      debugPrint('Unable to mark notification as read: $e');
    }
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
      debugPrint('❌ Failed to open follower profile: $e');
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

  bool _isChatNotification(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event_key'] ?? '')
        .toString()
        .toLowerCase();
    final referenceType = (data['reference_type'] ?? data['ref_type'] ?? '')
        .toString()
        .toLowerCase();

    return {
          'chat',
          'new_message',
          'message_received',
          'direct_message_received',
          'message_request_received',
          'conversation_mentioned',
          'unread_messages_reminder',
        }.contains(type) ||
        {'chat', 'conversation', 'message'}.contains(referenceType) ||
        data.containsKey('conversation_id') ||
        data.containsKey('conversationId');
  }

  void _incrementChatCount() {
    CustomBottomBar.chatCountNotifier.value =
        CustomBottomBar.chatCountNotifier.value + 1;
  }

  void refreshChatCount() {
    CustomBottomBar.refreshChatNotifier.value =
        !CustomBottomBar.refreshChatNotifier.value;
  }

  /// Refresh notification count from backend (call when app comes to foreground)
  void refreshNotificationCount() {
    CustomBottomBar.refreshNotificationNotifier.value =
        !CustomBottomBar.refreshNotificationNotifier.value;
  }
}
