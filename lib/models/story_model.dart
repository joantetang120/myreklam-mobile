import 'dart:typed_data';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/story_overlay.dart';

class StoryModel {
  final int? id;
  final int? userId;
  final String? mediaUrl;
  final String? mediaType;
  final Uint8List? imageBytes;
  final String caption;
  final String? overlayText;
  final String? overlayColor;
  final int? overlayStyle;
  final double? overlayX;
  final double? overlayY;
  final int viewsCount;
  final int likesCount;
  final bool isLiked;
  final List<StoryOverlay> overlays;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final bool isOwn;
  final List<StoryViewer> viewers;

  StoryModel({
    this.id,
    this.userId,
    this.mediaUrl,
    this.mediaType,
    this.imageBytes,
    required this.caption,
    this.overlayText,
    this.overlayColor,
    this.overlayStyle,
    this.overlayX,
    this.overlayY,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.isLiked = false,
    this.overlays = const [],
    required this.timestamp,
    this.expiresAt,
    this.isOwn = false,
    this.viewers = const [],
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
      mediaUrl: ApiConfig.resolveMediaUrl(json['media_url']?.toString()),
      mediaType: json['media_type']?.toString() ?? 'image',
      caption: json['caption']?.toString() ?? '',
      overlayText: json['overlay_text']?.toString(),
      overlayColor: json['overlay_color']?.toString(),
      overlayStyle: json['overlay_style'] is int
          ? json['overlay_style']
          : int.tryParse(json['overlay_style']?.toString() ?? ''),
      overlayX: json['overlay_x'] is double
          ? json['overlay_x']
          : double.tryParse(json['overlay_x']?.toString() ?? ''),
      overlayY: json['overlay_y'] is double
          ? json['overlay_y']
          : double.tryParse(json['overlay_y']?.toString() ?? ''),
      viewsCount: json['views_count'] is int
          ? json['views_count']
          : int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is int
          ? json['likes_count']
          : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true,
      overlays: StoryOverlay.listFromJson(json['overlays']),
      timestamp:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      isOwn: json['is_own'] == true,
      viewers:
          (json['viewers'] as List?)
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
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      userAvatar: ApiConfig.resolveMediaUrl(json['user_avatar']?.toString()),
      isOwn: json['is_own'] == true,
      stories:
          (json['stories'] as List?)
              ?.map((s) => StoryModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A user who can be @-mentioned in a story (built from the followers endpoint).
class MentionUser {
  final int id;
  final String name;
  final String? avatar;

  MentionUser({required this.id, required this.name, this.avatar});

  factory MentionUser.fromFollowerJson(Map<String, dynamic> json) {
    final particulier = json['particulier_profile'] as Map<String, dynamic>?;
    final pro = json['pro_profile'] as Map<String, dynamic>?;

    String name = 'Utilisateur';
    String? avatar;
    if (particulier != null) {
      name = particulier['pseudo']?.toString().trim().isNotEmpty == true
          ? particulier['pseudo'].toString()
          : name;
      avatar = particulier['avatar_url']?.toString();
    } else if (pro != null) {
      final company = pro['company_name']?.toString().trim() ?? '';
      final full =
          '${pro['first_name']?.toString() ?? ''} ${pro['last_name']?.toString() ?? ''}'
              .trim();
      name = company.isNotEmpty ? company : (full.isNotEmpty ? full : name);
      avatar = pro['avatar_url']?.toString() ?? pro['logo_url']?.toString();
    }

    return MentionUser(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: name,
      avatar: ApiConfig.resolveMediaUrl(avatar),
    );
  }
}

class StoryViewer {
  final int userId;
  final String userName;
  final String? userAvatar;
  final DateTime viewedAt;
  final bool liked;

  StoryViewer({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.viewedAt,
    this.liked = false,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString(),
      viewedAt:
          DateTime.tryParse(json['viewed_at']?.toString() ?? '') ??
          DateTime.now(),
      liked: json['liked'] == true,
    );
  }
}
