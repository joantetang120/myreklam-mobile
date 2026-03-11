import 'package:flutter/material.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';

class MyStoriesScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final String userName;
  final String userAvatar;

  const MyStoriesScreen({
    super.key,
    required this.stories,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  late List<StoryModel> _stories;

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return "il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}";
    } else if (difference.inHours < 24) {
      return "il y a ${difference.inHours}h";
    } else {
      return "il y a ${difference.inDays}j";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, _stories),
        ),
        title: const Text(
          'Mon Statut',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return _buildStoryItem(story, index);
        },
      ),
    );
  }

  Widget _buildStoryItem(StoryModel story, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerScreen(
              name: widget.userName,
              avatar: widget.userAvatar,
              stories: _stories.map((s) {
                return {
                  'image': s.imageBytes,
                  'text': s.caption,
                  'time': _getTimeAgo(s.timestamp),
                };
              }).toList(),
              initialIndex: index,
              isOwnStory: true,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3AAE5E),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.memory(
                  story.imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '100 vues',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(story.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onPressed: () {
                // Show options menu
              },
            ),
          ],
        ),
      ),
    );
  }
}
