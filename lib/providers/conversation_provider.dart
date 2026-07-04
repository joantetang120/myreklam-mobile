import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:myreklam/models/chat_message.dart';
import 'package:myreklam/services/chat_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/message_database.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';

class ConversationProvider extends ChangeNotifier {
  final ConversationService _chatService = ConversationService();
  final MessageDatabase _db = MessageDatabase.instance;
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

      // 1. Récupérer l'ID utilisateur actuel (toujours frais pour éviter le cache multi-comptes)
      print("DEBUG: Getting current user ID...");
      _currentUserId = await _chatService.getCurrentUserId();
      print("DEBUG: Current user ID: $_currentUserId");

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // 2. Charger les messages depuis le cache local d'abord (offline support)
      print("DEBUG: Loading messages from local cache...");
      final cachedMessages = await _db.getMessages(
        conversationId,
        _currentUserId!,
      );
      if (cachedMessages.isNotEmpty) {
        _messagesByConversation[conversationId] = cachedMessages;
        _isLoading = false;
        notifyListeners();
        print("DEBUG: Loaded ${cachedMessages.length} cached messages");
      }

      // 3. Charger les messages depuis l'API (sync avec backend)
      print("DEBUG: Fetching messages from API...");
      try {
        final messages = await _chatService.getMessages(
          conversationId,
          _currentUserId!,
        );
        print("DEBUG: Got ${messages.length} messages from API");

        // 4. Sauvegarder dans la base locale
        await _db.saveMessages(messages, conversationId, _currentUserId!);
        _messagesByConversation[conversationId] = messages;
      } catch (e) {
        print("DEBUG: API fetch failed, using cached messages: $e");
        // Si l'API échoue, on garde les messages en cache
        if (cachedMessages.isEmpty) rethrow;
      }

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
  Future<void> _onNewMessage(int conversationId, dynamic messageData) async {
    try {
      print("DEBUG: Processing new message for conversation $conversationId");

      // Convertir les données dynamiques en Map<String, dynamic>
      final Map<String, dynamic> messageMap = Map<String, dynamic>.from(
        messageData,
      );

      // Parser le message
      final message = ChatMessage.fromJson(messageMap, _currentUserId!);

      // Skip own messages - sendMessage() already adds them locally
      if (message.senderId == _currentUserId) {
        print("DEBUG: Skipping own message ${message.id} from WebSocket");
        return;
      }

      // Vérifier si le message n'existe pas déjà
      final existingMessages = _messagesByConversation[conversationId] ?? [];
      final alreadyExists = existingMessages.any((msg) => msg.id == message.id);

      if (alreadyExists) {
        print("DEBUG: Message ${message.id} already exists, skipping");
        return;
      }

      // Sauvegarder le nouveau message dans la DB locale
      await _db.saveMessage(message, _currentUserId!);

      // Ajouter à la liste en mémoire
      _addMessageToList(conversationId, message);

      // Notifier les listeners pour mettre à jour l'UI
      notifyListeners();

      print("DEBUG: New message ${message.id} processed and UI updated");

      // Refresh global chat unread count in bottom bar
      CustomBottomBar.refreshChatNotifier.value =
          !CustomBottomBar.refreshChatNotifier.value;
    } catch (e) {
      print('❌ Error handling new message: $e');
    }
  }

  // Envoyer un message
  Future<void> sendMessage(
    int conversationId,
    String text, {
    Map<String, dynamic>? attachments,
  }) async {
    try {
      _currentUserId ??= await _chatService.getCurrentUserId();

      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Sauvegarder le message en attente localement (pour offline)
      await _db.savePendingMessage(conversationId, text, _currentUserId!, null);

      // 2. Appel API pour envoyer le message
      try {
        final newMessage = await _chatService.sendMessage(
          conversationId,
          text,
          _currentUserId!,
          attachments: attachments,
        );

        // 3. Supprimer le message en attente et sauvegarder le vrai message
        final pendingMessages = await _db.getPendingMessages(conversationId);
        for (final pending in pendingMessages) {
          if (pending['text'] == text) {
            await _db.deletePendingMessage(pending['id'] as int);
          }
        }
        await _db.saveMessage(newMessage, _currentUserId!);

        // 4. Ajouter le message localement
        final readMessage = newMessage.copyWith(isRead: false);
        _addMessageToList(conversationId, readMessage);

        notifyListeners();
      } catch (e) {
        print('❌ Failed to send message, will retry when online: $e');
        // Le message reste en attente dans la DB locale
        rethrow;
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Modifier un message
  Future<void> editMessage(
    int conversationId,
    int messageId,
    String newText,
  ) async {
    try {
      _currentUserId ??= await _chatService.getCurrentUserId();
      if (_currentUserId == null) throw Exception('User not authenticated');

      await _chatService.editMessage(
        conversationId,
        messageId,
        newText,
        _currentUserId!,
      );

      // Mettre à jour le message localement
      final messages = _messagesByConversation[conversationId];
      if (messages != null) {
        final index = messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            text: newText,
            isEdited: true,
            editedAt: DateTime.now(),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error editing message: $e');
      rethrow;
    }
  }

  // Supprimer un message
  Future<void> deleteMessage(
    int conversationId,
    int messageId,
    String deleteType,
  ) async {
    try {
      _currentUserId ??= await _chatService.getCurrentUserId();
      if (_currentUserId == null) throw Exception('User not authenticated');

      await _chatService.deleteMessage(conversationId, messageId, deleteType);

      // Mettre à jour le message localement
      final messages = _messagesByConversation[conversationId];
      if (messages != null) {
        final index = messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          if (deleteType == 'for_everyone') {
            messages[index] = messages[index].copyWith(
              deletedForEveryone: true,
              text: '',
            );
          } else {
            // Supprimer pour moi: retirer de la liste locale
            messages.removeAt(index);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting message: $e');
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

        // Refresh global chat unread count in bottom bar
        CustomBottomBar.refreshChatNotifier.value =
            !CustomBottomBar.refreshChatNotifier.value;

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

  // Ajouter un message à la liste (avec déduplication)
  void _addMessageToList(int conversationId, ChatMessage message) {
    if (!_messagesByConversation.containsKey(conversationId)) {
      _messagesByConversation[conversationId] = [];
    }
    // Déduplication: ne pas ajouter si le message existe déjà
    final alreadyExists = _messagesByConversation[conversationId]!.any(
      (msg) => msg.id == message.id,
    );
    if (alreadyExists) {
      print("DEBUG: Message ${message.id} already in list, skipping add");
      return;
    }
    _messagesByConversation[conversationId]!.add(message);
    print("DEBUG: Message ${message.id} added to conversation $conversationId");
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
