import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class AvatarsStory extends StatelessWidget {
  final String name;
  final String imageName;
  final VoidCallback? onTap;
  final bool isViewed;

  const AvatarsStory({
    super.key,
    required this.name,
    required this.imageName,
    this.onTap,
    this.isViewed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        spacing: 5,
        children: [
          Container(
            padding: EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isViewed ? Colors.grey.shade200 : const Color(0xFFE6F7EF),
              border: Border.all(
                color: isViewed
                    ? Colors.grey.shade400
                    : const Color(0xFF3AAE5E),
                width: isViewed ? 1.5 : 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: ReklamAvatar(
                avatarUrl: imageName,
                displayName: name,
                radius: 21,
              ),
            ),
          ),
          Text(name, style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
