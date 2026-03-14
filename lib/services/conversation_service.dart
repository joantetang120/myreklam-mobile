import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/chat_conversation.dart';

class ConversationService {
  static const _storage = FlutterSecureStorage();

  // Récupérer toutes les conversations de l'utilisateur
  Future<List<ChatConversation>> getConversations() async {
    try {
      final token = await _storage.read(key: 'auth_token');
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
            .map((conv) => ChatConversation.fromJson(conv))
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
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'other_user_id': otherUserId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatConversation.fromJson(data['data']);
      } else {
        throw Exception(
          'Failed to create conversation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error creating conversation: $e');
      rethrow;
    }
  }

  // Supprimer une conversation
  Future<void> deleteConversation(int conversationId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
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
