import 'package:myreklam/services/push_notification_service.dart';

/// Chat-specific notification helper.
///
/// Local notifications (the plugin, the Android channel and tap routing) are
/// owned by [PushNotificationService]. This class only decides *whether* a chat
/// notification should be shown and builds the chat routing payload, then
/// delegates the actual display to the shared service. This avoids two plugins
/// initialising the same channel and registering competing tap handlers.
class ChatNotificationService {
  ChatNotificationService._();
  static final ChatNotificationService instance = ChatNotificationService._();

  /// Kept for backwards compatibility with existing call sites. The shared
  /// [PushNotificationService] performs the real initialisation in `main()`.
  Future<void> init() async {
    // No-op: local notifications are initialised by PushNotificationService.
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? conversationId,
  }) async {
    print('🔔 Affichage notification chat: De $senderName / $conversationId');

    // Build a routing payload consumed by PushNotificationService's tap handler.
    final parts = <String>['type=chat'];
    if (conversationId != null && conversationId.isNotEmpty) {
      parts.add('conversation_id=${Uri.encodeComponent(conversationId)}');
    }
    parts.add('name=${Uri.encodeComponent(senderName)}');

    await PushNotificationService.instance.showLocalNotification(
      title: senderName,
      body: message,
      payload: parts.join('&'),
    );
  }

  /// Decide whether to show a notification.
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
    //   return false;
    // }

    return true;
  }

  /// Show a chat notification only when [shouldShowNotification] allows it.
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
