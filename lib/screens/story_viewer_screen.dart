import 'package:flutter/material.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final bool isOwnStory;

  const StoryViewerScreen({
    super.key,
    required this.name,
    required this.avatar,
    required this.stories,
    this.initialIndex = 0,
    this.isOwnStory = false,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isLiked = false;
  final StoryService _storyService = StoryService();
  late FocusNode _replyFocusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });
    _progressController.forward();
    _recordCurrentView();

    _replyFocusNode = FocusNode()
      ..addListener(() {
        if (_replyFocusNode.hasFocus) {
          _progressController.stop();
        } else {
          _progressController.forward();
        }
      });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _recordCurrentView() {
    if (!widget.isOwnStory) {
      final storyId = widget.stories[_currentIndex]['id'];
      if (storyId is int) {
        _storyService.recordView(storyId);
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _progressController.reset();
      _progressController.forward();
      _recordCurrentView();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
      _recordCurrentView();
    }
  }

  void _showViewersModal() {
    final storyId = widget.stories[_currentIndex]['id'];
    if (storyId is! int) return;

    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<StoryViewer>>(
          future: _storyService.getViewers(storyId),
          builder: (context, snapshot) {
            final viewers = snapshot.data ?? [];
            final viewsCount =
                widget.stories[_currentIndex]['views_count'] ?? viewers.length;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Vu par $viewsCount personne${viewsCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (viewers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucune vue pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: viewers.length,
                        itemBuilder: (context, index) {
                          final viewer = viewers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: viewer.userAvatar != null
                                  ? NetworkImage(viewer.userAvatar!)
                                  : const AssetImage(
                                          'assets/images/dashboard_particulier/Ellipse 10.png',
                                        )
                                        as ImageProvider,
                            ),
                            title: Text(
                              viewer.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              _getTimeAgo(viewer.viewedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _progressController.forward();
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "il y a ${diff.inHours}h";
    return "il y a ${diff.inDays}j";
  }

  Widget _buildStoryImage(Map<String, dynamic> story) {
    final image = story['image'];

    if (image is String && image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
        errorBuilder: (_, __, ___) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      );
    }

    // Fallback for asset images
    if (image is String && image.isNotEmpty) {
      return Image.asset(
        image,
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.4,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.4,
      child: const Center(
        child: Icon(Icons.image, color: Colors.white54, size: 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final viewsCount = story['views_count'] ?? 0;

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = mediaQuery.size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onTap: () => FocusScope.of(context).unfocus(),
        onLongPressStart: (_) => _progressController.stop(),
        onLongPressEnd: (_) => _progressController.forward(),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
              // Progress bars
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(widget.stories.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: index == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: _progressController.value,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                      minHeight: 2.5,
                                    );
                                  },
                                )
                              : LinearProgressIndicator(
                                  value: index < _currentIndex ? 1.0 : 0.0,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                  minHeight: 2.5,
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

                  // Header: avatar, name, time, close
                  Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3AAE5E),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: widget.avatar.startsWith('http')
                            ? Image.network(
                                widget.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/dashboard_particulier/Ellipse 10.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(widget.avatar, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            story['time'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Story image
                          _buildStoryImage(story),

                          const SizedBox(height: 16),

                          // Story text
                          if (story['text'] != null &&
                              (story['text'] as String).isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                story['text'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isOwnStory)
              _OwnStoryOverlay(
                viewsCount: viewsCount,
                onShowViewers: _showViewersModal,
              )
            else
              _ReplyOverlay(
                isLiked: _isLiked,
                focusNode: _replyFocusNode,
                onToggleLike: () {
                  setState(() => _isLiked = !_isLiked);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyOverlay extends StatelessWidget {
  final bool isLiked;
  final FocusNode focusNode;
  final VoidCallback onToggleLike;

  const _ReplyOverlay({
    required this.isLiked,
    required this.focusNode,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: TextField(
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Répondre',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onToggleLike,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnStoryOverlay extends StatelessWidget {
  final int viewsCount;
  final VoidCallback onShowViewers;

  const _OwnStoryOverlay({
    required this.viewsCount,
    required this.onShowViewers,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onShowViewers,
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$viewsCount Vue${viewsCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
