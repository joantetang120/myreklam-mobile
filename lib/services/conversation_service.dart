import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/chat_conversation.dart';
import 'package:myreklam/models/chat_message.dart';
import 'package:myreklam/services/token_storage.dart';

class ConversationService {
  // Récupérer les messages d'une conversation
  Future<List<ChatMessage>> getMessages(
    int conversationId,
    int currentUserId,
  ) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/conversations/$conversationId/messages',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("DEBUG: API Response structure: ${data.runtimeType}");
        print("DEBUG: Full response: $data");

        // Gérer la réponse paginée Laravel
        List<dynamic> messagesList;

        // Vérifier la structure de la réponse avec plus de sécurité
        if (data is Map<String, dynamic>) {
          if (data['data'] != null) {
            if (data['data'] is Map<String, dynamic> &&
                data['data']['data'] is List) {
              // Structure paginée Laravel: {success: true, data: {data: [...], ...}}
              messagesList = data['data']['data'] as List<dynamic>;
            } else if (data['data'] is List) {
              // Structure simple: {data: [...]}
              messagesList = data['data'] as List<dynamic>;
            } else {
              throw Exception('Unexpected data structure in data field');
            }
          } else if (data['messages'] is List) {
            // Alternative: {messages: [...]}
            messagesList = data['messages'] as List<dynamic>;
          } else {
            throw Exception('No messages found in response');
          }
        } else if (data is List) {
          // Direct list: [...]
          messagesList = data as List<dynamic>;
        } else {
          throw Exception(
            'Unexpected API response structure: ${data.runtimeType}',
          );
        }

        print("DEBUG: Found ${messagesList.length} messages");
        final messages = messagesList
            .map((msg) => ChatMessage.fromJson(msg, currentUserId))
            .toList();
        return messages;
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      rethrow;
    }
  }

  // Envoyer un message
  Future<ChatMessage> sendMessage(
    int conversationId,
    String text,
    int currentUserId, {
    Map<String, dynamic>? attachments,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final body = <String, dynamic>{'text': text};
      if (attachments != null) body['attachments'] = attachments;
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/conversations/$conversationId/messages',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data['data'], currentUserId);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  // Modifier un message
  Future<ChatMessage> editMessage(
    int conversationId,
    int messageId,
    String newText,
    int currentUserId,
  ) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/conversations/$conversationId/messages/$messageId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': newText}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data['data'], currentUserId);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to edit message');
      }
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
      final token = await TokenStorage.getAccessToken();
      final request = http.Request(
        'DELETE',
        Uri.parse(
          '${ApiConfig.baseUrl}/conversations/$conversationId/messages/$messageId',
        ),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
      request.body = json.encode({'type': deleteType});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete message');
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // Marquer les messages comme lus
  Future<void> markAsRead(int conversationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
      rethrow;
    }
  }

  // Récupérer l'ID de l'utilisateur actuel
  Future<int?> getCurrentUserId() async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return int.tryParse(data['user']['id']);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Récupérer toutes les conversations de l'utilisateur
  Future<List<ChatConversation>> getConversations({int? currentUserId}) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final conversations = (data['data'] as List)
            .map(
              (conv) =>
                  ChatConversation.fromJson(conv, currentUserId: currentUserId),
            )
            .toList();
        return conversations;
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading conversations: $e');
      rethrow;
    }
  }

  // Créer ou récupérer une conversation avec un utilisateur
  Future<ChatConversation> getOrCreateConversation(int otherUserId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'partner_id': otherUserId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Pour getOrCreate, on ne connaît pas le currentUserId ici, donc on ne le passe pas
        // La logique par défaut sera utilisée (partner comme autre utilisateur)
        return ChatConversation.fromJson(data['data']);
      } else {
        // Extract error message from API response
        String errorMessage = 'Échec de la création de la conversation';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } catch (_) {
          // If JSON parsing fails, use default message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete conversation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      rethrow;
    }
  }
}
