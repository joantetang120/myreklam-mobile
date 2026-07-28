import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isSent;
  final bool isRead;
  final Map<String, dynamic>? attachments;
  final bool isEdited;
  final bool deletedForEveryone;
  final bool isDeletedForMe;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isSent,
    this.isRead = false,
    this.attachments,
    this.isEdited = false,
    this.deletedForEveryone = false,
    this.isDeletedForMe = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher les messages supprimés pour moi
    if (isDeletedForMe) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (isSent) const Spacer(flex: 1),
          Flexible(
            flex: 5,
            child: GestureDetector(
              onLongPress: deletedForEveryone ? null : onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: deletedForEveryone
                      ? (isSent
                            ? const Color(0xFFFFB74D).withValues(alpha: 0.4)
                            : const Color(0xFFF5F5F5).withValues(alpha: 0.6))
                      : (isSent
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isSent
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isSent
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isSent
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (deletedForEveryone) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block,
                            size: 14,
                            color: isSent
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Le message a \u00e9t\u00e9 supprim\u00e9',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isSent
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (attachments != null &&
                          attachments!['type'] == 'story_reply')
                        _StoryReplyPreview(
                          storyImage:
                              attachments!['story_image'] as String? ?? '',
                          storyAuthor:
                              attachments!['story_author'] as String? ??
                              'Story',
                          isSent: isSent,
                        ),
                      if (attachments != null &&
                          attachments!['type'] == 'annonce')
                        _AnnoncePreview(
                          title: attachments!['title'] as String? ?? '',
                          description:
                              attachments!['description'] as String? ?? '',
                          imageUrl: attachments!['image_url'] as String? ?? '',
                          authorName:
                              attachments!['author_name'] as String? ?? '',
                          annonceType:
                              attachments!['annonce_type'] as String? ?? '',
                          isSent: isSent,
                        ),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSent
                              ? Colors.white
                              : const Color(0xFF616161),
                          height: 1.4,
                        ),
                      ),
                      if (isEdited)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Modifi\u00e9',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isSent
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSent
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.grey[600],
                          ),
                        ),
                        if (isSent && !deletedForEveryone) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: isRead
                                ? const Color(0xFF2196F3)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!isSent) const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _AnnoncePreview extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String authorName;
  final String annonceType;
  final bool isSent;

  const _AnnoncePreview({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.authorName,
    required this.annonceType,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSent
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF3AAE5E).withValues(alpha: 0.4);
    final labelColor = isSent
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF3AAE5E);
    final subtitleColor = isSent
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: labelColor, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName.isNotEmpty ? authorName : 'Annonce',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (annonceType.isNotEmpty)
                  Text(
                    annonceType,
                    style: TextStyle(fontSize: 10, color: subtitleColor),
                  ),
                const SizedBox(height: 2),
                Text(
                  title.isNotEmpty ? title : description,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: borderColor,
                  child: Icon(
                    Icons.image_outlined,
                    size: 20,
                    color: isSent ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryReplyPreview extends StatelessWidget {
  final String storyImage;
  final String storyAuthor;
  final bool isSent;

  const _StoryReplyPreview({
    required this.storyImage,
    required this.storyAuthor,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSent
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.grey.withValues(alpha: 0.4);
    final labelColor = isSent
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF3AAE5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: labelColor, width: 3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 12,
                      color: labelColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$storyAuthor • Story',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Story',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSent
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (storyImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                storyImage,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: borderColor,
                  child: Icon(
                    Icons.image_outlined,
                    size: 20,
                    color: isSent ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
