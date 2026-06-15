import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/utils/user_session.dart';

class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Upload a new story (multipart image/video + optional caption + optional overlay text).
  Future<StoryModel?> uploadStory({
    required Uint8List mediaBytes,
    required String fileName,
    String? caption,
    String? overlayText,
    String? overlayColor,
    int? overlayStyle,
    double? overlayX,
    double? overlayY,
    String mediaType = 'image',
    List<int> mentions = const [],
    String? overlaysJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/stories');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _authHeaders();
      request.headers.addAll(headers);

      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          mediaBytes,
          filename: fileName.isNotEmpty
              ? fileName
              : 'story_${DateTime.now().millisecondsSinceEpoch}.$mediaType',
        ),
      );

      // Add media_type field for the backend
      request.fields['media_type'] = mediaType;

      if (caption != null && caption.trim().isNotEmpty) {
        request.fields['caption'] = caption.trim();
      }

      if (overlayText != null && overlayText.trim().isNotEmpty) {
        request.fields['overlay_text'] = overlayText.trim();
        if (overlayColor != null) {
          request.fields['overlay_color'] = overlayColor;
        }
        if (overlayStyle != null) {
          request.fields['overlay_style'] = overlayStyle.toString();
        }
        if (overlayX != null) {
          request.fields['overlay_x'] = overlayX.toString();
        }
        if (overlayY != null) {
          request.fields['overlay_y'] = overlayY.toString();
        }
      }

      // Mentioned user ids — indexed keys so Laravel parses them as an array.
      for (var i = 0; i < mentions.length; i++) {
        request.fields['mentions[$i]'] = mentions[i].toString();
      }

      // Structured overlays (stickers, drawing, location) as a JSON string.
      if (overlaysJson != null && overlaysJson.isNotEmpty && overlaysJson != '[]') {
        request.fields['overlays'] = overlaysJson;
      }

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Story upload status: ${response.statusCode}');
      debugPrint('Story upload body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return StoryModel.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading story: $e');
      return null;
    }
  }

  /// Get the story feed (all active stories grouped by user).
  Future<List<StoryUserGroup>> getFeed() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/stories/feed'), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final groups = (body['data'] as List)
              .map((g) => StoryUserGroup.fromJson(g as Map<String, dynamic>))
              .toList();
          for (final group in groups) {
            group.stories.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }
          return groups;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching story feed: $e');
      return [];
    }
  }

  /// Get current user's stories with viewer details.
  Future<List<StoryModel>> getMyStories() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/stories/mine'), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final list = (body['data'] as List)
              .map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching my stories: $e');
      return [];
    }
  }

  /// Record a view on a story.
  Future<int?> recordView(int storyId) async {
    try {
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/stories/$storyId/view'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['views_count'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Error recording story view: $e');
      return null;
    }
  }

  /// Like a story. Returns the new likes_count, or null on failure.
  Future<int?> likeStory(int storyId) async {
    try {
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/stories/$storyId/like'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['likes_count'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Error liking story: $e');
      return null;
    }
  }

  /// Remove a like from a story. Returns the new likes_count, or null on failure.
  Future<int?> unlikeStory(int storyId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/stories/$storyId/like'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['likes_count'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Error unliking story: $e');
      return null;
    }
  }

  /// Get the current user's followers (candidates for @-mentions).
  Future<List<MentionUser>> getMyFollowers() async {
    try {
      final myId = UserSession().id;
      if (myId == null || myId.isEmpty) return [];

      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/profile/$myId/followers'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return (body['data'] as List)
              .map((u) => MentionUser.fromFollowerJson(u as Map<String, dynamic>))
              .where((u) => u.id > 0)
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching followers: $e');
      return [];
    }
  }

  /// Get viewers list for a story (owner only).
  Future<List<StoryViewer>> getViewers(int storyId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/stories/$storyId/viewers'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return (body['data'] as List)
              .map((v) => StoryViewer.fromJson(v as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching story viewers: $e');
      return [];
    }
  }

  /// Get which users' stories have been fully viewed by current user.
  Future<List<int>> getFullyViewedUserIds() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/stories/viewed-status'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final userIds = body['data']['fully_viewed_user_ids'] as List;
          return userIds
              .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching viewed status: $e');
      return [];
    }
  }

  /// Delete a story.
  Future<bool> deleteStory(int storyId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/stories/$storyId'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Error deleting story: $e');
      return false;
    }
  }
}
