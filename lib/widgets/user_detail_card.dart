import 'package:flutter/material.dart';

class UserDetailCard extends StatelessWidget {
  final String avatar;
  final String name;
  final String userType;
  final VoidCallback? onSubscribe;
  final VoidCallback? onTap;
  final bool showSubscribeButton;
  final bool isFollowing;
  final bool isLoading;

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
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: avatar.startsWith('http')
                ? NetworkImage(avatar)
                : AssetImage(avatar) as ImageProvider,
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    userType,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showSubscribeButton)
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isFollowing ? const Color(0xFF3AAE5E) : const Color(0xFFFF9800),
                    side: BorderSide(
                      color: isFollowing ? const Color(0xFF3AAE5E) : const Color(0xFFFFCCBC),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                    backgroundColor: isFollowing ? const Color(0xFFE6F7EF) : const Color(0xFFFFF3E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
