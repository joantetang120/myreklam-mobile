import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/story_service.dart';
import 'package:myreklam/services/api_client.dart';

class StoryViewerScreen extends StatefulWidget {
  final String name;
  final String avatar;
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final bool isOwnStory;
  final int ownerId;

  const StoryViewerScreen({
    super.key,
    required this.name,
    required this.avatar,
    required this.stories,
    this.initialIndex = 0,
    this.isOwnStory = false,
    this.ownerId = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isLiked = false;
  bool _isTextExpanded = false;
  final StoryService _storyService = StoryService();
  late FocusNode _replyFocusNode;

  // Video playback
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _isLongPressPaused = false;

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
    _initCurrentVideo();

    _replyFocusNode = FocusNode()
      ..addListener(() {
        if (_replyFocusNode.hasFocus) {
          _progressController.stop();
          _videoController?.pause();
        } else {
          if (!_isVideo) {
            _progressController.forward();
          }
          _videoController?.play();
        }
      });
  }

  void _initCurrentVideo() {
    final story = widget.stories[_currentIndex];
    final mediaType = story['media_type'] as String? ?? 'image';
    final mediaUrl = story['image'] as String? ?? '';

    if (mediaType == 'video' &&
        mediaUrl.isNotEmpty &&
        mediaUrl.startsWith('http')) {
      setState(() {
        _isVideo = true;
        _isVideoInitialized = false;
      });
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() => _isVideoInitialized = true);
                _videoController?.play();
                _videoController?.setLooping(false);

                // Sync video position with progress indicator
                _videoController?.addListener(_onVideoProgress);
              }
            })
            .catchError((e) {
              debugPrint('Error initializing video: $e');
              setState(() => _isVideo = false);
            });
    } else {
      setState(() {
        _isVideo = false;
        _isVideoInitialized = false;
      });
      _videoController?.dispose();
      _videoController = null;
    }
  }

  void _onVideoProgress() {
    if (_videoController?.value.isInitialized != true) return;

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    const oneMinute = Duration(minutes: 1);

    // Limit video to 1 minute (loop back to start after 1 minute)
    final effectiveDuration = duration > oneMinute ? oneMinute : duration;
    final effectivePosition = position > oneMinute ? oneMinute : position;

    if (effectiveDuration.inMilliseconds > 0) {
      final progress =
          effectivePosition.inMilliseconds / effectiveDuration.inMilliseconds;
      _progressController.value = progress.clamp(0.0, 1.0);
    }

    // Loop at 1 minute or when video ends
    if (position >= effectiveDuration &&
        !_videoController!.value.isPlaying &&
        !_isLongPressPaused) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
    }
  }

  void _onLongPressStart() {
    if (_videoController?.value.isInitialized != true) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      _progressController.stop();
      setState(() => _isLongPressPaused = true);
    }
  }

  void _onLongPressEnd() {
    if (_videoController?.value.isInitialized != true) return;
    if (_isLongPressPaused) {
      _videoController!.play();
      _progressController.forward();
      setState(() => _isLongPressPaused = false);
    }
  }

  void _toggleVideoPlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _progressController.stop();
      } else {
        _videoController!.play();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
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
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _videoController = null;

    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _progressController.reset();
      _progressController.forward();
      _recordCurrentView();
      _initCurrentVideo();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _videoController = null;

    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
      _recordCurrentView();
      _initCurrentVideo();
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

  Widget _buildStoryMedia(Map<String, dynamic> story) {
    final mediaUrl = story['image'] as String?;
    final mediaType = story['media_type'] as String? ?? 'image';

    // Calculate available height (screen minus safe areas, header, text area and bottom padding)
    final screenHeight = MediaQuery.of(context).size.height;
    final safePadding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - safePadding.top - safePadding.bottom;

    // Video display
    if (mediaType == 'video' && _isVideo && _videoController != null) {
      if (!_isVideoInitialized) {
        return SizedBox(
          height: availableHeight,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      return GestureDetector(
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        child: Stack(
          fit: StackFit.loose,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // Pause overlay when paused (by long press or user action)
            if (!_videoController!.value.isPlaying)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(child: Container(width: 72, height: 72)),
              ),
          ],
        ),
      );
    }

    // Image display
    if (mediaUrl is String && mediaUrl.startsWith('http')) {
      return Image.network(
        mediaUrl,
        width: double.infinity,
        height: availableHeight,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: availableHeight,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
        errorBuilder: (_, __, ___) => SizedBox(
          height: availableHeight,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      );
    }

    // Fallback for asset images
    if (mediaUrl is String && mediaUrl.isNotEmpty) {
      return Image.asset(
        mediaUrl,
        width: double.infinity,
        height: availableHeight,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(
          height: availableHeight,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      );
    }

    return SizedBox(
      height: availableHeight,
      child: const Center(
        child: Icon(Icons.image, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _buildStoryTextOverlay(String text) {
    final maxLines = _isTextExpanded ? null : 3;
    // Estimate if text exceeds 3 lines (avg ~40 chars per line on mobile)
    final needsExpansion = text.length > 100 || text.split('\n').length > 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: needsExpansion
          ? () {
              // Toggle expansion state
              setState(() {
                _isTextExpanded = !_isTextExpanded;
              });
              // Pause when expanded, resume when collapsed
              if (_isTextExpanded) {
                _progressController.stop();
              } else {
                _progressController.forward();
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _isTextExpanded
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
        ),
        padding: EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: RichText(
          textAlign: TextAlign.left,
          maxLines: maxLines,
          overflow: maxLines != null
              ? TextOverflow.ellipsis
              : TextOverflow.clip,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: text),
              if (maxLines != null && needsExpansion)
                const TextSpan(
                  text: ' ...Voir plus',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayText(Map<String, dynamic> story) {
    final text = story['overlay_text'] as String;
    final colorHex = story['overlay_color'] as String?;
    final styleIndex = story['overlay_style'] as int? ?? 0;
    final posX = story['overlay_x'] as double? ?? 0.5;
    final posY = story['overlay_y'] as double? ?? 0.5;

    // Parse color from hex string
    Color textColor = Colors.white;
    if (colorHex != null && colorHex.startsWith('#')) {
      try {
        final hex = colorHex.substring(1);
        if (hex.length == 6) {
          textColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          textColor = Color(int.parse(hex, radix: 16));
        }
      } catch (e) {
        textColor = Colors.white;
      }
    }

    // Determine background color based on text color
    Color bgColor;
    if (textColor == Colors.white ||
        textColor == Colors.yellow ||
        textColor == Colors.lime ||
        textColor == Colors.cyan) {
      bgColor = Colors.black.withOpacity(0.4);
    } else {
      bgColor = Colors.white.withOpacity(0.9);
    }

    // Build text style based on style index
    TextStyle textStyle = TextStyle(
      color: textColor,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    );

    switch (styleIndex % 7) {
      case 1:
        textStyle = textStyle.copyWith(
          fontFamily: 'serif',
          fontWeight: FontWeight.w600,
        );
        break;
      case 2:
        textStyle = textStyle.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        );
        break;
      case 3:
        textStyle = textStyle.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
        );
        break;
      case 4:
        textStyle = textStyle.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        );
        break;
      case 5:
        textStyle = textStyle.copyWith(
          fontFamily: 'cursive',
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        );
        break;
      case 6:
        textStyle = textStyle.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );
        break;
    }

    return Positioned(
      left: posX * MediaQuery.of(context).size.width - 140,
      top: posY * MediaQuery.of(context).size.height - 50,
      child: Center(
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(minWidth: 0, maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: textStyle,
              textAlign: TextAlign.center,
              maxLines: null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    final resolved = ApiConfig.resolveMediaUrl(widget.avatar);
    if (resolved != null && resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/dashboard_particulier/Ellipse 10.png',
          fit: BoxFit.cover,
        ),
      );
    }
    // Fallback to asset (local assets like default avatar)
    return Image.asset(
      widget.avatar,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/dashboard_particulier/Ellipse 10.png',
        fit: BoxFit.cover,
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
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTapUp: (details) {
          // If text is expanded, collapse it and resume story on any tap
          if (_isTextExpanded) {
            setState(() {
              _isTextExpanded = false;
            });
            _progressController.forward();
            return;
          }
          // Normal story navigation
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
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
                                          backgroundColor: Colors.white
                                              .withOpacity(0.3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.white),
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
                          child: ClipOval(child: _buildAvatarImage()),
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
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Story media - full screen (image or video)
                          _buildStoryMedia(story),

                          // Story text overlay at bottom
                          if (story['text'] != null &&
                              (story['text'] as String).isNotEmpty)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildStoryTextOverlay(
                                story['text'] as String,
                              ),
                            ),

                          // Story overlay text with position, color, style
                          if (story['overlay_text'] != null &&
                              (story['overlay_text'] as String).isNotEmpty)
                            _buildOverlayText(story),
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
                ownerId: widget.ownerId,
                ownerName: widget.name,
                storyId: story['id'] is int ? story['id'] as int : 0,
                storyImage: story['image'] as String? ?? '',
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

class _ReplyOverlay extends StatefulWidget {
  final bool isLiked;
  final FocusNode focusNode;
  final VoidCallback onToggleLike;
  final int ownerId;
  final String ownerName;
  final int storyId;
  final String storyImage;

  const _ReplyOverlay({
    required this.isLiked,
    required this.focusNode,
    required this.onToggleLike,
    required this.ownerId,
    required this.ownerName,
    required this.storyId,
    required this.storyImage,
  });

  @override
  State<_ReplyOverlay> createState() => _ReplyOverlayState();
}

class _ReplyOverlayState extends State<_ReplyOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ConversationService _conversationService = ConversationService();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Prevent duplicate sends with synchronous check
    if (_isSending) return;
    _isSending = true;

    setState(() {});
    FocusScope.of(context).unfocus();

    try {
      // Get current user id
      final response = await ApiClient().authenticatedGet('/profile/me');
      final currentUserId =
          int.tryParse(response['user']['id'].toString()) ?? 0;

      // Get or create conversation with story owner
      final conversation = await _conversationService.getOrCreateConversation(
        widget.ownerId,
      );

      // Build story attachment metadata
      final attachments = <String, dynamic>{
        'type': 'story_reply',
        'story_id': widget.storyId,
        'story_image': widget.storyImage,
        'story_author': widget.ownerName,
      };

      // Send message with story reference
      await _conversationService.sendMessage(
        conversation.id,
        text,
        currentUserId,
        attachments: attachments,
      );

      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé'),
            backgroundColor: Color(0xFF3AAE5E),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to the conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              conversationId: conversation.id.toString(),
              name: widget.ownerName,
              avatar: null,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        _isSending = false;
        setState(() {});
      }
    }
  }

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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: widget.focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendReply(),
                        decoration: InputDecoration(
                          hintText: 'Répondre...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSending ? null : _sendReply,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AAE5E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3AAE5E).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                  // const SizedBox(width: 12),
                  // GestureDetector(
                  //   onTap: widget.onToggleLike,
                  //   child: Icon(
                  //     widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  //     color: widget.isLiked ? Colors.red : Colors.white,
                  //     size: 28,
                  //   ),
                  // ),
                  // const SizedBox(width: 16),
                  // const Icon(
                  //   Icons.share_outlined,
                  //   color: Colors.white,
                  //   size: 26,
                  // ),
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
