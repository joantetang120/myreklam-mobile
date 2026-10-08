import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/social_video.dart';

class ReelModel {
  final String id;
  final String videoUrl;
  final String caption;
  final String authorName;
  final String? authorAvatar;
  int likesCount;
  int commentsCount;
  bool isLiked;

  ReelModel({
    required this.id,
    required this.videoUrl,
    required this.caption,
    required this.authorName,
    this.authorAvatar,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
  });

  static ReelModel? fromFeedItem(Map<String, dynamic> item) {
    if (item['feed_type']?.toString() != 'post') return null;
    final resource = Map<String, dynamic>.from(
      item['resource'] as Map? ?? const {},
    );
    final media = List<dynamic>.from(
      resource['media'] as List? ??
          resource['media_files'] as List? ??
          const [],
    );
    Map<String, dynamic>? video;
    for (final raw in media) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final type = (entry['type'] ?? entry['file_type'] ?? '')
          .toString()
          .toLowerCase();
      final mime = (entry['mime_type'] ?? '').toString().toLowerCase();
      final path = (entry['url'] ?? entry['path'] ?? entry['file_path'] ?? '')
          .toString()
          .toLowerCase();
      if (type == 'video' ||
          mime.startsWith('video/') ||
          RegExp(r'\.(mp4|mov|avi|m4v)(\?|$)').hasMatch(path)) {
        video = entry;
        break;
      }
    }
    final external = SocialVideo.fromText(
      resource['content']?.toString() ?? '',
    );
    if (video == null && external == null) return null;
    final rawUrl =
        (video?['url'] ??
                video?['path'] ??
                video?['file_path'] ??
                external?.url ??
                '')
            .toString();
    final resolved = ApiConfig.resolveMediaUrl(rawUrl);
    if (resolved == null || resolved.isEmpty) return null;
    final author = Map<String, dynamic>.from(
      item['author'] as Map? ?? const {},
    );
    final reaction = resource['user_reaction']?.toString().toLowerCase();
    return ReelModel(
      id: (resource['id'] ?? item['id']).toString(),
      videoUrl: resolved,
      caption: (resource['content'] ?? 'Un moment partagé sur MyReklam')
          .toString(),
      authorName: (author['display_name'] ?? 'Membre MyReklam').toString(),
      authorAvatar: ApiConfig.resolveMediaUrl(author['avatar_url']?.toString()),
      likesCount: _count(resource['likes_count']),
      commentsCount: _count(resource['comments_count']),
      isLiked: reaction == 'like',
    );
  }

  static int _count(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
