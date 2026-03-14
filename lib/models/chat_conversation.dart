class ChatConversation {
  final int id;
  final int userId;
  final int? partnerId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? otherUserName;
  final String? otherUserAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.userId,
    this.partnerId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.otherUserName,
    this.otherUserAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      partnerId: json['partner_id'] as int?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
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
    return otherUserAvatar;
  }

  ChatConversation copyWith({
    int? id,
    int? userId,
    int? partnerId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? otherUserName,
    String? otherUserAvatar,
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
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
