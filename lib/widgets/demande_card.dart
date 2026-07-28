import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

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
  // Favorite properties
  final bool isFavorited;
  final bool isLoadingFavorite;
  final VoidCallback? onFavoriteToggle;
  final String? accountType;
  final VoidCallback? onReport;

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
    this.isFavorited = false,
    this.isLoadingFavorite = false,
    this.onFavoriteToggle,
    this.accountType,
    this.onReport,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
                    child: ReklamAvatar(
                      avatarUrl: profileImage,
                      displayName: username,
                      radius: 24,
                      accountType: accountType,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF616161),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Text(
                            accountType?.toLowerCase() == 'professionnel' ||
                                    accountType?.toLowerCase() == 'pro'
                                ? 'Professionnel'
                                : 'Particulier',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onReport != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Signaler',
                          onPressed: onReport,
                          icon: const Icon(
                            Icons.report_outlined,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      if (onFavoriteToggle != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Favoris',
                          onPressed: isLoadingFavorite
                              ? null
                              : onFavoriteToggle,
                          icon: isLoadingFavorite
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorited ? Colors.red : Colors.grey,
                                  size: 21,
                                ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Demande',
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
              // Location
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
              const SizedBox(height: 12),
              // Reaction bar (if provided)
              if (reactionBar != null) ...[
                const Divider(height: 1),
                const SizedBox(height: 10),
                reactionBar!,
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],
              // Time ago (below button)
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }
}
