import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class FollowerUserCard extends StatelessWidget {
  final String image;
  final String name;
  final String subname;
  final String buttonText;
  final VoidCallback? onFollow;
  final VoidCallback? onRemove;

  const FollowerUserCard({
    super.key,
    required this.image,
    required this.name,
    required this.subname,
    this.buttonText = 'Suivre en retour',
    this.onFollow,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ReklamAvatar(avatarUrl: image, displayName: name, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subname,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onFollow,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3AAE5E),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: const BorderSide(color: Color(0xFF3AAE5E), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }
}
