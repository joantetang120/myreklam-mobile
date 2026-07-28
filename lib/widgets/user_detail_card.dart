import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class UserDetailCard extends StatelessWidget {
  final String avatar;
  final String name;
  final String userType;
  final VoidCallback? onSubscribe;
  final VoidCallback? onTap;
  final bool showSubscribeButton;
  final bool isFollowing;
  final bool isLoading;
  final bool isOwner;

  const UserDetailCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.userType,
    this.onSubscribe,
    this.onTap,
    this.showSubscribeButton = true,
    this.isFollowing = false,
    this.isLoading = false,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ReklamAvatar(
            avatarUrl: avatar,
            displayName: name,
            radius: 26,
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
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 203, 236, 224),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        98,
                        93,
                        93,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    userType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0XFF04BC7B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showSubscribeButton && !isOwner)
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF9800),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onSubscribe,
                    icon: Icon(
                      isFollowing ? Icons.check : Icons.person_add_outlined,
                      size: 14,
                    ),
                    label: Text(
                      isFollowing ? 'Suivis' : 'Suivre',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowing
                          ? const Color(0xFF3AAE5E)
                          : const Color(0xFFFF9800),
                      side: BorderSide(
                        color: isFollowing
                            ? const Color(0xFF3AAE5E)
                            : const Color(0xFFFFCCBC),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 0),
                      backgroundColor: isFollowing
                          ? const Color(0xFFE6F7EF)
                          : const Color(0xFFFFF3E0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
