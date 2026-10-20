import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:myreklam/widgets/social_video_preview.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class PostCard extends StatelessWidget {
  final String profileImage;
  final String username;
  final String userType;
  final String postText;
  final String? postImage;
  final int likesCount;
  final int commentsCount;
  final String timeAgo;
  final VoidCallback? onCommentsTap;

  const PostCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.userType,
    required this.postText,
    required this.postImage,
    required this.likesCount,
    required this.commentsCount,
    required this.timeAgo,
    this.onCommentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AdaptiveColors.border(
            context,
            Colors.grey,
          ).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SocialVideoPreview(text: postText),
          Row(
            children: [
              ReklamAvatar(
                avatarUrl: profileImage,
                displayName: username,
                radius: 24,
                accountType: userType.toLowerCase() == 'professionnel'
                    ? 'pro'
                    : 'particulier',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AdaptiveColors.foreground(
                          context,
                          Color(0xFF616161),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdaptiveColors.surface(
                          context,
                          const Color(0xFFF5F5F5),
                        ),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: AdaptiveColors.border(
                            context,
                            Colors.grey,
                          ).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        userType,
                        style: TextStyle(
                          fontSize: 10,
                          color: AdaptiveColors.foreground(
                            context,
                            Colors.grey,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    color: AdaptiveColors.foreground(
                      context,
                      Colors.grey,
                    ).withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.more_horiz,
                    color: AdaptiveColors.foreground(
                      context,
                      Colors.grey,
                    ).withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.close,
                    color: AdaptiveColors.foreground(
                      context,
                      Colors.grey,
                    ).withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Post Text
          Text(
            postText,
            style: TextStyle(
              fontSize: 14,
              color: AdaptiveColors.foreground(context, Color(0xFF757575)),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          // Post Image
          if (postImage != null && postImage!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildPostImage(context, postImage!),
            ),
            const SizedBox(height: 20),
          ],
          // Footer
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AdaptiveColors.border(
                    context,
                    Colors.grey,
                  ).withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildAction(
                  context,
                  Icons.thumb_up_alt_outlined,
                  likesCount.toString(),
                ),
                const SizedBox(width: 20),
                _buildAction(
                  context,
                  Icons.chat_bubble_outline,
                  commentsCount.toString(),
                  onTap: onCommentsTap,
                ),
                // Bouton partager masqué
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AdaptiveColors.foreground(
                        context,
                        Colors.grey,
                      ).withValues(alpha: 0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AdaptiveColors.foreground(context, Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String count, {
    VoidCallback? onTap,
  }) {
    final content = Row(
      children: [
        Icon(
          icon,
          color: AdaptiveColors.foreground(
            context,
            Colors.grey,
          ).withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            color: AdaptiveColors.foreground(context, Colors.grey),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _buildPostImage(BuildContext context, String path) {
    final image = path.startsWith('http')
        ? Image.network(
            path,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(context),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: double.infinity,
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          )
        : Image.asset(
            path,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(context),
          );
    return image;
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      color: AdaptiveColors.surface(context, Colors.grey[200]),
      child: Icon(
        Icons.image_not_supported,
        color: AdaptiveColors.foreground(context, Colors.grey),
        size: 40,
      ),
    );
  }
}
