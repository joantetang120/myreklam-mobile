import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:myreklam/models/chat_message.dart';
import 'package:myreklam/services/chat_service.dart';
import 'package:myreklam/services/conversation_service.dart';

class ConversationProvider extends ChangeNotifier {
  final ConversationService _chatService = ConversationService();
  final Map<int, List<ChatMessage>> _messagesByConversation = {};
  int? _currentUserId;
  bool _isLoading = false;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  List<ChatMessage> getMessages(int conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  bool get isLoading => _isLoading;

  // Charger les messages d'une conversation
  Future<void> loadMessages(int conversationId) async {
    try {
      print("DEBUG: Setting loading to true");
      _isLoading = true;
      notifyListeners();

      // 1. Récupérer l'ID utilisateur actuel
      print("DEBUG: Getting current user ID...");
      _currentUserId ??= await _chatService.getCurrentUserId();
      print("DEBUG: Current user ID: $_currentUserId");

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // 2. Charger les messages depuis l'API
      print("DEBUG: Fetching messages from API...");
      final messages = await _chatService.getMessages(
        conversationId,
        _currentUserId!,
      );
      print("DEBUG: Got ${messages.length} messages");
      _messagesByConversation[conversationId] = messages;

      // 3. S'abonner au WebSocket pour les nouveaux messages
      print("DEBUG: Subscribing to WebSocket...");
      try {
        await ChatService.subscribeToConversation(conversationId.toString());
        print("DEBUG: WebSocket subscription successful");

        // Configurer l'écoute des messages (une seule fois pour toute l'app)
        _setupMessageListener();
      } catch (e) {
        print("DEBUG: WebSocket subscription failed: $e");
        // Continuer même si WebSocket échoue
      }

      // 4. Marquer les messages comme lus
      print("DEBUG: Marking messages as read...");
      try {
        await markAsRead(conversationId);
        print("DEBUG: Messages marked as read");
      } catch (e) {
        print("DEBUG: Failed to mark as read: $e");
        // Continuer même si markAsRead échoue
      }

      print("DEBUG: Setting loading to false");
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
  void _onNewMessage(int conversationId, dynamic messageData) {
    try {
      print("DEBUG: Processing new message for conversation $conversationId");

      // Convertir les données dynamiques en Map<String, dynamic>
      final Map<String, dynamic> messageMap = Map<String, dynamic>.from(
        messageData,
      );

      // Parser le message
      final message = ChatMessage.fromJson(messageMap, _currentUserId!);

      // Vérifier si le message n'existe pas déjà
      final existingMessages = _messagesByConversation[conversationId] ?? [];
      final alreadyExists = existingMessages.any((msg) => msg.id == message.id);

      if (alreadyExists) {
        print("DEBUG: Message ${message.id} already exists, skipping");
        return;
      }

      // Notifier les listeners pour mettre à jour l'UI
      notifyListeners();

      print("DEBUG: New message ${message.id} processed and UI updated");
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
      final readMessage = newMessage.copyWith(isRead: false);
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

  // Configurer l'écoute des messages WebSocket (une seule fois)
  void _setupMessageListener() {
    if (_messageSubscription != null) return; // Déjà configuré

    print("DEBUG: Setting up message listener...");
    _messageSubscription = ChatService.messageStream.listen((data) {
      print("DEBUG: Received WebSocket data: $data");

      if (data['type'] == 'status_update') {
        // Mise à jour de statut de message
        print("DEBUG: Status update received");
        notifyListeners();
        return;
      }

      final conversationIdStr = data['conversationId']?.toString();
      if (conversationIdStr == null) return;

      final conversationId = int.tryParse(conversationIdStr);
      if (conversationId == null) return;

      final messageData = data['message'];
      final senderData = data['sender'];
      if (messageData == null) return;

      print("DEBUG: New message for conversation $conversationId");
      // Combiner les données du message et de l'expéditeur
      final fullMessageData = {...messageData, 'sender': senderData};
      _onNewMessage(conversationId, fullMessageData);
    });
  }

  // Ajouter un message à la liste
  void _addMessageToList(int conversationId, ChatMessage message) {
    if (!_messagesByConversation.containsKey(conversationId)) {
      _messagesByConversation[conversationId] = [];
    }
    _messagesByConversation[conversationId]!.add(message);
    print("DEBUG: Message added to conversation $conversationId");
  }

  // Se désabonner d'une conversation
  Future<void> unsubscribeFromConversation(int conversationId) async {
    try {
      await ChatService.unsubscribeFromConversation(conversationId.toString());
    } catch (e) {
      print('❌ Error unsubscribing from conversation: $e');
    }
  }

  // Nettoyer les messages d'une conversation
  void clearMessages(int conversationId) {
    _messagesByConversation.remove(conversationId);
    notifyListeners();
  }

  @override
  void dispose() {
    // Nettoyer l'écoute des messages WebSocket
    _messageSubscription?.cancel();
    _messageSubscription = null;

    // Nettoyer toutes les souscriptions WebSocket
    _messagesByConversation.keys.forEach((conversationId) {
      ChatService.unsubscribeFromConversation(conversationId.toString());
    });

    print("DEBUG: ConversationProvider disposed");
    super.dispose();
  }
}
