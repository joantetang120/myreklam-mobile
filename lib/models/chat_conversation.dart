import 'package:myreklam/config/api_config.dart';

class ChatConversation {
  final int id;
  final int userId;
  final int? partnerId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isLastMessageFromMe;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? otherUserEmail;
  final String? otherUserType;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    this.partnerId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isLastMessageFromMe = false,
    this.otherUserName,
    this.otherUserAvatar,
    this.otherUserEmail,
    this.otherUserType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    // Extraire les informations de l'autre utilisateur (partner ou user selon le contexte)
    String? otherUserName;
    String? otherUserAvatar;
    String? otherUserEmail;
    String? otherUserType;

    // Déterminer qui est l'autre utilisateur en comparant avec currentUserId
    Map<String, dynamic>? otherUser;

    // Si currentUserId est fourni, l'utiliser pour déterminer l'autre utilisateur
    if (currentUserId != null) {
      final userId = json['user_id'] as int?;
      final partnerId = json['partner_id'] as int?;

      // Si l'utilisateur actuel est le user_id, alors l'autre est le partner
      if (userId == currentUserId && json['partner'] != null) {
        otherUser = json['partner'] as Map<String, dynamic>;
      }
      // Si l'utilisateur actuel est le partner_id, alors l'autre est le user
      else if (partnerId == currentUserId && json['user'] != null) {
        otherUser = json['user'] as Map<String, dynamic>;
      }
      // Fallback si aucune correspondance
      else if (json['partner'] != null) {
        otherUser = json['partner'] as Map<String, dynamic>;
      } else if (json['user'] != null) {
        otherUser = json['user'] as Map<String, dynamic>;
      }
    } else {
      // Ancienne logique si currentUserId n'est pas fourni
      if (json['partner'] != null) {
        otherUser = json['partner'] as Map<String, dynamic>;
      } else if (json['user'] != null) {
        otherUser = json['user'] as Map<String, dynamic>;
      }
    }

    if (otherUser != null) {
      otherUserEmail = otherUser['email']?.toString();
      otherUserType = otherUser['account_type']?.toString();

      // Extraire le nom depuis le profil approprié
      if (otherUser['account_type'] == 'particulier' &&
          otherUser['particulier_profile'] != null) {
        final particulierProfile =
            otherUser['particulier_profile'] as Map<String, dynamic>;
        otherUserName =
            particulierProfile['pseudo']?.toString() ??
            otherUserEmail?.split('@').first ??
            'Utilisateur';
        otherUserAvatar = particulierProfile['avatar_url']?.toString();
      } else if (otherUser['account_type'] == 'pro' &&
          otherUser['pro_profile'] != null) {
        final proProfile = otherUser['pro_profile'] as Map<String, dynamic>;
        otherUserName =
            proProfile['company_name']?.toString() ??
            (proProfile['first_name']?.toString() != null &&
                    proProfile['last_name']?.toString() != null
                ? '${proProfile['first_name']} ${proProfile['last_name']}'
                : otherUserEmail?.split('@').first) ??
            'Utilisateur';
        otherUserAvatar = proProfile['avatar_url']?.toString();
      } else {
        // Fallback si aucun profil n'est disponible
        otherUserName = otherUserEmail?.split('@').first ?? 'Utilisateur';
        otherUserAvatar = null;
      }
    }

    return ChatConversation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      partnerId: json['partner_id'] as int?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isLastMessageFromMe: json['is_last_message_from_me'] as bool? ?? false,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      otherUserEmail: otherUserEmail,
      otherUserType: otherUserType,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'partner_id': partnerId,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthode helper pour obtenir le nom de l'autre utilisateur
  String getOtherUserName() {
    return otherUserName ?? 'Utilisateur';
  }

  // Méthode helper pour obtenir l'avatar de l'autre utilisateur
  String? getOtherUserAvatar() {
    return _buildStorageUrl(otherUserAvatar);
  }

  // Méthode helper pour construire l'URL de stockage
  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    // Construire l'URL complète en ajoutant la base du serveur
    final serverBase = ApiConfig.baseUrl.replaceFirst('/api', '');
    return '$serverBase/storage/$url';
  }

  ChatConversation copyWith({
    int? id,
    int? userId,
    int? partnerId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isLastMessageFromMe,
    String? otherUserName,
    String? otherUserAvatar,
    String? otherUserEmail,
    String? otherUserType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isLastMessageFromMe: isLastMessageFromMe ?? this.isLastMessageFromMe,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      otherUserEmail: otherUserEmail ?? this.otherUserEmail,
      otherUserType: otherUserType ?? this.otherUserType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter pour obtenir le type d'utilisateur formaté
  String getFormattedUserType() {
    if (otherUserType == null) return '';
    switch (otherUserType!.toLowerCase()) {
      case 'pro':
        return 'Professionnel';
      case 'particulier':
        return 'Particulier';
      default:
        return otherUserType!;
    }
  }

  // Getter pour savoir si l'autre utilisateur est un pro
  bool get isOtherUserPro => otherUserType?.toLowerCase() == 'pro';
}
