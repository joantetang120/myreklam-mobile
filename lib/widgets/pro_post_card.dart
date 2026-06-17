import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class ProPostCard extends StatelessWidget {
  final String profileImage;
  final String username;
  final String userType;
  final String postText;
  final String? postImage;
  final String? reductionPercentage;
  final IconData categoryIcon;
  final String categoryName;
  final String merchantName;
  final String timeAgo;
  final String price;
  final int likesCount;
  final int commentsCount;
  final VoidCallback? onTapCTA;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onAvatarTap;

  const ProPostCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.userType,
    required this.postText,
    this.postImage,
    this.reductionPercentage,
    required this.categoryIcon,
    required this.categoryName,
    required this.merchantName,
    required this.timeAgo,
    required this.price,
    required this.likesCount,
    required this.commentsCount,
    this.onTapCTA,
    this.onCommentsTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: ReklamAvatar(
                  avatarUrl: profileImage,
                  displayName: username,
                  radius: 24,
                  accountType: 'pro',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161),
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
                        color: const Color(0xFFE6F7EF),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF3AAE5E).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        userType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3AAE5E),
                          fontWeight: FontWeight.bold,
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
                    color: Colors.grey.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.more_horiz,
                    color: Colors.grey.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.close,
                    color: Colors.grey.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Post Text
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
              children: [
                TextSpan(text: postText),
                if (postText.length > 50)
                  const TextSpan(
                    text: '...plus',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Post Image with Reduction Badge
          if (postImage != null && postImage!.isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _buildPostImage(postImage!),
                ),
                if (reductionPercentage != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reductionPercentage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Category Metadata
          Row(
            children: [
              Icon(categoryIcon, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                categoryName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 12),
          // Merchant and Time
          Row(
            children: [
              const Icon(Icons.public, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    children: [
                      const TextSpan(text: 'En ligne disponible chez ', style: TextStyle(fontSize: 10, color: Colors.black87)),
                      TextSpan(
                        text: merchantName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(' | ', style: TextStyle(color: Colors.grey)),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          // Price and CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onTapCTA,
                icon: const Icon(Icons.list_alt_outlined, size: 18),
                label: const Text('Voir le bon plan', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          // Engagement Stats
          Row(
            children: [
              _buildStat(Icons.thumb_up_alt_outlined, likesCount.toString()),
              const SizedBox(width: 20),
              _buildStat(
                Icons.chat_bubble_outline,
                commentsCount.toString(),
                onTap: onCommentsTap,
              ),
              // Bouton partager masqué
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String count, {VoidCallback? onTap}) {
    final content = Row(
      children: [
        Icon(icon, color: Colors.grey.withOpacity(0.7), size: 18),
        const SizedBox(width: 6),
        Text(
          count,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
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

  ImageProvider _buildImageProvider(String path) {
    if (path.isNotEmpty && path.startsWith('http')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }

  Widget _buildPostImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
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
      );
    }
    return Image.asset(
      path,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported,
          color: Colors.grey, size: 40),
    );
  }
}
