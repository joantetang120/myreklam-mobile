import 'dart:typed_data';
import 'package:myreklam/config/api_config.dart';

class StoryModel {
  final int? id;
  final int? userId;
  final String? mediaUrl;
  final Uint8List? imageBytes;
  final String caption;
  final int viewsCount;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final bool isOwn;
  final List<StoryViewer> viewers;

  StoryModel({
    this.id,
    this.userId,
    this.mediaUrl,
    this.imageBytes,
    required this.caption,
    this.viewsCount = 0,
    required this.timestamp,
    this.expiresAt,
    this.isOwn = false,
    this.viewers = const [],
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      mediaUrl: ApiConfig.resolveMediaUrl(json['media_url']?.toString()),
      caption: json['caption']?.toString() ?? '',
      viewsCount: json['views_count'] is int ? json['views_count'] : int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      isOwn: json['is_own'] == true,
      viewers: (json['viewers'] as List?)
              ?.map((v) => StoryViewer.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class StoryUserGroup {
  final int userId;
  final String userName;
  final String? userAvatar;
  final bool isOwn;
  final List<StoryModel> stories;

  StoryUserGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.isOwn,
    required this.stories,
  });

  factory StoryUserGroup.fromJson(Map<String, dynamic> json) {
    return StoryUserGroup(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      userAvatar: ApiConfig.resolveMediaUrl(json['user_avatar']?.toString()),
      isOwn: json['is_own'] == true,
      stories: (json['stories'] as List?)
              ?.map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class StoryViewer {
  final int userId;
  final String userName;
  final String? userAvatar;
  final DateTime viewedAt;

  StoryViewer({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString(),
      viewedAt: DateTime.tryParse(json['viewed_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
