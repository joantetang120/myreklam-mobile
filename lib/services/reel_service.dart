import 'dart:io';

import 'package:myreklam/models/reel_model.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/models/social_video.dart';

class ReelService {
  final ApiClient _api;
  ReelService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<ReelModel>> getReels({int page = 1, int limit = 100}) async {
    final response = await _api.get(
      '/feed/latest?type=post&page=$page&limit=$limit',
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    final items = List<dynamic>.from(data['items'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map((item) => ReelModel.fromFeedItem(Map<String, dynamic>.from(item)))
        .whereType<ReelModel>()
        .toList();
  }

  Future<void> refreshReaction(ReelModel reel) async {
    final response = await _api.authenticatedGet('/posts/${reel.id}/reactions');
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    reel.likesCount = _int(data['likes_count']);
    reel.isLiked = data['user_reaction']?.toString() == 'like';
  }

  Future<void> toggleLike(ReelModel reel) async {
    final response = await _api.authenticatedPost(
      '/posts/${reel.id}/reactions',
      body: const {'type': 'like'},
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    reel.likesCount = _int(data['likes_count']);
    reel.isLiked = data['user_reaction']?.toString() == 'like';
  }

  Future<List<Map<String, dynamic>>> comments(String reelId) async {
    final response = await _api.authenticatedGet(
      '/posts/$reelId/comments?per_page=50',
    );
    final data = response['data'];
    final list = data is Map ? data['data'] : data;
    return List<dynamic>.from(
      list as List? ?? const [],
    ).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> addComment(String reelId, String body) async {
    final response = await _api.authenticatedPost(
      '/posts/$reelId/comments',
      body: {'body': body},
    );
    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  Future<String> publish({
    File? video,
    String? videoLink,
    required String caption,
    String visibility = 'public',
  }) async {
    final external = videoLink == null ? null : SocialVideo.parse(videoLink);
    if ((video == null && external == null) ||
        (video != null && external != null)) {
      throw ArgumentError('Choisissez une vidéo ou un lien vidéo valide.');
    }
    final created = await _api.authenticatedPost(
      '/posts',
      body: {
        'content': external != null
            ? [
                caption.trim(),
                external.url,
              ].where((s) => s.isNotEmpty).join('\n\n')
            : caption.trim().isEmpty
            ? 'Reel partagé sur MyReklam'
            : caption.trim(),
        'visibility': visibility,
      },
    );
    final id = created['data']?['id']?.toString();
    if (id == null || id.isEmpty)
      throw ApiException(
        statusCode: 500,
        message: 'Le Reel n’a pas pu être créé.',
      );
    try {
      if (external != null) return id;
      await _api.authenticatedMultipartMultiple(
        '/posts/$id/media',
        files: [video!],
        fileField: 'files',
      );
      return id;
    } catch (_) {
      try {
        await _api.authenticatedDelete('/posts/$id');
      } catch (_) {}
      rethrow;
    }
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
