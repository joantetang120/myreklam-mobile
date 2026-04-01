import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';

class PostDetailFullScreen extends StatelessWidget {
  final Map<String, dynamic> author;
  final String content;
  final String timeAgo;
  final List<String> mediaUrls;
  final Widget reactionBar;

  const PostDetailFullScreen({
    super.key,
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.mediaUrls,
    required this.reactionBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Publication',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _getAvatarProvider(author['avatar']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author['displayName'] ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${author['accountType']} • $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
              ),

            // Media
            if (mediaUrls.isNotEmpty)
              Column(
                children: mediaUrls.map((url) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                )).toList(),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            // Reaction Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: reactionBar,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  ImageProvider _getAvatarProvider(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/images/dashboard_particulier/Ellipse 10.png');
    }
    if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    return NetworkImage(ApiConfig.resolveMediaUrl(avatar) ?? '') as ImageProvider;
  }
}
