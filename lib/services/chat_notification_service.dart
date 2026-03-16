import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class ChatNotificationService {
  ChatNotificationService._();
  static final ChatNotificationService instance = ChatNotificationService._();

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'myreklam_notifications';
  static const _channelName = 'Myreklam Notifications';

  Future<void> init() async {
    print('🔔 Initialisation ChatNotificationService...');

    // Initialiser les notifications locales
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Créer le canal Android
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
            ),
          );
    }

    // Demander la permission
    await _localPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    print('✅ ChatNotificationService initialisé');
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? conversationId,
  }) async {
    print('🔔 Affichage notification chat:');
    print('   De: $senderName');
    print('   Message: $message');
    print('   Conversation: $conversationId');

    await _showNotification('$senderName', message, conversationId);
  }

  // Gérer le clic sur une notification locale
  void _onNotificationTap(NotificationResponse notificationResponse) {
    if (notificationResponse.payload?.startsWith('chat_') == true) {
      final conversationId = notificationResponse.payload!.replaceFirst(
        'chat_',
        '',
      );
      print('🔔 Notification locale cliquée - Conversation: $conversationId');
      _navigateToConversation(conversationId);
    }
  }

  // Naviguer vers une conversation
  void _navigateToConversation(String conversationId) {
    print('🔔 Navigation vers la conversation: $conversationId');

    // Utiliser le navigatorKey global pour naviguer depuis n'importe où
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(
        ParticulierMainScreen.routeName,
        arguments: {
          'initialIndex': 1, // Index de l'onglet messages
          'conversationId': conversationId,
        },
      );
    } else {
      print('❌ Context non disponible pour la navigation');
    }
  }

  // Afficher une notification locale (méthode unique)
  Future<void> _showNotification(
    String title,
    String body,
    String? conversationId,
  ) async {
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
      payload: conversationId != null ? 'chat_$conversationId' : null,
    );
  }

  // Décider si afficher une notification
  bool shouldShowNotification({
    required int currentUserId,
    required int senderId,
    String? currentConversationId,
  }) {
    // Ne pas afficher de notification pour ses propres messages
    if (senderId == currentUserId) {
      print('🔔 Notification ignorée - Mon propre message');
      return false;
    }

    // Ne pas afficher si l'utilisateur est déjà dans la conversation
    // TODO: Implémenter la détection de la conversation active
    // if (currentConversationId != null) {
    //   print('🔔 Notification ignorée - Utilisateur dans la conversation');
    //   return false;
    // }

    return true;
  }

  // Version améliorée avec logique de décision
  Future<void> showSmartNotification({
    required String senderName,
    required String message,
    String? conversationId,
    required int currentUserId,
    required int senderId,
    String? currentConversationId,
  }) async {
    if (shouldShowNotification(
      currentUserId: currentUserId,
      senderId: senderId,
      currentConversationId: currentConversationId,
    )) {
      await showMessageNotification(
        senderName: senderName,
        message: message,
        conversationId: conversationId,
      );
    }
  }
}
