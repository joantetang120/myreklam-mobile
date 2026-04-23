import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';

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

  ImageProvider _getImageProvider() {
    print("imageName $imageName");
    // Local assets
    if (imageName.startsWith('assets/')) {
      return AssetImage(imageName);
    }
    // HTTP/HTTPS URLs (including resolved ones)
    if (imageName.startsWith('http')) {
      return NetworkImage(imageName);
    }
    // Relative paths - resolve to full URL
    final resolved = ApiConfig.resolveMediaUrl(imageName);
    if (resolved != null) {
      return NetworkImage(resolved);
    }
    // Fallback
    return AssetImage(imageName);
  }

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
              child: CircleAvatar(backgroundImage: _getImageProvider()),
            ),
          ),
          Text(name, style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
