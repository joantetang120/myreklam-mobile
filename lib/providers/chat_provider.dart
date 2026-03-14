import 'package:flutter/foundation.dart';
import 'package:myreklam/models/chat_message.dart';
import 'package:myreklam/services/api_chat_service.dart';
import 'package:myreklam/services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiChatService _chatService = ApiChatService();
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  int? _currentUserId;
  bool _isLoading = false;

  List<ChatMessage> getMessages(int conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  bool get isLoading => _isLoading;

  // Charger les messages d'une conversation
  Future<void> loadMessages(int conversationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Récupérer l'ID utilisateur actuel
      _currentUserId ??= await _chatService.getCurrentUserId();

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // 2. Charger les messages depuis l'API
      final messages = await _chatService.getMessages(
        conversationId,
        _currentUserId!,
      );
      _messagesByConversation[conversationId] = messages;

      // 3. S'abonner au WebSocket pour les nouveaux messages
      await WebSocketService.subscribeToConversation(
        conversationId.toString(),
        (data) => _onNewMessage(conversationId, data),
      );

      // 4. Marquer les messages comme lus
      await markAsRead(conversationId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading messages: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Callback pour les nouveaux messages via WebSocket
  void _onNewMessage(int conversationId, Map<String, dynamic> data) {
    try {
      if (_currentUserId == null) return;

      final newMessage = ChatMessage.fromJson(data, _currentUserId!);

      // Si c'est notre propre message, il est déjà dans la liste (ajouté par sendMessage)
      // On vérifie pour éviter les doublons
      final messages = _messagesByConversation[conversationId] ?? [];
      final exists = messages.any((msg) => msg.id == newMessage.id);

      if (!exists) {
        // Messages reçus des autres utilisateurs
        _addMessageToList(conversationId, newMessage);
        notifyListeners();
      } else {
        // Mettre à jour le message existant (pour le statut isRead par exemple)
        final index = messages.indexWhere((msg) => msg.id == newMessage.id);
        if (index != -1) {
          messages[index] = newMessage;
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error handling new message: $e');
    }
  }

  // Envoyer un message
  Future<void> sendMessage(int conversationId, String text) async {
    try {
      if (_currentUserId == null) {
        _currentUserId = await _chatService.getCurrentUserId();
      }

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Appel API pour envoyer le message
      final newMessage = await _chatService.sendMessage(
        conversationId,
        text,
        _currentUserId!,
      );

      // 2. Ajouter le message localement avec statut lu (nos propres messages sont lus)
      final readMessage = newMessage.copyWith(isRead: true);
      _addMessageToList(conversationId, readMessage);

      notifyListeners();
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Marquer les messages comme lus
  Future<void> markAsRead(int conversationId) async {
    try {
      // 1. Appel API
      await _chatService.markAsRead(conversationId);

      // 2. Mise à jour locale de tous les messages non lus
      if (_messagesByConversation.containsKey(conversationId)) {
        final messages = _messagesByConversation[conversationId]!;
        _messagesByConversation[conversationId] = messages
            .map((msg) => msg.isMe ? msg : msg.copyWith(isRead: true))
            .toList();

        notifyListeners();
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  // Ajouter un message à la liste
  void _addMessageToList(int conversationId, ChatMessage message) {
    if (!_messagesByConversation.containsKey(conversationId)) {
      _messagesByConversation[conversationId] = [];
    }
    _messagesByConversation[conversationId]!.add(message);
  }

  // Se désabonner d'une conversation
  Future<void> unsubscribeFromConversation(int conversationId) async {
    await WebSocketService.unsubscribeFromConversation(
      conversationId.toString(),
    );
  }

  // Nettoyer les messages d'une conversation
  void clearMessages(int conversationId) {
    _messagesByConversation.remove(conversationId);
    notifyListeners();
  }

  @override
  void dispose() {
    // Nettoyer toutes les souscriptions WebSocket
    _messagesByConversation.keys.forEach((conversationId) {
      WebSocketService.unsubscribeFromConversation(conversationId.toString());
    });
    super.dispose();
  }
}
