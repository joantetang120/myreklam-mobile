import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/chat_message.dart';

class ApiChatService {
  static const _storage = FlutterSecureStorage();

  // Récupérer les messages d'une conversation
  Future<List<ChatMessage>> getMessages(int conversationId, int currentUserId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = (data['data'] as List)
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
  Future<ChatMessage> sendMessage(int conversationId, String text, int currentUserId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': text}),
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

  // Marquer les messages comme lus
  Future<void> markAsRead(int conversationId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
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
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] as int?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
}
