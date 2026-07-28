import 'package:flutter/material.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';
import 'package:myreklam/services/story_service.dart';
import 'package:myreklam/services/story_store.dart';

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
  final StoryService _storyService = StoryService();
  final StoryStore _storyStore = StoryStore();

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
    _refreshFromApi();
  }

  Future<void> _refreshFromApi() async {
    final fresh = await _storyService.getMyStories();
    if (mounted && fresh.isNotEmpty) {
      setState(() {
        _stories = fresh;
      });
    }
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

  Future<void> _deleteStory(StoryModel story, int index) async {
    if (story.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la story'),
        content: const Text('Voulez-vous vraiment supprimer cette story ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _storyService.deleteStory(story.id!);
      if (success && mounted) {
        setState(() {
          _stories.removeAt(index);
        });
        _storyStore.removeStory(story.id!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Story supprimée')));
      }
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
          onPressed: () => Navigator.pop(context),
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
      body: _stories.isEmpty
          ? const Center(
              child: Text(
                'Aucune story active',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          : ListView.builder(
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
                  'image': s.mediaUrl ?? '',
                  'media_type': s.mediaType ?? 'image',
                  'text': s.caption,
                  'time': _getTimeAgo(s.timestamp),
                  'id': s.id,
                  'views_count': s.viewsCount,
                  'likes_count': s.likesCount,
                  'is_liked': s.isLiked,
                  'overlays': s.overlays,
                  'overlay_text': s.overlayText,
                  'overlay_color': s.overlayColor,
                  'overlay_style': s.overlayStyle,
                  'overlay_x': s.overlayX,
                  'overlay_y': s.overlayY,
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
                border: Border.all(color: const Color(0xFF3AAE5E), width: 2),
              ),
              child: ClipOval(
                child: story.mediaUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail (video or image)
                          story.mediaType == 'video'
                              ? Container(color: Colors.grey[800])
                              : Image.network(
                                  story.mediaUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          // Play icon overlay for videos
                          if (story.mediaType == 'video')
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${story.viewsCount} vue${story.viewsCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeAgo(story.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteStory(story, index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
