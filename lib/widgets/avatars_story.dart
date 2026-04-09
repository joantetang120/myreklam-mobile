import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';

class AvatarsStory extends StatelessWidget {
  final String name;
  final String imageName;
  final VoidCallback? onTap;

  const AvatarsStory({
    super.key,
    required this.name,
    required this.imageName,
    this.onTap,
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
              color: const Color(0xFFE6F7EF),
              border: Border.all(color: Color(0xFF3AAE5E)),
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
