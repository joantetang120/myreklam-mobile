class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String text;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;
  final String? senderName;
  final String? senderAvatar;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,
    this.senderName,
    this.senderAvatar,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int currentUserId) {
    // Support pour les données du message direct ou depuis l'événement Pusher
    final messageData = json['message'] ?? json;
    final senderData = json['sender'] as Map<String, dynamic>?;

    return ChatMessage(
      id: messageData['id'] as int,
      conversationId: messageData['conversation_id'] as int,
      senderId: messageData['sender_id'] as int,
      text: messageData['text'] as String,
      createdAt: DateTime.parse(messageData['created_at'] as String),
      isMe: (messageData['sender_id'] as int) == currentUserId,
      isRead: messageData['is_read'] as bool? ?? false,
      senderName: senderData?['name'] as String?,
      senderAvatar: senderData?['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? text,
    DateTime? createdAt,
    bool? isMe,
    bool? isRead,
    String? senderName,
    String? senderAvatar,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}
