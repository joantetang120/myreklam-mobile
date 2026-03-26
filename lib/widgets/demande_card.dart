import 'package:flutter/material.dart';

class DemandeCard extends StatelessWidget {
  final String profileImage;
  final String username;
  final String categoryLabel;
  final Color categoryColor;
  final String title;
  final String description;
  final String location;
  final String? postImage;
  final int likesCount;
  final int commentsCount;
  final String timeAgo;
  final VoidCallback? onTapCTA;
  final Widget? reactionBar;
  final VoidCallback? onAvatarTap;

  const DemandeCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.categoryLabel,
    this.categoryColor = const Color(0xFF3AAE5E),
    required this.title,
    required this.description,
    required this.location,
    this.postImage,
    required this.likesCount,
    required this.commentsCount,
    required this.timeAgo,
    this.onTapCTA,
    this.reactionBar,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: _buildImageProvider(profileImage),
                  backgroundColor: Colors.grey[200],
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 18),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF616161),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          // Location & Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          // Post image (optional)
          if (postImage != null && postImage!.isNotEmpty) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _buildPostImage(postImage!),
            ),
          ],
          const SizedBox(height: 15),
          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTapCTA,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Voir la demande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Reaction bar (if provided)
          if (reactionBar != null) ...[
            const Divider(height: 1),
            const SizedBox(height: 10),
            reactionBar!,
            const SizedBox(height: 10),
            const Divider(height: 1),
          ],
        ],
      ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [categoryColor, categoryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Demande',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _buildImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }

  Widget _buildPostImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: double.infinity,
            height: 180,
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
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 36,
      ),
    );
  }
}
