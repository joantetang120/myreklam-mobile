import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myreklam/services/share_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/image_preview_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/post_detail_full_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_profileEntreprise_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ProPublicViewScreen extends StatefulWidget {
  final String? userId; // null means viewing own profile

  const ProPublicViewScreen({super.key, this.userId});

  @override
  State<ProPublicViewScreen> createState() => _ProPublicViewScreenState();
}

class _ReactionData {
  int likesCount;
  int commentsCount;
  int repostsCount;
  String? userReaction; // 'like' or null

  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.userReaction,
  });
}

class _ReviewEntry {
  final String avatarPath;
  final String name;
  final String timeAgo;
  final String reviewText;
  final int rating;

  const _ReviewEntry({
    required this.avatarPath,
    required this.name,
    required this.timeAgo,
    required this.reviewText,
    required this.rating,
  });
}

Widget _buildBonPlanImage(String url) {
  return Image.network(
    url,
    width: double.infinity,
    height: 220,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        height: 220,
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    },
    errorBuilder: (_, error, ___) {
      debugPrint('Image load error: $error');
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
        ),
      );
    },
  );
}

Widget _buildBonPlanImageCarousel(List<String> urls) {
  if (urls.length == 1) {
    return _buildBonPlanImage(urls.first);
  }

  return StatefulBuilder(
    builder: (context, setState) {
      final controller = PageController();
      int currentPage = 0;

      return Column(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: controller,
              itemCount: urls.length,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemBuilder: (context, index) {
                return _buildBonPlanImage(urls[index]);
              },
            ),
          ),
          // Page indicator
          if (urls.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(urls.length, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == currentPage
                        ? const Color(0xFFFF9800)
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
          ],
        ],
      );
    },
  );
}

/// Widget that displays video thumbnail using video_thumbnail package
class _VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double? height;
  final BoxFit fit;

  const _VideoThumbnailWidget({
    required this.videoUrl,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showPreview = true;
  VideoPlayerController? _previewController;
  bool _isMuted = true;
  Timer? _positionTimer;
  Duration _position = Duration.zero;

  Widget _wrapWithConstraints(Widget child) {
    if (widget.height != null) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: child,
      );
    }
    return AspectRatio(aspectRatio: 16 / 9, child: child);
  }

  @override
  void initState() {
    super.initState();
    _startPreviewThenGenerateThumbnail();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _previewController?.dispose();
    super.dispose();
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final c = _previewController;
      if (!mounted || c == null || !c.value.isInitialized) return;
      final newPos = c.value.position;
      if (newPos.inSeconds != _position.inSeconds) {
        setState(() {
          _position = newPos;
        });
      }
    });
  }

  Future<void> _startPreviewThenGenerateThumbnail() async {
    // Autoplay preview in loop (muted by default).
    // If preview init fails (network/codec), fallback to thumbnail.
    final trimmedUrl = widget.videoUrl.trim();
    if (trimmedUrl.isEmpty ||
        (!trimmedUrl.toLowerCase().startsWith('http://') &&
            !trimmedUrl.toLowerCase().startsWith('https://'))) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _showPreview = false;
      });
      return;
    }

    // Start generating thumbnail in background.
    _generateThumbnail();

    // Start preview.
    try {
      _previewController = VideoPlayerController.networkUrl(
        Uri.parse(trimmedUrl),
      );
      await _previewController!.initialize();
      await _previewController!.setLooping(true);
      await _previewController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _previewController!.play();

      _position = Duration.zero;
      _startPositionTimer();

      if (mounted) {
        setState(() {
          _showPreview = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Ignore preview errors and fall back to thumbnail/fallback.
      if (mounted) {
        setState(() {
          _showPreview = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Duration _remaining(Duration duration, Duration position) {
    if (duration == Duration.zero) return Duration.zero;
    final remainingMs = duration.inMilliseconds - position.inMilliseconds;
    if (remainingMs <= 0) return Duration.zero;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> _toggleMute() async {
    final c = _previewController;
    if (c == null || !c.value.isInitialized) return;
    final newMuted = !_isMuted;
    await c.setVolume(newMuted ? 0.0 : 1.0);
    if (mounted) {
      setState(() {
        _isMuted = newMuted;
      });
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      debugPrint(
        '[_VideoThumbnailWidget] Generating thumbnail for: ${widget.videoUrl}',
      );

      // Check if URL is valid
      final trimmedUrl = widget.videoUrl.trim();
      if (trimmedUrl.isEmpty ||
          (!trimmedUrl.toLowerCase().startsWith('http://') &&
              !trimmedUrl.toLowerCase().startsWith('https://'))) {
        debugPrint('[_VideoThumbnailWidget] Invalid URL: "${widget.videoUrl}"');
        debugPrint('[_VideoThumbnailWidget] Trimmed URL: "$trimmedUrl"');
        debugPrint(
          '[_VideoThumbnailWidget] Starts with http: ${trimmedUrl.toLowerCase().startsWith('http://')}',
        );
        debugPrint(
          '[_VideoThumbnailWidget] Starts with https: ${trimmedUrl.toLowerCase().startsWith('https://')}',
        );
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // Generate thumbnail at ~10% of video duration or 5 seconds
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 500,
        quality: 80,
        timeMs: 5000, // 5 seconds
      );

      if (thumbnail == null) {
        debugPrint(
          '[_VideoThumbnailWidget] Thumbnail generation returned null',
        );
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[_VideoThumbnailWidget] Error generating thumbnail: $e');
      // Silently fail to fallback - video thumbnails may not work for remote URLs
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback();
    }

    if (_showPreview &&
        _previewController != null &&
        _previewController!.value.isInitialized) {
      final duration = _previewController!.value.duration;
      final remaining = _remaining(duration, _position);
      return _wrapWithConstraints(
        Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _previewController!.value.size.width,
                height: _previewController!.value.size.height,
                child: VideoPlayer(_previewController!),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return _wrapWithConstraints(
        Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return _wrapWithConstraints(
      Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _thumbnailData!,
            fit: widget.fit,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
          // Play icon overlay
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return _wrapWithConstraints(
      Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Colors.grey[700],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableDescriptionStateful extends StatefulWidget {
  final String text;

  const _ExpandableDescriptionStateful({required this.text});

  @override
  State<_ExpandableDescriptionStateful> createState() =>
      _ExpandableDescriptionStatefulState();
}

class _ExpandableDescriptionStatefulState
    extends State<_ExpandableDescriptionStateful> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text;

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedCrossFade(
        firstChild: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: text.length > 100
                    ? '${text.substring(0, 100)}... '
                    : text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              if (text.length > 100)
                const TextSpan(
                  text: 'voir plus',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        secondChild: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.4,
          ),
        ),
        crossFadeState: isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _PostAuthorInfo {
  const _PostAuthorInfo({
    required this.id,
    required this.displayName,
    required this.accountType,
    required this.avatar,
  });

  final String? id;
  final String displayName;
  final String accountType;
  final String avatar;
}

/// Helper function to check if a URL is a video
bool _isVideoUrl(String url) {
  final videoExtensions = ['.mp4', '.mov', '.avi', '.quicktime', '.x-msvideo'];
  final lowerUrl = url.toLowerCase();
  return videoExtensions.any((ext) => lowerUrl.contains(ext));
}

class _PostCardWidget extends StatefulWidget {
  final String postId;
  final bool isRepost;
  final bool isQuoteRepost;
  final String? repostContent;
  final _PostAuthorInfo reposter;
  final _PostAuthorInfo author;
  final String content;
  final String timeAgo;
  final List<String> mediaUrls;
  final Function(String) onToggleReaction;
  final Widget Function() buildReactionBar;
  final Widget Function(String, Color, IconData) buildTypeTag;

  const _PostCardWidget({
    required this.postId,
    required this.isRepost,
    this.isQuoteRepost = false,
    this.repostContent,
    required this.reposter,
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.mediaUrls,
    required this.onToggleReaction,
    required this.buildReactionBar,
    required this.buildTypeTag,
  });

  @override
  State<_PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<_PostCardWidget> {
  bool _isExpanded = false;
  static const int _collapsedMaxLength = 150;

  Widget _buildAuthorRow(_PostAuthorInfo authorInfo) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final userId = authorInfo.id;
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      authorInfo.accountType.toLowerCase() == 'professionnel'
                      ? ProPublicViewScreen(userId: userId)
                      : ParticulierPublicViewScreen(userId: userId),
                ),
              );
            }
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: authorInfo.avatar.startsWith('http')
                ? NetworkImage(authorInfo.avatar) as ImageProvider
                : authorInfo.avatar.startsWith('assets/')
                ? AssetImage(authorInfo.avatar)
                : NetworkImage(
                        ApiConfig.resolveMediaUrl(authorInfo.avatar) ?? '',
                      )
                      as ImageProvider,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  final userId = authorInfo.id;
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            authorInfo.accountType.toLowerCase() ==
                                'professionnel'
                            ? ProPublicViewScreen(userId: userId)
                            : ParticulierPublicViewScreen(userId: userId),
                      ),
                    );
                  }
                },
                child: Text(
                  authorInfo.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${authorInfo.accountType} • ${widget.timeAgo}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // For quote reposts, show the repost_content as main text
    final mainContent = widget.isQuoteRepost
        ? (widget.repostContent ?? '')
        : widget.content;
    final needsCollapse = mainContent.length > _collapsedMaxLength;
    final displayContent = !_isExpanded && needsCollapse
        ? '${mainContent.substring(0, _collapsedMaxLength)}...'
        : mainContent;

    // For quote repost, the author row shows the reposter; for simple repost, it shows the original author
    final displayAuthor = widget.isQuoteRepost
        ? widget.reposter
        : widget.author;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailFullScreen(
              author: {
                'displayName': widget.author.displayName,
                'accountType': widget.author.accountType,
                'avatar': widget.author.avatar,
              },
              content: widget.content,
              timeAgo: widget.timeAgo,
              mediaUrls: widget.mediaUrls,
              reactionBar: widget.buildReactionBar(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with author info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Repost header if applicable (simple repost only)
                  if (widget.isRepost && !widget.isQuoteRepost) ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                widget.reposter.avatar.startsWith('http')
                                ? NetworkImage(widget.reposter.avatar)
                                : widget.reposter.avatar.startsWith('assets/')
                                ? AssetImage(widget.reposter.avatar)
                                      as ImageProvider
                                : NetworkImage(
                                    ApiConfig.resolveMediaUrl(
                                          widget.reposter.avatar,
                                        ) ??
                                        '',
                                  ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: widget.reposter.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' a republié ce contenu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Author row
                  _buildAuthorRow(displayAuthor),
                ],
              ),
            ),
            // Main content text (repost_content for quote, original content for simple/original)
            if (mainContent.isNotEmpty && !widget.isQuoteRepost) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayContent,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        height: 1.4,
                      ),
                    ),
                    if (needsCollapse)
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isExpanded ? '...moins' : '...plus',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            // Quote repost: show repost_content then embedded original post
            if (widget.isQuoteRepost) ...[
              if (mainContent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    displayContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              // Embedded original post card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original author info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                widget.author.avatar.startsWith('http')
                                ? NetworkImage(widget.author.avatar)
                                      as ImageProvider
                                : widget.author.avatar.startsWith('assets/')
                                ? AssetImage(widget.author.avatar)
                                : NetworkImage(
                                        ApiConfig.resolveMediaUrl(
                                              widget.author.avatar,
                                            ) ??
                                            '',
                                      )
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.author.displayName} • ${widget.timeAgo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Original content
                    if (widget.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Text(
                          widget.content.length > 200
                              ? '${widget.content.substring(0, 200)}...'
                              : widget.content,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            height: 1.4,
                          ),
                        ),
                      ),
                    // Original media
                    if (widget.mediaUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                        child: SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: _buildMediaSection(widget.mediaUrls),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
            // Media images (only for non-quote posts)
            if (!widget.isQuoteRepost && widget.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaSection(widget.mediaUrls),
            ],
            // Reaction bar
            if (widget.postId.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.buildReactionBar(),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return _MediaItemWidget(
        url: urls[0],
        onTap: () => _openImagePreview(context, urls, 0),
        height: 400,
      );
    }

    // Multiple images/videos - show grid
    return SizedBox(height: 300, child: _buildMediaGrid(urls));
  }

  void _openImagePreview(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImagePreviewScreen(imageUrls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _MediaItemWidget(
              url: urls[0],
              onTap: () => _openImagePreview(context, urls, 0),
              height: 300,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _MediaItemWidget(
              url: urls[1],
              onTap: () => _openImagePreview(context, urls, 1),
              height: 300,
            ),
          ),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _MediaItemWidget(
              url: urls[0],
              onTap: () => _openImagePreview(context, urls, 0),
              height: 300,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _MediaItemWidget(
                    url: urls[1],
                    onTap: () => _openImagePreview(context, urls, 1),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _MediaItemWidget(
                    url: urls[2],
                    onTap: () => _openImagePreview(context, urls, 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4+ images/videos: 2x2 grid with overflow counter
    final int remaining = urls.length - 4;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _MediaItemWidget(
                  url: urls[0],
                  onTap: () => _openImagePreview(context, urls, 0),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _MediaItemWidget(
                  url: urls[1],
                  onTap: () => _openImagePreview(context, urls, 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _MediaItemWidget(
                  url: urls[2],
                  onTap: () => _openImagePreview(context, urls, 2),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, urls, 3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isVideoUrl(urls[3])
                          ? _VideoThumbnailWidget(videoUrl: urls[3])
                          : Image.network(
                              urls[3],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                      if (remaining > 0)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
      ],
    );
  }
}

/// Widget to display media item (image or video thumbnail)
class _MediaItemWidget extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  final double? height;

  const _MediaItemWidget({required this.url, required this.onTap, this.height});

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoUrl(url);
    return GestureDetector(
      onTap: onTap,
      child: isVideo
          ? _VideoThumbnailWidget(videoUrl: url, height: height)
          : Image.network(
              url,
              fit: BoxFit.cover,
              height: height,
              width: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
    );
  }
}

/// Widget for carousel media items (smaller play icon)
class _CarouselMediaItemWidget extends StatelessWidget {
  final String url;
  final double? height;

  const _CarouselMediaItemWidget({required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoUrl(url);
    if (isVideo) {
      return Stack(
        alignment: Alignment.center,
        fit: height == null ? StackFit.expand : StackFit.loose,
        children: [
          _VideoThumbnailWidget(videoUrl: url, height: height),
          // Smaller play icon overlay for carousel
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline,
              size: 24,
              color: Colors.white,
            ),
          ),
        ],
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _ProPublicViewScreenState extends State<ProPublicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  final _conversationService = ConversationService();
  final TextEditingController _reviewController = TextEditingController();

  String _selectedAnnonceFilter = 'Tout';
  String? _currentUserId;

  // Media gallery state
  int _selectedMediaTab = 0; // 0 = photos, 1 = videos

  List<Map<String, dynamic>> _bonPlans = [];
  List<Map<String, dynamic>> _jobOffers = [];
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingAnnonces = true;
  String? _annoncesError;

  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  // Reviews - now dynamic from backend
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  String? _reviewsError;
  int _reviewRating = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  bool _isLoadingProfile = true;
  Map<String, dynamic>? _profileResponse;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // Check if viewing own profile by comparing widget.userId with current user's ID
  bool get _isViewingOwnProfile {
    final currentUserId = UserSession().id?.toString();
    final viewingUserId = widget.userId;

    // If no userId provided, it's own profile
    if (viewingUserId == null) return true;

    // If userId matches current user's ID, it's own profile
    return viewingUserId == currentUserId;
  }

  int get _totalCount =>
      _bonPlans.length +
      _jobOffers.length +
      _events.length +
      _demandes.length +
      _trainings.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    ReactionCacheService.init().then((_) => _loadProfile());
    _getCurrentUserId();
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return m <= 1 ? 'il y a 1 minute' : 'il y a $m minutes';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return h <= 1 ? 'il y a 1 heure' : 'il y a $h heures';
      }
      if (diff.inDays < 7) {
        final d = diff.inDays;
        return d <= 1 ? 'il y a 1 jour' : 'il y a $d jours';
      }
      final w = (diff.inDays / 7).floor();
      return w <= 1 ? 'il y a 1 semaine' : 'il y a $w semaines';
    } catch (_) {
      return '';
    }
  }

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _workTimeLabel(String workTime) {
    switch (workTime) {
      case 'full_time':
        return 'Temps plein';
      case 'part_time':
        return 'Temps partiel';
      case 'freelance':
        return 'Freelance';
      case 'internship':
        return 'Stage';
      default:
        return workTime;
    }
  }

  Widget _buildBonPlansList() {
    final items = _bonPlans;
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: const Text(
                'Aucune annonce',
                style: TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(children: items.map((bp) => _buildBonPlanCard(bp)).toList());
  }

  Widget _buildJobOffersList() {
    final items = _jobOffers;
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: const Text(
                'Aucune annonce',
                style: TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(children: items.map((jo) => _buildJobOfferCard(jo)).toList());
  }

  Widget _buildTrainingsList() {
    final items = _trainings;
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: const Text(
                'Aucune annonce',
                style: TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(children: items.map((tr) => _buildTrainingCard(tr)).toList());
  }

  Widget _buildEventsList() {
    final items = _events;
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: const Text(
                'Aucune annonce',
                style: TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(children: items.map((ev) => _buildEventCard(ev)).toList());
  }

  Widget _buildDemandesList() {
    final items = _demandes;
    if (items.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: const Text(
                'Aucune annonce',
                style: TextStyle(color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    return Column(children: items.map((d) => _buildDemandeCard(d)).toList());
  }

  Widget _buildTypeTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Handle already complete URLs (both http:// and https://)
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return url;
    }
    // Handle URLs that might incorrectly start with /storage/ followed by http
    if (url.startsWith('/storage/http')) {
      // Extract the actual URL after /storage/
      final actualUrl = url.substring(9); // Remove '/storage/'
      if (actualUrl.toLowerCase().startsWith('http://') ||
          actualUrl.toLowerCase().startsWith('https://')) {
        return actualUrl;
      }
    }
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$serverBase/storage/$cleanUrl';
  }

  Widget _buildBonPlanDescription(Map<String, dynamic> item) {
    final descriptionPlain = item['description']?.toString() ?? '';
    final cleanText = _stripHtml(descriptionPlain);

    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ExpandableDescription(text: cleanText);
  }

  // Expandable description widget with "voir plus" functionality
  Widget _ExpandableDescription({required String text}) {
    return _ExpandableDescriptionStateful(text: text);
  }

  void _showEntityCommentsSheet(String apiSlug, String entityId) {
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    String? error;
    final commentCtrl = TextEditingController();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            // Load on first build
            if (isLoading && comments.isEmpty && error == null) {
              ApiClient()
                  .authenticatedGet('/$apiSlug/$entityId/comments?per_page=50')
                  .then((response) {
                    final data = response['data'];
                    List<Map<String, dynamic>> fetched = [];
                    if (data is Map && data['data'] is List) {
                      fetched = List<Map<String, dynamic>>.from(
                        data['data'] as List,
                      );
                    } else if (data is List) {
                      fetched = List<Map<String, dynamic>>.from(data);
                    }
                    modalSetState(() {
                      comments = fetched;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    modalSetState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  });
            }

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments',
                    body: {'body': text},
                  );
                }
                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = comments.firstWhere(
                        (c) => c['id'] == replyingToId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (parent.isNotEmpty) {
                        final replies = List<Map<String, dynamic>>.from(
                          (parent['replies'] as List?) ?? [],
                        );
                        replies.add(newComment);
                        parent['replies'] = replies;
                        parent['replies_count'] =
                            (parent['replies_count'] as int? ?? 0) + 1;
                      }
                    } else {
                      comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  // Update local comments count in feed
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
                    ReactionCacheService.saveCommentsCount(
                      apiSlug,
                      entityId,
                      data.commentsCount,
                    );
                  });
                }
                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();

                // Refresh reaction counts from API to ensure accuracy
                await _refreshReactionFromApi(apiSlug, entityId);

                // Award 1 My for posting a comment (silently, no modal)
                try {
                  final mysResponse = await MysEarningService().awardMys(
                    actionType: 'comment',
                    referenceId: newComment?['id']?.toString(),
                  );
                  if (mysResponse['success'] == true) {
                    final newBalance = mysResponse['earning']?['new_balance'];
                    if (newBalance != null) {
                      UserSession().updateMys(newBalance);
                    }
                  }
                } catch (e) {
                  debugPrint("Error awarding My's for comment: $e");
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            }

            Future<void> toggleCommentReaction(
              Map<String, dynamic> comment,
              String type,
            ) async {
              final commentId = comment['id'];
              try {
                final response = await ApiClient().authenticatedPost(
                  '/comments/$commentId/reactions',
                  body: {'type': type},
                );
                final respData = response['data'] as Map<String, dynamic>?;
                if (respData != null) {
                  modalSetState(() {
                    comment['likes_count'] = respData['likes_count'];
                    comment['user_reaction'] = respData['user_reaction'];
                  });
                }
              } catch (e) {
                debugPrint('Comment reaction error: $e');
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);

              final newText = await showDialog<String>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (newText == null ||
                  newText.trim().isEmpty ||
                  newText == currentBody)
                return;

              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment =
                    response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  modalSetState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });

                  // Recharger le feed pour actualiser les commentaires
                  // await _loadUnifiedFeed(reset: true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la modification: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(
              Map<String, dynamic> comment,
              bool isReply,
            ) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');

                // Update local comments count in feed
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }

                // Refresh reaction counts from API to ensure accuracy
                await _refreshReactionFromApi(apiSlug, entityId);

                // Recharger le feed pour actualiser les commentaires
                // await _loadUnifiedFeed(reset: true);

                modalSetState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    comments.removeWhere((c) => c['id'] == commentId);
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Widget buildCommentItem(
              Map<String, dynamic> comment, {
              bool isReply = false,
            }) {
              final user = comment['user'] as Map<String, dynamic>? ?? {};
              final userId = user['id']?.toString(); // Convertir en String
              final email = user['email']?.toString() ?? '';

              final userProfile = user['pro_profile'] != null
                  ? user['pro_profile']
                  : user['particulier_profile'];

              final displayName = (userId != null && userId == _currentUserId)
                  ? 'Vous'
                  : (userProfile['pseudo']?.toString() ??
                        userProfile['company_name']?.toString() ??
                        email.split('@').first);
              final body = comment['body']?.toString() ?? '';
              final createdAt = comment['created_at']?.toString();
              final likes = _asInt(comment['likes_count']);
              final userReaction = comment['user_reaction']?.toString();
              final isOwner = userId != null && userId == _currentUserId;
              print("UserId: $userId");
              print("_currentUserId: $_currentUserId");
              print("isOwner: $isOwner");
              final replies =
                  (comment['replies'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [];
              // Get avatar URL from user data - check nested profiles
              final particulierProfile =
                  user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl =
                  particulierProfile?['avatar_url']?.toString() ??
                  proProfile?['avatar_url']?.toString() ??
                  proProfile?['logo_url']?.toString() ??
                  user['avatar_url']?.toString();

              return Padding(
                padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isReply ? 14 : 18,
                          backgroundColor: const Color(0xFFE6F7EF),
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(
                                  ApiConfig.resolveMediaUrl(avatarUrl) ??
                                      avatarUrl,
                                )
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: isReply ? 11 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2A8143),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: isReply ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _buildTimeAgo(createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                        showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                          ),
                                          items: [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Modifier'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Supprimer',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ).then((value) {
                                          if (value == 'edit') {
                                            editComment(comment);
                                          } else if (value == 'delete') {
                                            deleteComment(comment, isReply);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4F4F4F),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        toggleCommentReaction(comment, 'like'),
                                    child: Row(
                                      children: [
                                        Icon(
                                          userReaction == 'like'
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          size: 14,
                                          color: userReaction == 'like'
                                              ? const Color(0xFF3AAE5E)
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$likes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: userReaction == 'like'
                                                ? const Color(0xFF3AAE5E)
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isReply) ...[
                                    const SizedBox(width: 14),
                                    GestureDetector(
                                      onTap: () {
                                        modalSetState(() {
                                          replyingToId = comment['id'] as int?;
                                          replyingToName = displayName;
                                        });
                                        FocusScope.of(
                                          ctx,
                                        ).requestFocus(FocusNode());
                                      },
                                      child: Text(
                                        'Répondre',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E9B5B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Nested replies
                    if (!isReply && replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...replies.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: buildCommentItem(r, isReply: true),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Commentaires',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Comment list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? Center(
                              child: Text(
                                'Erreur: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, i) =>
                                  buildCommentItem(comments[i]),
                            ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Reply indicator
                    if (replyingToId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            Text(
                              'Répondre à $replyingToName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Écrire un commentaire...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => submitComment(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: submitComment,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3AAE5E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) =>
      '${apiSlug}_$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromResource(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource,
  ) {
    final key = _reactionKey(apiSlug, entityId);
    if (!_reactions.containsKey(key)) {
      final apiReaction = resource['user_reaction']?.toString();
      final userReaction = ReactionCacheService.isCached(apiSlug, entityId)
          ? ReactionCacheService.load(apiSlug, entityId)
          : apiReaction;
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      final apiCommentsCount = _asInt(resource['comments_count']);
      final cachedCommentsCount = ReactionCacheService.loadCommentsCount(
        apiSlug,
        entityId,
      );
      _reactions[key] = _ReactionData(
        likesCount: (cachedCount != null && cachedCount > apiCount)
            ? cachedCount
            : apiCount,
        commentsCount:
            (cachedCommentsCount != null &&
                cachedCommentsCount > apiCommentsCount)
            ? cachedCommentsCount
            : apiCommentsCount,
        userReaction: userReaction,
      );
    }
  }

  Future<void> _refreshReactionFromApi(String apiSlug, String entityId) async {
    try {
      final response = await ApiClient().authenticatedGet(
        '/$apiSlug/$entityId',
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          final key = _reactionKey(apiSlug, entityId);
          final apiLikesCount = _asInt(data['likes_count']);
          final apiCommentsCount = _asInt(data['comments_count']);
          final apiReaction = data['user_reaction']?.toString();
          final currentData = _getReaction(apiSlug, entityId);
          final preservedLikesCount = apiLikesCount > currentData.likesCount
              ? apiLikesCount
              : currentData.likesCount;
          final preservedCommentsCount =
              apiCommentsCount > currentData.commentsCount
              ? apiCommentsCount
              : currentData.commentsCount;
          final cachedReaction = ReactionCacheService.load(apiSlug, entityId);
          final preservedReaction =
              currentData.userReaction ?? cachedReaction ?? apiReaction;
          _reactions[key] = _ReactionData(
            likesCount: preservedLikesCount,
            commentsCount: preservedCommentsCount,
            userReaction: preservedReaction,
          );
          ReactionCacheService.saveCount(
            apiSlug,
            entityId,
            preservedLikesCount,
          );
          ReactionCacheService.saveCommentsCount(
            apiSlug,
            entityId,
            preservedCommentsCount,
          );
          ReactionCacheService.save(apiSlug, entityId, preservedReaction);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing reaction: $e');
    }
  }

  Future<void> _toggleReaction(
    String apiSlug,
    String entityId,
    String type,
  ) async {
    final data = _getReaction(apiSlug, entityId);

    // Optimistic update
    final oldReaction = data.userReaction;
    final oldLikes = data.likesCount;

    setState(() {
      if (oldReaction == type) {
        data.userReaction = null;
        if (type == 'like') data.likesCount--;
      } else {
        if (oldReaction == 'like') data.likesCount--;
        data.userReaction = type;
        if (type == 'like') data.likesCount++;
      }
    });

    try {
      final response = await ApiClient().authenticatedPost(
        '/$apiSlug/$entityId/reactions',
        body: {'type': type},
      );
      final respData = response['data'] as Map<String, dynamic>?;
      if (respData != null && mounted) {
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = respData['user_reaction']?.toString();
        });
        ReactionCacheService.save(
          apiSlug,
          entityId,
          respData['user_reaction']?.toString(),
        );
        ReactionCacheService.saveCount(apiSlug, entityId, data.likesCount);
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
      if (mounted) {
        setState(() {
          data.likesCount = oldLikes;
          data.userReaction = oldReaction;
        });
      }
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }


  Widget _buildAuthorInfo(Map<String, dynamic> authorData) {
    // Extract profile data based on account type
    final accountType = authorData['account_type']?.toString();
    final proProfile = authorData['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        authorData['particulier_profile'] as Map<String, dynamic>?;

    // Get the appropriate profile
    final profile = proProfile != null ? proProfile : particulierProfile;

    // Extract name from profile or fallback to direct fields
    final name =
        profile?['company_name']?.toString() ??
        '${profile?['first_name']?.toString() ?? ''} ${profile?['last_name']?.toString() ?? ''}'
            .trim();

    // Extract avatar from profile or fallback to direct fields
    final avatarUrl =
        profile?['avatar_url']?.toString() ?? profile?['avatar']?.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            image:
                avatarUrl != null &&
                    avatarUrl.isNotEmpty &&
                    (avatarUrl.startsWith("https") ||
                        avatarUrl.startsWith("http"))
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : (avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            "${ApiConfig.baseUrl.replaceAll("/api", "")}/storage/$avatarUrl",
                          ),
                          fit: BoxFit.cover,
                        )
                      : null),
          ),
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, size: 16, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isNotEmpty ? name : 'Utilisateur',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (accountType == 'pro')
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _repostPost(
    String postId, {
    Map<String, dynamic>? originalPostData,
  }) async {
    final textController = TextEditingController();
    bool isSubmitting = false;

    // Fetch current user info for the modal header
    String userName = 'Vous';
    String userAvatar = _defaultAvatar;
    try {
      final resp = await ApiClient().authenticatedGet('/profile/me');
      final userData = resp['user'] as Map<String, dynamic>?;
      final profile = resp['profile'] as Map<String, dynamic>?;
      if (profile != null) {
        userName =
            profile['company_name']?.toString() ??
            profile['pseudo']?.toString() ??
            userData?['name']?.toString() ??
            'Vous';
        final av = profile['avatar_url']?.toString();
        if (av != null) {
          userAvatar = _buildStorageUrl(av) ?? _defaultAvatar;
        }
      }
    } catch (_) {}

    // Extract original post info for preview
    String originalAuthorName = '';
    String originalContent = '';
    String originalTimeAgo = '';
    String originalProfil = '';
    List<String> originalMediaUrls = [];
    if (originalPostData != null) {
      final origPost =
          originalPostData['original_post'] as Map<String, dynamic>? ??
          originalPostData;
      final origAuthor = _extractPostAuthorInfo(origPost);
      originalAuthorName = origAuthor.displayName;
      originalContent = origPost['content']?.toString() ?? '';
      originalTimeAgo = _buildTimeAgo(origPost['created_at']?.toString());
      originalMediaUrls = _extractAllMediaUrls(origPost);
      originalProfil = origPost['author']['avatar_url'];
    }

    if (!mounted) return;

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Republier cette publication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User profile row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: userAvatar.startsWith('http')
                                      ? NetworkImage(userAvatar)
                                      : AssetImage(userAvatar) as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Text(
                                        'Public',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Text input
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: TextField(
                              controller: textController,
                              maxLines: 5,
                              minLines: 2,
                              maxLength: 300,
                              decoration: InputDecoration(
                                hintText:
                                    'Ajoutez un commentaire à votre republication...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                counterStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF333333),
                                height: 1.5,
                              ),
                              onChanged: (_) => modalSetState(() {}),
                            ),
                          ),
                          // Original post preview
                          if (originalPostData != null)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundImage: NetworkImage(
                                            originalProfil.startsWith('http')
                                                ? originalProfil
                                                : (_buildStorageUrl(
                                                        originalProfil,
                                                      ) ??
                                                      ''),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '$originalAuthorName • $originalTimeAgo',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (originalContent.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        8,
                                        12,
                                        0,
                                      ),
                                      child: Text(
                                        originalContent.length > 200
                                            ? '${originalContent.substring(0, 200)}...'
                                            : originalContent,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF555555),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  if (originalMediaUrls.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(11),
                                          bottomRight: Radius.circular(11),
                                        ),
                                        child: SizedBox(
                                          height: 180,
                                          width: double.infinity,
                                          child: Image.network(
                                            originalMediaUrls.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.image,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 12),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom action bar
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      MediaQuery.of(ctx).padding.bottom + 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                modalSetState(() => isSubmitting = true);
                                try {
                                  final body = <String, dynamic>{};
                                  final text = textController.text.trim();
                                  if (text.isNotEmpty) {
                                    body['repost_content'] = text;
                                  }
                                  await ApiClient().authenticatedPost(
                                    '/posts/$postId/repost',
                                    body: body,
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx, 'success');
                                  }
                                } catch (e) {
                                  modalSetState(() => isSubmitting = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3AAE5E),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Republier',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == 'success') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publication republiée avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
    Map<String, dynamic>? postData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';
    final isBonPlan = apiSlug == 'bon-plans';

    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                size: 18,
                color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.likesCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[600],
                  fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        // Comments
        GestureDetector(
          onTap: () => _showEntityCommentsSheet(apiSlug, entityId),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.commentsCount.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (isPost) ...[
          if (postData?['original_post_id'] == null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _repostPost(entityId, originalPostData: postData),
              child: Row(
                children: [
                  Icon(Icons.repeat_rounded, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    data.repostsCount > 0
                        ? data.repostsCount.toString()
                        : 'Republier',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
        // Share icon
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => ShareService.shareEntity(apiSlug, entityId),
          child: Icon(Icons.share_outlined, size: 18, color: Colors.grey[500]),
        ),
        // For bon plans: show author avatar and name on the left
        if (isBonPlan && authorData != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () {
              final userId = authorData['id']?.toString();
              final accountType = authorData['account_type']?.toString();
              if (userId != null && userId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => accountType?.toLowerCase() == 'pro'
                        ? ProPublicViewScreen(userId: userId)
                        : ParticulierPublicViewScreen(userId: userId),
                  ),
                );
              }
            },
            child: _buildAuthorInfo(authorData),
          ),
        ],
      ],
    );
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PUBLISHED':
        return 'Publié';
      case 'PENDING_REVIEW':
        return 'En attente';
      case 'DRAFT':
        return 'Brouillon';
      case 'REJECTED':
        return 'Rejeté';
      case 'ARCHIVED':
        return 'Archivé';
      default:
        return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PUBLISHED':
        return const Color(0xFF4CAF50);
      case 'PENDING_REVIEW':
        return const Color(0xFFFF9800);
      case 'DRAFT':
        return Colors.grey;
      case 'REJECTED':
        return const Color(0xFFF44336);
      case 'ARCHIVED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _buildImageUrl(String? url) {
    if (url == null) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    String fullUrl = url;
    if (url.startsWith('http')) {
      // fullUrl = url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
      fullUrl = url;
    } else {
      fullUrl = '$serverBase$url';
    }
    debugPrint('Image URL: $fullUrl');
    return fullUrl;
  }

  String _buildDeliveryInfo(Map<String, dynamic>? pickupMethods) {
    if (pickupMethods == null) return 'Non spécifié';
    final inStore = pickupMethods['in_store'] == true;
    final delivery = pickupMethods['delivery'] == true;
    if (inStore && delivery) return 'En magasin et livraison';
    if (inStore) return 'En magasin uniquement';
    if (delivery) return 'Livraison disponible';
    return 'Non spécifié';
  }

  List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return [];
    }
    final images = <String>[];
    for (final m in mediaFiles) {
      if (m is Map && m['url'] != null) {
        final url = _buildImageUrl(m['url']?.toString());
        if (url.isNotEmpty) {
          images.add(url);
        }
      }
    }
    return images;
  }

  Future<void> _navigateToBonPlanDetail(Map<String, dynamic> bp) async {
    final bonPlanId = bp['id']?.toString();
    if (bonPlanId == null || bonPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce bon plan')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/bonplans/$bonPlanId',
      );
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      // Use the enhanced user data with proper display name and avatar
      String profileImage = user?['avatar_url']?.toString() ?? '';
      if (profileImage.isEmpty) {
        profileImage = _buildImageUrl(user?['avatar']?.toString());
      }
      if (profileImage.isEmpty) {
        profileImage = 'assets/images/default_profile.png';
      }
      // Use display_name which contains company_name for pro or pseudo for particulier
      final username =
          user?['display_name']?.toString() ??
          user?['name']?.toString() ??
          'Mon bon plan';
      final userType = user?['account_type']?.toString() ?? 'Professionnel';
      final title = data['title']?.toString() ?? 'Bon plan';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final category = data['category']?.toString() ?? '';
      final subCategory = data['sub_category']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';
      final availableAt =
          data['available_at_name']?.toString() ?? 'Non spécifié';
      final validityType = data['validity_type']?.toString() ?? 'permanent';
      final validFrom = data['valid_from']?.toString();
      final validUntil = data['valid_until']?.toString();
      final link = data['link']?.toString();
      final pickupMethods = data['pickup_methods'] as Map<String, dynamic>?;
      final deliveryInfo = _buildDeliveryInfo(pickupMethods);
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final location = locationCity != null
          ? (locationPostalCode != null
                ? '$locationCity ($locationPostalCode)'
                : locationCity)
          : locationPostalCode;
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImages(mediaFiles);
      final reductionLabel = data['reduction_label']?.toString();
      // Extract price fields from API response (French field names)
      final price = data['prix_final']?.toString();
      final originalPrice = data['prix_avant_reduction']?.toString();

      final tags = <PostTag>[
        if (category.isNotEmpty)
          PostTag(
            title: category,
            icon: Icons.local_offer_outlined,
            color: Colors.orange,
          ),
        if (subCategory.isNotEmpty)
          PostTag(
            title: subCategory,
            icon: Icons.grid_view_outlined,
            color: Colors.grey,
          ),
        if (type.isNotEmpty)
          PostTag(
            title: type,
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
      ];

      if (!mounted) return;
      final acceptMessages = data['accept_messages'] == true;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProPostDetailScreen(
            images: images,
            discount: reductionLabel,
            avatar: profileImage,
            name: username,
            userType: userType,
            title: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            time: _timeAgo(data['created_at'].toString()),
            availability: availableAt,
            validityType: validityType,
            validFrom: validFrom,
            validUntil: validUntil,
            deliveryInfo: deliveryInfo,
            location: location,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            link: link,
            isOwner: true,
            bonPlanId: bonPlanId,
            bonPlanData: data,
            acceptMessages: acceptMessages,
            authorData: user,
            price: price,
            originalPrice: originalPrice,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadAnnonces();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      debugPrint('Error fetching bon plan detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  int _calculateDiscount(dynamic originalPrice, dynamic finalPrice) {
    final original = double.tryParse(originalPrice.toString()) ?? 0;
    final finalP = double.tryParse(finalPrice.toString()) ?? 0;
    if (original <= 0 || finalP <= 0 || finalP >= original) return 0;
    final discount = ((original - finalP) / original * 100).round();
    return discount;
  }

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final bpId = bp['id']?.toString() ?? '';
    final title = bp['title']?.toString() ?? '';
    final category = bp['category']?.toString() ?? '';
    final subCategory = bp['sub_category']?.toString() ?? '';
    final type = bp['type']?.toString() ?? '';
    final merchantName = bp['available_at_name']?.toString() ?? '';
    final locationType = bp['available_location_type']?.toString() ?? '';
    final createdAt = bp['created_at']?.toString();
    // Support both media_files (from BonPlanController) and media (from FeedController)
    final mediaFiles = (bp['media_files'] as List? ?? [])
      ..addAll(bp['media'] as List? ?? []);
    final imageUrls = mediaFiles
        .where((m) => m['type'] == 'image' || m['type'] == null)
        .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    // Check if already favorited by current user
    bool favoris = bp['is_favorited'];
    final currentUserId = UserSession().id;

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading) return;

          // Toggle immediately for responsive UI
          favoris = !favoris;
          setState(() => _isLoading = true);

          try {
            if (!favoris) {
              // Remove from favorites
              await ApiClient().authenticatedDelete('/bonplans/$bpId/favorite');
              // Update underlying data to persist state across rebuilds
              bp['is_favorited'] = false;
              if (bp['bon_plan_favorites'] is List) {
                (bp['bon_plan_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == currentUserId ||
                          f['user']?['id']?.toString() == currentUserId),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/bonplans/$bpId/favorite');
              // Update underlying data to persist state across rebuilds
              bp['is_favorited'] = true;
              if (bp['bon_plan_favorites'] is! List) {
                bp['bon_plan_favorites'] = [];
              }
              (bp['bon_plan_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            }

            setState(() {
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    favoris ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            favoris = !favoris;
            bp['is_favorited'] = favoris;
            setState(() {
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour des favoris'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image carousel at top
                  if (imageUrls.isNotEmpty)
                    _buildBonPlanImageCarousel(imageUrls),

                  // Title
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      imageUrls.isNotEmpty ? 16 : 56,
                      100,
                      0,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBonPlanDescription(bp),
                  ),
                  const SizedBox(height: 12),

                  // Price instead of tags
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        bp['prix_avant_reduction'] != null &&
                                bp['prix_final'] == null
                            ? Text(
                                '${bp['prix_avant_reduction']}€',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E9B5B),
                                ),
                              )
                            : (type == 'Infos pouvoir d\'achat'
                                  ? SizedBox.shrink()
                                  : Text(
                                      bp['prix_final'] != null &&
                                              bp['prix_final']
                                                  .toString()
                                                  .isNotEmpty
                                          ? '${bp['prix_final']}€'
                                          : 'Gratuit',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E9B5B),
                                      ),
                                    )),
                        if (bp['prix_final'] != null &&
                            bp['prix_avant_reduction'] != null &&
                            bp['prix_avant_reduction']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${bp['prix_avant_reduction']}€',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          // Discount badge
                          if (bp['prix_final'] != null &&
                              bp['prix_final'].toString().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${_calculateDiscount(bp['prix_avant_reduction'], bp['prix_final'])}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                        // Promo code as tag
                        if (bp['promo_code'] != null &&
                            bp['promo_code'].toString().isNotEmpty) ...[
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E9B5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2E9B5B),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer_outlined,
                                    size: 14,
                                    color: Color(0xFF2E9B5B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Code promo: ${bp['promo_code']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E9B5B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Merchant + time
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (merchantName.isNotEmpty) ...[
                          Icon(
                            Icons.store_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$locationType chez $merchantName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        if (createdAt != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _buildTimeAgo(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                  const SizedBox(height: 10),
                  if (bpId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildReactionBar(
                        'bon-plans',
                        bpId,
                        acceptedMessages: bp['accept_messages'] == true,
                        authorData: bp['user'] as Map<String, dynamic>?,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1),
                  ),
                  const SizedBox(height: 12),
                  // CTA Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToBonPlanDetail(bp),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('VOIR LE BON PLAN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Favorite button at top-left
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: _isLoading ? null : _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[600],
                            ),
                          )
                        : Icon(
                            favoris ? Icons.favorite : Icons.favorite_border,
                            color: favoris ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                  ),
                ),
              ),
              // Bon Plan tag at top-right
              Positioned(
                top: 12,
                right: 12,
                child: _buildTypeTag(
                  'Bon Plan',
                  const Color(0xFFFF9800),
                  Icons.local_offer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String? _buildJobSalaryDisplay(Map<String, dynamic> job) {
    final min = job['salary_min'];
    final max = job['salary_max'];
    final exact = job['salary_exact'];
    final paymentType = job['salary_payment_type']?.toString(); // brut/net
    final period = job['salary_period']?.toString(); // horaire/mensuel/annuel

    // Build period label
    String periodLabel = '';
    if (period == 'horaire')
      periodLabel = '/h';
    else if (period == 'mensuel')
      periodLabel = '/mois';
    else if (period == 'annuel')
      periodLabel = '/an';

    // Build payment label (brut/net)
    String paymentLabel = paymentType == 'brut'
        ? ' brut'
        : (paymentType == 'net' ? ' net' : '');

    // If we have both min and max, show range
    if (min != null && max != null) {
      return '${min}€ - ${max}€$periodLabel$paymentLabel';
    }

    // If we have exact salary
    if (exact != null) {
      return '${exact}€$periodLabel$paymentLabel';
    }

    // If we have only min
    if (min != null) {
      return 'À partir de ${min}€$periodLabel$paymentLabel';
    }

    // If we have only max
    if (max != null) {
      return 'Jusqu\'à ${max}€$periodLabel$paymentLabel';
    }

    // Check for salary_type = selon_profil
    final salaryType = job['salary_type']?.toString();
    if (salaryType == 'selon_profil') {
      return 'Selon profil';
    }

    return null; // No salary info available
  }

  String _formatJobSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Salaire non spécifié';
  }

  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserId != null) {
      return _currentUserId;
    }
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final data = response['user'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();

      // Sync mys and parrainage_code to UserSession
      if (data != null) {
        final mys = data['mys'];
        final parrainageCode = data['parrainage_code'];
        if (mys != null) {
          UserSession().updateMys(mys);
        }
        if (parrainageCode != null) {
          UserSession().updateParrainageCode(parrainageCode);
        }
      }

      if (mounted) {
        setState(() => _currentUserId = id);
      } else {
        _currentUserId = id;
      }
      return id;
    } catch (e) {
      debugPrint('Error fetching current user ID: $e');
      return _currentUserId;
    }
  }

  Future<void> _navigateToJobOfferDetail(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir cette offre d\'emploi'),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/job-offers/$jobId');
      Navigator.pop(context); // Dismiss loading

      final data = response['data'] as Map<String, dynamic>? ?? response;

      debugPrint('JOB DETAIL API response keys: ${data.keys.toList()}');
      debugPrint(
        'JOB DETAIL description type: ${data['description']?.runtimeType}',
      );
      debugPrint('JOB DETAIL description value: ${data['description']}');
      debugPrint('JOB DETAIL description_delta: ${data['description_delta']}');
      // Check all keys that contain 'desc'
      data.forEach((key, value) {
        if (key.toLowerCase().contains('desc') ||
            key.toLowerCase().contains('delta')) {
          debugPrint(
            'JOB DETAIL key=$key type=${value?.runtimeType} value=$value',
          );
        }
      });

      // Extract job offer details
      final title = data['title']?.toString() ?? '';
      final descriptionRaw = data['description'];
      final description = descriptionRaw?.toString() ?? '';
      final descriptionDelta =
          data['description_delta'] ??
          (descriptionRaw is List ? descriptionRaw : null);
      final profileDescription = data['profile_description']?.toString();
      final companyName = data['company_name']?.toString() ?? 'Entreprise';
      final companyWebsite = data['company_website']?.toString() ?? '';
      final contractTypeRaw = data['contract_type'];
      final contractType = contractTypeRaw is Map
          ? (contractTypeRaw['name'] ?? contractTypeRaw.toString())
          : (contractTypeRaw?.toString() ?? '');
      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map
          ? (workTimeRaw['name'] ?? workTimeRaw.toString())
          : (workTimeRaw?.toString() ?? '');
      final locationRaw = data['location'];
      final location = locationRaw is Map
          ? (locationRaw['city'] ??
                locationRaw['name'] ??
                locationRaw.toString())
          : (locationRaw?.toString() ?? '');
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString())
          : (categoryRaw?.toString() ?? '');
      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final advantagesRaw = data['advantages'];
      final advantages = advantagesRaw is List
          ? advantagesRaw
                .map(
                  (a) => a is Map ? (a['name'] ?? a.toString()) : a.toString(),
                )
                .toList()
          : <String>[];
      final createdAt = data['created_at']?.toString();
      final mediaRaw =
          data['media'] as List? ?? data['media_files'] as List? ?? [];
      final remoteWork = data['remote_work'] == true;
      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
          : educationLevelRaw?.toString();
      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
          : experienceLevelRaw?.toString();

      // Build images list
      final images = mediaRaw
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString() ?? '') ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      if (images.isEmpty) {
        images.add('assets/images/dashboard_particulier/Rectangle 13.png');
      }

      // Build tags
      final tags = <JobDetailTag>[
        if (contractType.isNotEmpty)
          JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime.isNotEmpty)
          JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (educationLevel != null && educationLevel.isNotEmpty)
          JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatJobSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      // Build advantages list
      final advantagesList = advantages
          .take(3)
          .map((a) => a.toString())
          .toList();

      // Check ownership
      final jobUserId =
          job['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          jobUserId != null &&
          currentUserId != null &&
          jobUserId == currentUserId;

      // Get user data and accept_messages
      final user = data['user'] as Map<String, dynamic>?;
      final acceptMessages = data['accept_messages'] == true;

      String companyLogo = '';
      if (user != null) {
        final particulierProfile =
            user['particulier_profile'] is Map<String, dynamic>
            ? user['particulier_profile'] as Map<String, dynamic>
            : null;
        final proProfile = user['pro_profile'] is Map<String, dynamic>
            ? user['pro_profile'] as Map<String, dynamic>
            : null;
        companyLogo =
            (particulierProfile?['avatar_url'] ??
                    proProfile?['avatar_url'] ??
                    proProfile?['logo_url'])
                ?.toString() ??
            '';
      }

      final resolvedCompanyLogo =
          _buildStorageUrl(companyLogo) ??
          'assets/images/dashboard_particulier/Rectangle 13.png';

      // Navigate to detail screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo: companyLogo,
            companyName: companyName,
            companyWebsite: companyWebsite,
            jobTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            profileDescription: profileDescription,
            tags: tags,
            postTags: <PostTag>[
              if (workTime.isNotEmpty)
                PostTag(
                  title: workTime,
                  icon: Icons.access_time,
                  color: Colors.grey,
                ),
            ],
            subtags: contractType.isNotEmpty
                ? PostTag(
                    title: contractType,
                    icon: Icons.description_outlined,
                    color: const Color(0xFF27A5FF),
                  )
                : null,
            advantages: advantagesList,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            location: location,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobId,
            jobOfferData: data,
            acceptMessages: acceptMessages,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadAnnonces();
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Widget _buildJobOfferCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location =
        job['location']?.toString() ??
        job['city']?.toString() ??
        'Non spécifié';
    final contract = job['contract_type']?.toString() ?? '';
    final experience = job['experience_level']?.toString() ?? '';
    final salary =
        job['salary_label']?.toString() ??
        _buildJobSalaryDisplay(job) ??
        job['salary']?.toString();

    // Check initial favorite status
    bool favoris = job['is_favorited'];

    final tags = <JobDetailTag>[
      // 1st: Place (location)
      if (location.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: location),
      // 2nd: Contract duration
      if (contract.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contract),
      // 3rd: Salary (depending on type)
      if (salary != null && salary.isNotEmpty)
        JobDetailTag(icon: Icons.euro, text: salary, isSpecial: true),
    ];

    final user = job['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;

    final avatarUrl = proProfile?['avatar_url']?.toString() ?? '';

    final companyName = proProfile?['company_name']?.toString() ?? 'Entreprise';

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ??
        'assets/images/dashboard_particulier/Rectangle 13.png';

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || jobId.isEmpty) return;

          // Toggle immediately for responsive UI
          favoris = !favoris;
          setState(() => _isLoading = true);

          try {
            if (!favoris) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              job['is_favorited'] = false;
              if (job['job_offer_favorites'] is List) {
                (job['job_offer_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == UserSession().id ||
                          f['user']?['id']?.toString() == UserSession().id),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              job['is_favorited'] = true;
              if (job['job_offer_favorites'] is! List) {
                job['job_offer_favorites'] = [];
              }
              (job['job_offer_favorites'] as List).add({
                'user_id': UserSession().id,
                'user': {'id': UserSession().id},
              });
            }

            setState(() {
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    favoris ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            favoris = !favoris;
            job['is_favorited'] = favoris;
            setState(() => _isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return JobAnnouncementCard(
          companyLogo: companyLogoUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isFavorited: favoris,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToJobOfferDetail(job),
          onAvatarTap: () {},
          reactionBar: jobId.isNotEmpty
              ? _buildReactionBar('job-offers', jobId)
              : null,
        );
      },
    );
  }

  String _formatSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Salaire non spécifié';
  }

  Future<void> _navigateToTrainingDetail(Map<String, dynamic> tr) async {
    final trainingId = tr['id']?.toString();
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette formation')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/trainings/$trainingId',
      );
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final companyName =
          data['company_name']?.toString() ??
          data['provider_name']?.toString() ??
          'Organisme';
      final website = data['website']?.toString();
      final trainingType = data['training_type']?.toString();
      final trainingCategory = data['training_category']?.toString();
      final trainingSubCategory = data['training_sub_category']?.toString();
      final trainingStyleRaw = data['training_style'];
      final trainingStyle = trainingStyleRaw is List
          ? trainingStyleRaw.map((e) => e.toString()).toList()
          : <String>[];
      final trainingPublicRaw = data['training_public'];
      final trainingPublic = trainingPublicRaw is List
          ? trainingPublicRaw.map((e) => e.toString()).toList()
          : <String>[];
      final requiredLevelsRaw = data['required_levels'];
      final requiredLevels = requiredLevelsRaw is List
          ? requiredLevelsRaw.map((e) => e.toString()).toList()
          : <String>[];
      final price = data['price']?.toString();
      final priceType = data['price_type']?.toString();
      final publicType = data['public_type']?.toString();
      final tempo = data['tempo']?.toString();
      final trainingFundingRaw = data['training_funding'];
      final trainingFunding = trainingFundingRaw is List
          ? trainingFundingRaw.map((e) => e.toString()).toList()
          : <String>[];
      final durationInH = data['duration_in_h'] is int
          ? data['duration_in_h'] as int
          : int.tryParse(data['duration_in_h']?.toString() ?? '');
      final durationUnit = data['duration_unit']?.toString();
      final startDate = data['start_date']?.toString();
      final endDate = data['end_date']?.toString();
      final dateToDefine = data['date_to_define'] == true;
      final addressCity = data['address_city']?.toString();
      final addressZipcode = data['address_zipcode']?.toString();
      final addressLine1 = data['address_line1']?.toString();
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final showLocation = data['show_location'] == true;
      final certificationRaw = data['certification'];
      final certification = certificationRaw is List
          ? certificationRaw.map((e) => e.toString()).toList()
          : <String>[];
      final documentFilesRaw = data['document_files'] as List? ?? [];
      final documents = documentFilesRaw
          .where((d) => d is Map)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final tags = <FormationTag>[
        if (trainingCategory != null && trainingCategory.isNotEmpty)
          FormationTag(icon: Icons.category_outlined, text: trainingCategory),
        if (trainingSubCategory != null && trainingSubCategory.isNotEmpty)
          FormationTag(
            icon: Icons.subdirectory_arrow_right,
            text: trainingSubCategory,
          ),
        if (trainingType != null && trainingType.isNotEmpty)
          FormationTag(icon: Icons.school_outlined, text: trainingType),
        if (durationInH != null)
          FormationTag(icon: Icons.timer_outlined, text: '$durationInH h'),
        if (price != null)
          FormationTag(icon: Icons.euro, text: '$price €', isSpecial: true),
      ];

      // Check ownership
      final trainingUserId =
          tr['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          trainingUserId != null &&
          currentUserId != null &&
          trainingUserId == currentUserId;

      // Extract user data for owner card
      final userData = data['user'] as Map<String, dynamic>?;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingDetailScreen(
            images: images,
            companyLogo: 'assets/images/Formation.png',
            companyName: companyName,
            trainingTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            website: website,
            trainingType: trainingType,
            trainingCategory: trainingCategory,
            trainingSubCategory: trainingSubCategory,
            trainingStyle: trainingStyle,
            trainingPublic: trainingPublic,
            requiredLevels: requiredLevels,
            price: price,
            priceType: priceType,
            publicType: publicType,
            tempo: tempo,
            trainingFunding: trainingFunding,
            durationInH: durationInH,
            durationUnit: durationUnit,
            startDate: startDate,
            endDate: endDate,
            dateToDefine: dateToDefine,
            addressCity: addressCity,
            addressZipcode: addressZipcode,
            addressLine1: addressLine1,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            showLocation: showLocation,
            certification: certification,
            documents: documents,
            isOwner: isOwner,
            trainingId: trainingId,
            trainingData: data,
            returnToListingOnEdit: false,
            authorData: userData,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadAnnonces();
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final trainingId = training['id']?.toString() ?? '';
    final title = training['title']?.toString() ?? 'Formation';
    final description = _stripHtml(training['description']?.toString() ?? '');
    final provider = training['provider_name']?.toString() ?? 'Organisme';
    final duration = training['duration_in_h'];
    final durationUnit = training['duration_unit']?.toString();
    final price = training['price'];
    final category = training['training_category']?.toString() ?? '';
    final subCategory = training['training_sub_category']?.toString() ?? '';
    final trainingType = training['training_type']?.toString() ?? '';

    final addressCity = training['address_city']?.toString() ?? '';

    // Helper to extract array values
    String _extractArrayValues(dynamic field) {
      if (field is List) {
        return field
            .map((item) {
              if (item is Map)
                return item['value']?.toString() ??
                    item['name']?.toString() ??
                    '';
              return item.toString();
            })
            .where((s) => s.isNotEmpty)
            .join(' · ');
      }
      return field?.toString() ?? '';
    }

    // Translation for training_style
    String _translateTrainingStyle(String value) {
      switch (value.trim()) {
        case 'Remote':
          return 'En ligne';
        case 'OnSite':
          return 'Présentiel';
        case 'Hybrid':
          return 'Hybride';
        default:
          return value;
      }
    }

    // Extract and translate training_style values
    String trainingStyleText = '';
    final trainingStyleRaw = training['training_style'];
    if (trainingStyleRaw is List) {
      final translated = trainingStyleRaw
          .map((item) {
            final value = item is Map
                ? (item['value']?.toString() ?? item.toString())
                : item.toString();
            return _translateTrainingStyle(value);
          })
          .where((s) => s.isNotEmpty)
          .join(' · ');
      trainingStyleText = translated;
    } else if (trainingStyleRaw != null) {
      trainingStyleText = _translateTrainingStyle(trainingStyleRaw.toString());
    }

    // Translation for training_public
    String _translateTrainingPublic(String value) {
      switch (value.trim()) {
        case 'AllPublic':
          return 'Tout public';
        case 'Employed':
          return 'Salarié en poste';
        case 'JobSeeker':
          return 'Demandeurs d\'emploi';
        case 'Company':
          return 'Entreprise';
        case 'Student':
          return 'Étudiant';
        default:
          return value;
      }
    }

    // Extract and translate training_public values
    String trainingPublicText = '';
    final trainingPublicRaw = training['training_public'];
    if (trainingPublicRaw is List) {
      final translated = trainingPublicRaw
          .map((item) {
            final value = item is Map
                ? (item['value']?.toString() ?? item.toString())
                : item.toString();
            return _translateTrainingPublic(value);
          })
          .where((s) => s.isNotEmpty)
          .join(' · ');
      trainingPublicText = translated;
    } else if (trainingPublicRaw != null) {
      trainingPublicText = _translateTrainingPublic(
        trainingPublicRaw.toString(),
      );
    }

    final certification = _extractArrayValues(training['certification']);

    // Check if CPF is in training_funding array
    final trainingFunding = training['training_funding'];
    bool hasCpf = false;
    if (trainingFunding is List) {
      hasCpf = trainingFunding.any(
        (funding) =>
            funding.toString().toUpperCase() == 'CPF' ||
            (funding is Map &&
                funding['type']?.toString().toUpperCase() == 'CPF'),
      );
    }

    final tags = <FormationTag>[
      // 1st: Address city (location)
      if (addressCity.isNotEmpty)
        FormationTag(icon: Icons.location_on_outlined, text: addressCity),
      // 2nd: Training public (translated)
      if (trainingPublicText.isNotEmpty)
        FormationTag(icon: Icons.people_outline, text: trainingPublicText),
      // 3rd: Training style (translated)
      if (trainingStyleText.isNotEmpty)
        FormationTag(icon: Icons.style_outlined, text: trainingStyleText),
      // 4th: Certification
      if (certification.isNotEmpty)
        FormationTag(icon: Icons.verified_outlined, text: certification),
      // 5th: CPF eligibility
      if (hasCpf)
        FormationTag(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Eligible CPF',
        ),
      // 6th: Training type
      if (trainingType.isNotEmpty)
        FormationTag(icon: Icons.school_outlined, text: trainingType),
      // 7th: Duration
      if (duration != null)
        FormationTag(
          icon: Icons.timer_outlined,
          text: '$duration h${durationUnit != null ? ' / $durationUnit' : ''}',
        ),
      // 8th: Price (special/green) - LAST
      if (price != null) ...[
        () {
          final publicType = training['public_type']?.toString() ?? '';
          String priceText = '$price €';
          if (publicType == 'personne') {
            priceText += ' - Par personne';
          } else if (publicType == 'groupe') {
            priceText += ' - Par groupe';
          }
          return FormationTag(
            icon: Icons.euro,
            text: priceText,
            isSpecial: true,
          );
        }(),
      ],
    ];

    final user = training['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;

    final avatarUrl = proProfile?['avatar_url']?.toString();

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ?? 'assets/images/Formation.png';

    // Extract owner name from profiles
    final ownerName = proProfile?['company_name']?.toString();

    // Check if already favorited by current user
    final favoris = training['training_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    final bool initialIsFavorited =
        currentUserId != null &&
        favoris.any(
          (f) =>
              f is Map &&
              (f['user_id']?.toString() == currentUserId ||
                  f['user']?['id']?.toString() == currentUserId),
        );

    // Use ValueNotifier for state that persists across rebuilds
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoading = false;

        Future<void> _toggleFavorite() async {
          if (isLoading || trainingId.isEmpty) return;

          // Toggle immediately for responsive UI
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => isLoading = true);

          try {
            if (!isFavoritedNotifier.value) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/trainings/$trainingId/favorite',
              );
              // Update the underlying data to persist state across rebuilds
              if (training['training_favorites'] is List) {
                (training['training_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == currentUserId ||
                          f['user']?['id']?.toString() == currentUserId),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/trainings/$trainingId/favorite',
              );
              // Update the underlying data to persist state across rebuilds
              if (training['training_favorites'] is! List) {
                training['training_favorites'] = [];
              }
              (training['training_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            }

            setState(() {
              isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavoritedNotifier.value
                        ? 'Ajouté aux favoris'
                        : 'Retiré des favoris',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => isLoading = false);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour des favoris'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return FormationCard(
          companyLogo: companyLogoUrl,
          companyName: ownerName ?? "",
          formationTitle: title,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(training['created_at']?.toString()),
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToTrainingDetail(training),
          onAvatarTap: () {},
          reactionBar: trainingId.isNotEmpty
              ? _buildReactionBar('trainings', trainingId)
              : null,
        );
      },
    );
  }

  String get _defaultAvatar =>
      'assets/images/dashboard_particulier/Ellipse 10.png';

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('http')) return url;
          return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$url";
        }
      }
    }
    final cover = resource['cover_url']?.toString();
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('http')) return cover;
      return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$cover";
    }
    return null;
  }

  String _formatEventStatus(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || startDateStr.isEmpty) return 'À venir';
    try {
      final start = DateTime.parse(startDateStr);
      final now = DateTime.now();
      if (endDateStr != null && endDateStr.isNotEmpty) {
        final end = DateTime.parse(endDateStr);
        if (now.isAfter(end)) return 'Terminé';
      }
      if (now.isAfter(start)) return 'En cours';
      return 'À venir';
    } catch (_) {
      return 'À venir';
    }
  }

  String _formatEventDate(Map<String, dynamic> event) {
    final durationType = event['duration_type']?.toString();
    final eventDate = event['event_date']?.toString();
    final startDate = event['start_date']?.toString();
    final endDate = event['end_date']?.toString();

    String formatDate(String? iso) {
      if (iso == null) return '';
      try {
        final date = DateTime.parse(iso);
        const months = [
          'janvier',
          'février',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'août',
          'septembre',
          'octobre',
          'novembre',
          'décembre',
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (_) {
        return iso;
      }
    }

    if (durationType == 'permanent') return 'Permanent';

    // Handle multi_day with start/end dates like bon plan validity
    if (durationType == 'multi_day') {
      final hasStart = startDate != null && startDate.isNotEmpty;
      final hasEnd = endDate != null && endDate.isNotEmpty;

      if (hasStart && hasEnd) {
        final formattedStart = formatDate(startDate);
        final formattedEnd = formatDate(endDate);
        return 'Du $formattedStart Au $formattedEnd';
      } else if (hasStart) {
        final formatted = formatDate(startDate);
        return 'À partir du $formatted';
      } else if (hasEnd) {
        final formatted = formatDate(endDate);
        return 'Jusqu\'au $formatted';
      }
      return 'À partir de bientôt';
    }

    final formatted = formatDate(eventDate);
    return formatted.isNotEmpty
        ? 'A lieu, $formatted'
        : 'Date annoncée prochainement';
  }

  Future<void> _navigateToEventDetail(Map<String, dynamic> ev) async {
    final eventId = ev['id']?.toString();
    if (eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cet événement')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/events/$eventId');
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final categoryCode = data['category_code']?.toString();
      final subCategoryCode = data['sub_category_code']?.toString();
      final formatType = data['format_type']?.toString();
      final durationType = data['duration_type']?.toString();
      final eventDate = data['event_date']?.toString();
      final startDate = data['start_date']?.toString();
      final endDate = data['end_date']?.toString();
      final startTime = data['start_time']?.toString();
      final endTime = data['end_time']?.toString();
      final priceType = data['price_type']?.toString();
      final pricingMode = data['pricing_mode']?.toString();
      final priceAmount = data['price_amount']?.toString();
      final priceCategories =
          (data['price_categories'] as List?)
              ?.map<Map<String, dynamic>>(
                (c) => Map<String, dynamic>.from(c as Map),
              )
              .toList() ??
          <Map<String, dynamic>>[];
      final reservationMode = data['reservation_mode']?.toString();
      final coverageArea = data['coverage_area']?.toString();
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final isNationwide = data['is_nationwide'] == true;
      final organizerName = data['organizer_name']?.toString();
      final isOrganizer = data['is_organizer'] != false;
      final websiteUrl = data['website_url']?.toString();
      final landingUrl = data['landing_url']?.toString();
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      final tags = <PostTag>[
        if (categoryCode != null && categoryCode.isNotEmpty)
          PostTag(
            title: categoryCode,
            icon: Icons.local_offer_outlined,
            color: Colors.green,
          ),
        if (subCategoryCode != null && subCategoryCode.isNotEmpty)
          PostTag(
            title: subCategoryCode,
            icon: Icons.grid_view_outlined,
            color: Colors.grey,
          ),
        if (formatType != null && formatType.isNotEmpty)
          PostTag(
            title: formatType,
            icon: Icons.videocam_outlined,
            color: Colors.blue,
          ),
      ];

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: 'assets/images/default_profile.png',
            username: isOrganizer
                ? 'Mon événement'
                : (organizerName ?? 'Organisateur'),
            userType: 'Évènement',
            eventTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
            categoryCode: categoryCode,
            subCategoryCode: subCategoryCode,
            formatType: formatType,
            durationType: durationType,
            eventDate: eventDate,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            priceType: priceType,
            pricingMode: pricingMode,
            priceAmount: priceAmount,
            priceCategories: priceCategories,
            reservationMode: reservationMode,
            coverageArea: coverageArea,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            isNationwide: isNationwide,
            organizerName: organizerName,
            isOrganizer: isOrganizer,
            websiteUrl: websiteUrl,
            landingUrl: landingUrl,
            acceptMessages: acceptMessages,
            isOwner: true,
            eventId: eventId,
            eventData: data,
            returnToListingOnEdit: true,
            authorData: data['user'] as Map<String, dynamic>?,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadAnnonces();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  String _formatPrice(Map<String, dynamic> event) {
    final priceType = event['price_type']?.toString();

    // If price_type is gratuit or null, return "Gratuit"
    if (priceType == null || priceType == 'gratuit') {
      return 'Gratuit';
    }

    // If price_type is payant, check pricing_mode
    if (priceType == 'payant') {
      final pricingMode = event['pricing_mode']?.toString();

      // If pricing_mode is categories, get first price from price_categories
      if (pricingMode == 'categories') {
        final priceCategories = event['price_categories'] as List?;
        if (priceCategories != null && priceCategories.isNotEmpty) {
          final firstCategory = priceCategories[0] as Map<String, dynamic>?;
          if (firstCategory != null) {
            final price = firstCategory['price']?.toString();
            if (price != null && price.isNotEmpty) {
              return 'À partir de $price €';
            }
          }
        }
        return 'Payant';
      }

      // If pricing_mode is unique, get price_amount
      if (pricingMode == 'unique') {
        final priceAmount = event['price_amount']?.toString();
        if (priceAmount != null && priceAmount.isNotEmpty) {
          return '$priceAmount €';
        }
        return 'Payant';
      }

      return 'Payant';
    }

    return 'Gratuit';
  }

  /// Translates English sub-category codes to French labels
  String _translateSubCategory(String code) {
    const Map<String, String> translations = {
      'AfterworkTeamBuilding': 'Afterwork / Team Building',
      'ConferenceCongressSeminars': 'Conférence / Congrès / Séminaires',
      'SeminarOutings': 'Séminaire / Sorties',
      'TradeShowForumExhibition': 'Salon / Forum / Exposition',
      'OpenDay': 'Journée Portes Ouvertes',
      'EntrepreneurialNetworking': 'Réseautage entrepreneurial',
      'Music': 'Musique',
      'CreativeHobbies': 'Loisir créatifs',
      'MoviesSeries': 'Films & Séries',
      'BooksMagazines': 'Livres & Magazines',
      'ShowsTickets': 'Spectacles & Billeterie',
      'GamblingBetting': 'Jeux de hasard & paris',
      'SportsEvents': 'Événements Sportifs',
      'AutoMotoBoatPlane': 'Auto / Moto / Bateau / Avion',
      'TourismHikingGourmetWalk':
          'Tourisme / Visite / Randonnée / Marche Gourmande',
      'EsportsGamingEvents': 'Événements e-sport / Gaming',
      'WorkshopsInternshipsCourses': 'Ateliers / Stage / Cours',
      'ConferencesProfessionalTraining':
          'Conférences et formations professionnelles',
      'Associative': 'Associatifs',
      'AuctionsCharity': 'Enchères / Charité',
      'SolidarityEvents': 'Manifestations solidaires',
      'ChildrenMuseums': 'Enfants / Musées',
      'AnimalEvents': 'Manifestation Animalière',
      'WorkshopsShowsForChildren': 'Ateliers et spectacles pour enfants',
      'MarketFleaMarketCarBootSale':
          'Marché / Bourse / Brocante / Vide Grenier',
      'TradeFairs': 'Foires commerciales',
      'GamesContestsLottery': 'Jeux / Concours / Loterie',
      'BoardGameTournaments': 'Tournois de jeux de société',
      'TastingsWineCheeseChocolate': 'Dégustations (vin, fromage, chocolat...)',
      'CulinaryFestivals': 'Festivals culinaires',
      'CookingWorkshops': 'Ateliers cuisine',
      'MeditationYogaWellnessRetreats': 'Méditation, yoga, retraites bien-être',
      'ConferencesWorkshopsPersonalDevelopment':
          'Conférences et ateliers sur le développement personnel',
      'AlternativeHealingTherapies': 'Soins et thérapies alternatives',
      'Hackathons': 'Hackathons',
      'TechConferencesStartups': 'Conférences tech & start-up',
      'GamingEsportsEvents': 'Événements gaming & e-sport',
      'FashionShows': 'Défilés de mode',
      'BeautyExhibitionsFairs': 'Salons et foires de la beauté',
      'MakeupSkincareWorkshops': 'Ateliers maquillage et soins',
    };

    return translations[code] ?? code;
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final user = event['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;

    // Extract owner name from profiles
    final ownerName =
        proProfile?['company_name']?.toString() ??
        proProfile?['first_name']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        particulierProfile?['first_name']?.toString() ??
        user?['name']?.toString() ??
        'Organisateur';
    final eventTitle = event['title']?.toString() ?? 'Évènement';
    final eventImage = _extractMediaUrl(event) ?? '';
    final categories = <String>[
      if (event['category_label']?.toString().isNotEmpty ?? false)
        event['category_label'].toString(),
      if (event['sub_category_label']?.toString().isNotEmpty ?? false)
        event['sub_category_label'].toString(),
    ];
    final price = _formatPrice(event);
    final coverageArea =
        event['coverage_area']?.toString() ??
        event['location']?.toString() ??
        'Non spécifié';

    final eventId = event['id']?.toString() ?? '';

    // Build tags for display
    final tags = <String>[];

    // Add sub_category_code if available (and translate to French)
    final subCategoryCode = event['sub_category_code']?.toString();
    if (subCategoryCode != null && subCategoryCode.isNotEmpty) {
      tags.add(_translateSubCategory(subCategoryCode));
    }

    // Add format_type if available
    final formatType = event['format_type']?.toString();
    if (formatType != null && formatType.isNotEmpty) {
      const formatTranslations = {
        'Présentiel': 'Présentiel',
        'En ligne': 'En ligne',
        'Hybride': 'Hybride',
      };
      tags.add(formatTranslations[formatType] ?? formatType);
    }

    // Check if already favorited by current user
    bool favoris = event['is_favorited'] == true;

    final currentUserId = UserSession().id;

    return StatefulBuilder(
      builder: (context, cardSetState) {
        Future<void> _toggleFavorite() async {
          // Toggle immediately for responsive UI
          cardSetState(() {
            favoris = !favoris;
          });

          // Update underlying data immediately for persistence across rebuilds
          event['is_favorited'] = favoris;
          if (favoris) {
            // Add to favorites
            if (event['event_favorites'] is! List) {
              event['event_favorites'] = [];
            }
            // Check if already exists to avoid duplicates
            final alreadyExists = (event['event_favorites'] as List).any(
              (f) =>
                  f is Map &&
                  (f['user_id']?.toString() == currentUserId ||
                      f['user']?['id']?.toString() == currentUserId),
            );
            if (!alreadyExists) {
              (event['event_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            }
          } else {
            // Remove from favorites
            if (event['event_favorites'] is List) {
              (event['event_favorites'] as List).removeWhere(
                (f) =>
                    f is Map &&
                    (f['user_id']?.toString() == currentUserId ||
                        f['user']?['id']?.toString() == currentUserId),
              );
            }
          }

          try {
            if (!favoris) {
              // Remove from favorites (API call)
              await ApiClient().authenticatedDelete(
                '/events/$eventId/favorite',
              );
            } else {
              // Add to favorites (API call)
              await ApiClient().authenticatedPost('/events/$eventId/favorite');
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    favoris ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');

            // Revert on error
            cardSetState(() {
              favoris = !favoris;
            });

            // Revert underlying data
            event['is_favorited'] = favoris;
            if (!favoris) {
              // Was removing, so add back
              if (event['event_favorites'] is! List) {
                event['event_favorites'] = [];
              }
              (event['event_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            } else {
              // Was adding, so remove
              if (event['event_favorites'] is List) {
                (event['event_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == currentUserId ||
                          f['user']?['id']?.toString() == currentUserId),
                );
              }
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return EvenementCard(
          profileImage: profileImage,
          username: ownerName,
          userType: user?['account_type']?.toString() ?? 'particulier',
          eventTitle: eventTitle,
          eventImage: eventImage,
          badge: event['status']?.toString(),
          categories: categories.isNotEmpty ? categories : ['Général'],
          eventDate: _formatEventDate(event),
          location: coverageArea,
          timeAgo: _buildTimeAgo(event['created_at']?.toString()),
          price: price,
          likesCount: _asInt(event['likes_count']),
          commentsCount: _asInt(event['comments_count']),
          onTapCTA: () => _navigateToEventDetail(event),
          tags: tags.isNotEmpty ? tags : null,
          onAvatarTap: () {},
          reactionBar: eventId.isNotEmpty
              ? _buildReactionBar('events', eventId)
              : null,
          isFavorite: favoris,
          onFavoriteToggle: _toggleFavorite,
        );
      },
    );
  }

  String _getNatureLabel(String nature) {
    const natureLabels = {
      'emploi': 'Recherche d\'emploi',
      'service': 'Recherche de service',
      'logement': 'Recherche de logement',
      'produit': 'Recherche de produit',
      'formation': 'Recherche de formation',
      'collaboration': 'Collaboration',
      'autre': 'Autre demande',
    };
    return natureLabels[nature.toLowerCase()] ?? nature;
  }

  Color _categoryColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('urgent')) return Colors.redAccent;
    if (lower.contains('emploi')) return const Color(0xFF3AAE5E);
    if (lower.contains('stage')) return const Color(0xFF2196F3);
    if (lower.contains('formation')) return const Color(0xFF9C27B0);
    if (lower.contains('immobilier')) return const Color(0xFFFF5722);
    if (lower.contains('service')) return const Color(0xFFFF9800);
    return const Color(0xFF3AAE5E);
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> d) async {
    final demandeId = d['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette demande')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/$demandeId',
      );

      print("Response: ${response['data']['user']}");

      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final nature = data['nature']?.toString();
      final type = data['type']?.toString();
      final username = response['data']['user']['pro_profile'] != null
          ? response['data']['user']['pro_profile']['first_name']?.toString()
          : response['data']['user']['particulier_profile']['pseudo']
                ?.toString();
      final avatar = response['data']['user']['pro_profile'] != null
          ? response['data']['user']['pro_profile']['avatar_url']?.toString()
          : response['data']['user']['particulier_profile']['avatar_url']
                ?.toString();
      final urgent = data['urgent'] == true;
      final budgetMax = data['budget_max']?.toString();
      final location = data['location']?.toString();
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final nationwide = data['nationwide'] == true;
      final searchRadiusKm = data['search_radius_km'] is int
          ? data['search_radius_km'] as int
          : int.tryParse(data['search_radius_km']?.toString() ?? '');
      final showGoogleLocation = data['show_google_location'] == true;
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => m['url']?.toString() ?? '')
          // .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      final categoryLabel = (type != null && type.isNotEmpty)
          ? type
          : (nature != null && nature.isNotEmpty ? nature : 'Demande');

      final tags = <PostTag>[
        PostTag(
          title: categoryLabel,
          icon: Icons.label_outline,
          color: Colors.grey,
        ),
        if (urgent)
          PostTag(
            title: 'Urgent',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        if (nationwide)
          PostTag(
            title: 'Toute la France',
            icon: Icons.public,
            color: Colors.blue,
          ),
      ];

      final subTagsCat = nature != null && nature.isNotEmpty
          ? nature
          : 'Demande';

      final subTag = PostTag(
        title: subTagsCat,
        icon: Icons.label_outline,
        color: Colors.orange,
      );

      final currentUserId = _currentUserId;
      final authorId = (data['user'] is Map)
          ? (data['user'] as Map)['id']?.toString()
          : data['user_id']?.toString();

      final isOwner =
          authorId != null && authorId.isNotEmpty && currentUserId == authorId;

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: avatar ?? 'assets/images/profil/Rectangle 195.png',
            username: username ?? 'Ma demande',
            demandeTitle: title,
            description: description,
            tags: tags,
            subtags: subTag,
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
            nature: nature,
            type: type,
            urgent: urgent,
            budgetMax: budgetMax,
            location: location,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            nationwide: nationwide,
            searchRadiusKm: searchRadiusKm,
            showGoogleLocation: showGoogleLocation,
            acceptMessages: acceptMessages,
            isOwner: isOwner,
            demandeId: demandeId,
            demandeData: data,
            returnToListingOnEdit: true,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadAnnonces();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final user = demande['user'] as Map<String, dynamic>?;

    // Extraire le profil particulier
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;

    // Avatar : particulier_profile.avatar_url ou pro_profile.logo_url
    final avatarUrl =
        particulierProfile?['avatar_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        proProfile?['logo_url']?.toString();
    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;

    // Username : particulier_profile.pseudo ou pro_profile.company_name
    final username =
        particulierProfile?['pseudo']?.toString() ??
        proProfile?['company_name']?.toString() ??
        user?['email']?.toString() ??
        'Utilisateur';

    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');

    // Nature de la demande (Internship, SearchJob, Training, RealEstate, etc.)
    final nature = demande['nature']?.toString() ?? 'Demande';
    final categoryLabel = _getNatureLabel(nature);

    // Location
    final nationwideRaw = demande['nationwide'];
    final nationwide =
        nationwideRaw == true ||
        nationwideRaw == 1 ||
        nationwideRaw?.toString() == '1' ||
        nationwideRaw?.toString().toLowerCase() == 'true';
    final locationRaw =
        demande['location']?.toString() ?? demande['city']?.toString() ?? '';
    final location = nationwide
        ? 'Toute la France'
        : (locationRaw.isNotEmpty ? locationRaw : 'Non spécifié');

    // Media
    final postImage = _extractMediaUrl(demande);

    final demandeId = demande['id']?.toString() ?? '';

    // Check if already favorited by current user
    final bool initialIsFavorited = demande['is_favorited'] == true;
    final currentUserId = UserSession().id;

    // Use ValueNotifier for state that persists across rebuilds
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoadingFavorite = false;

        Future<void> toggleFavorite() async {
          if (isLoadingFavorite || demandeId.isEmpty) return;

          // Toggle immediately for responsive UI
          final newValue = !isFavoritedNotifier.value;
          isFavoritedNotifier.value = newValue;
          setState(() => isLoadingFavorite = true);

          try {
            if (!newValue) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/demandes/$demandeId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              demande['is_favorited'] = false;
              if (demande['demande_favorites'] is List) {
                (demande['demande_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == currentUserId ||
                          f['user']?['id']?.toString() == currentUserId),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/demandes/$demandeId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              demande['is_favorited'] = true;
              if (demande['demande_favorites'] is! List) {
                demande['demande_favorites'] = [];
              }
              (demande['demande_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            }

            setState(() {
              isLoadingFavorite = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavoritedNotifier.value
                        ? 'Ajouté aux favoris'
                        : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            demande['is_favorited'] = isFavoritedNotifier.value;
            setState(() => isLoadingFavorite = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return DemandeCard(
          profileImage: profileImage,
          username: username,
          categoryLabel: categoryLabel,
          accountType: proProfile != null && proProfile!.isNotEmpty
              ? 'pro'
              : 'particulier',
          categoryColor: _categoryColor(categoryLabel),
          title: title,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          location: location,
          postImage: postImage,
          likesCount: _asInt(demande['likes_count']),
          commentsCount: _asInt(demande['comments_count']),
          timeAgo: _buildTimeAgo(demande['created_at']?.toString()),
          onTapCTA: () => _navigateToDemandeDetail(demande),
          onAvatarTap: () {},
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: isLoadingFavorite,
          onFavoriteToggle: toggleFavorite,
          reactionBar: demandeId.isNotEmpty
              ? _buildReactionBar(
                  'demandes',
                  demandeId,
                  acceptedMessages: demande['accept_messages'] == true,
                  authorData: demande['user'],
                )
              : null,
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final response = widget.userId == null
          ? await _profileService.getProfile()
          : await _profileService.getUserProfile(widget.userId!);

      if (!mounted) return;

      setState(() {
        _profileResponse = response;
        _isFollowing = response['is_following'] ?? false;
        _isLoadingProfile = false;
      });

      _loadAnnonces();
      _loadPosts();
      _loadReviews();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    final targetUserId =
        widget.userId ?? _profileResponse?['user']?['id']?.toString();
    if (targetUserId == null) {
      setState(() => _isLoadingReviews = false);
      return;
    }

    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final response = await ApiClient().authenticatedGet(
        '/reviews/user/$targetUserId',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(response['reviews'] ?? []);
          _averageRating = (response['average_rating'] ?? 0.0).toDouble();
          _totalReviews = response['total_reviews'] ?? 0;
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _reviewsError = response['message'] ?? 'Erreur de chargement';
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewsError = 'Erreur de connexion: $e';
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewRating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez noter et commenter avant d\'envoyer votre avis.',
          ),
        ),
      );
      return;
    }

    // Check if viewing own profile
    if (_isViewingOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous ne pouvez pas donner un avis à votre propre profil.',
          ),
        ),
      );
      return;
    }

    final targetUserId = widget.userId;
    if (targetUserId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedPost(
        '/reviews/user/$targetUserId',
        body: {
          'rating': _reviewRating,
          'comment': _reviewController.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        // Clear form
        setState(() {
          _reviewRating = 0;
          _reviewController.clear();
        });

        // Reload reviews
        await _loadReviews();

        // Update UserSession with new My's balance from response
        // The backend should return the updated mys count, or we can refresh from profile
        if (response['new_mys_balance'] != null) {
          UserSession().updateMys(response['new_mys_balance']);
        }

        // Show reward modal
        if (mounted && response['mys_earned'] != null) {
          await MysRewardModal.show(
            context,
            amount: response['mys_earned'],
            actionType: 'review',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Erreur lors de l\'envoi de l\'avis',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isViewingOwnProfile || _isLoadingFollow) return;

    final targetId = widget.userId;
    if (targetId == null) return;

    setState(() => _isLoadingFollow = true);

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoadingFollow = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'Vous suivez maintenant cet utilisateur'
                  : 'Vous ne suivez plus cet utilisateur',
            ),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startConversation() async {
    if (_isViewingOwnProfile) return;

    final targetIdStr = widget.userId;
    if (targetIdStr == null) return;

    final targetId = int.tryParse(targetIdStr);
    if (targetId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _conversationService.getOrCreateConversation(
        targetId,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final profile = _profileResponse?['profile'];
      final displayName = (profile is Map)
          ? (profile['company_name']?.toString() ?? 'Entreprise')
          : 'Entreprise';

      String? avatarUrl;
      if (profile is Map) {
        avatarUrl =
            profile['avatar_url']?.toString() ??
            profile['logo_url']?.toString();
      }
      final resolvedAvatar = avatarUrl != null && avatarUrl.isNotEmpty
          ? (avatarUrl.startsWith('http')
                ? avatarUrl
                : ApiConfig.resolveMediaUrl(avatarUrl))
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar:
                resolvedAvatar ??
                'assets/images/dashboard_particulier/Ellipse 10.png',
            status: 'En ligne',
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer la conversation: $e')),
        );
      }
    }
  }

  void _showReportConfirmation() {
    final profile = _profileResponse?['profile'];
    final displayName = (profile is Map)
        ? (profile['company_name']?.toString() ?? 'ce compte')
        : 'ce compte';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler le compte'),
        content: Text('Voulez-vous vraiment signaler $displayName ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement envoyé'),
                  backgroundColor: Color(0xFF3AAE5E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Signaler',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPosts({bool showLoader = true}) async {
    if (!mounted) return;
    if (showLoader) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final targetUserId = widget.userId;
      final response = await ApiClient().authenticatedGet(
        targetUserId != null ? '/posts?user_id=$targetUserId' : '/posts',
      );
      final data = response['data'];
      List<Map<String, dynamic>> posts = [];
      if (data is List) {
        posts = List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        posts = List<Map<String, dynamic>>.from(data['data'] as List);
      }

      if (!mounted) return;
      setState(() {
        _myPosts = posts;
        _isLoadingPosts = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.message;
        _isLoadingPosts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postsError = 'Impossible de charger les posts.';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _refreshPosts() => _loadPosts(showLoader: false);

  bool _isRepost(Map<String, dynamic> post) {
    final originalPostId = post['original_post_id'];
    return originalPostId != null && originalPostId.toString().isNotEmpty;
  }

  bool _isQuoteRepost(Map<String, dynamic> post) {
    final isRepost = _isRepost(post);
    final repostContent = post['repost_content']?.toString();
    return isRepost && repostContent != null && repostContent.trim().isNotEmpty;
  }

  String _buildTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final created = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return "à l'instant";
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
      final weeks = (diff.inDays / 7).floor();
      if (weeks < 4) return 'il y a $weeks sem';
      final months = (diff.inDays / 30).floor();
      return 'il y a $months mois';
    } catch (_) {
      return '';
    }
  }

  String? _joinNames(dynamic first, dynamic last) {
    final firstName = first?.toString().trim();
    final lastName = last?.toString().trim();
    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) {
      return null;
    }
    if (firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName?.isNotEmpty == true ? firstName : lastName;
  }

  _PostAuthorInfo _extractPostAuthorInfo(Map<String, dynamic> raw) {
    final authorMap = (raw['author'] ?? raw['user']) as Map<String, dynamic>?;
    final authorId =
        authorMap?['id']?.toString() ??
        raw['author_id']?.toString() ??
        raw['user_id']?.toString();

    final feedAuthor = raw['author'] as Map<String, dynamic>?;

    final nameCandidates = [
      feedAuthor?['display_name'],
      authorMap?['display_name'],
      raw['display_name'],
      raw['author_display_name'],
      authorMap?['pseudo'],
      authorMap?['nomsociete'],
      _joinNames(authorMap?['first_name'], authorMap?['last_name']),
      authorMap?['name'],
      raw['author_name'],
      raw['authorName'],
    ];

    String resolvedName = 'Utilisateur';
    for (final candidate in nameCandidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        resolvedName = value;
        break;
      }
    }

    if (_currentUserId != null &&
        authorId != null &&
        authorId == _currentUserId) {
      resolvedName = 'Vous';
    }

    final rawType =
        (feedAuthor?['account_type'] ??
                authorMap?['account_type'] ??
                authorMap?['profiletype'] ??
                raw['author_account_type'])
            ?.toString()
            .toLowerCase() ??
        '';
    final accountType =
        rawType.contains('pro') || rawType.contains('professionnel')
        ? 'Professionnel'
        : 'Particulier';

    final particulierProfile =
        authorMap?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = authorMap?['pro_profile'] as Map<String, dynamic>?;

    final avatarCandidates = [
      feedAuthor?['avatar_url'],
      particulierProfile?['avatar_url'],
      proProfile?['avatar_url'],
      proProfile?['logo_url'],
      authorMap?['avatar_url'],
      authorMap?['avatar'],
      authorMap?['photo'],
      authorMap?['photoprofilurl'],
      raw['author_avatar'],
      raw['authorAvatar'],
    ];
    String avatar = _defaultAvatar;
    for (final candidate in avatarCandidates) {
      if (candidate == null) continue;
      final resolved = _buildStorageUrl(candidate.toString());
      if (resolved != null && resolved.isNotEmpty) {
        avatar = resolved;
        break;
      }
    }

    return _PostAuthorInfo(
      id: authorId,
      displayName: resolvedName,
      accountType: accountType,
      avatar: avatar,
    );
  }

  List<String> _extractAllMediaUrls(Map<String, dynamic> resource) {
    final urls = <String>[];
    final media = resource['media'] ?? resource['media_files'];
    if (media is List) {
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) {
            // If URL is already complete (http/https), use it as-is
            if (url.startsWith('http')) {
              urls.add(url);
            } else {
              // Otherwise prepend the server base URL
              urls.add("${ApiConfig.baseUrl.replaceFirst('/api', '')}$url");
            }
          }
        }
      }
    }
    if (urls.isEmpty) {
      final cover = resource['cover_url']?.toString();
      if (cover != null && cover.isNotEmpty) {
        if (cover.startsWith('http')) {
          urls.add(cover);
        } else {
          urls.add("${ApiConfig.baseUrl.replaceFirst('/api', '')}$cover");
        }
      }
    }
    return urls;
  }

  void _seedReactionFromFeed(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource,
  ) {
    final key = _reactionKey(apiSlug, entityId);
    if (!_reactions.containsKey(key)) {
      final apiReaction = resource['user_reaction']?.toString();
      final userReaction = ReactionCacheService.isCached(apiSlug, entityId)
          ? ReactionCacheService.load(apiSlug, entityId)
          : apiReaction;
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      final apiCommentsCount = _asInt(resource['comments_count']);
      final cachedCommentsCount = ReactionCacheService.loadCommentsCount(
        apiSlug,
        entityId,
      );
      final apiRepostsCount = _asInt(resource['reposts_count']);
      _reactions[key] = _ReactionData(
        likesCount: (cachedCount != null && cachedCount > apiCount)
            ? cachedCount
            : apiCount,
        commentsCount:
            (cachedCommentsCount != null &&
                cachedCommentsCount > apiCommentsCount)
            ? cachedCommentsCount
            : apiCommentsCount,
        repostsCount: apiRepostsCount,
        userReaction: userReaction,
      );
    }
  }

  Widget _buildPostCard(Map<String, dynamic> raw) {
    final postId = raw['id']?.toString() ?? '';

    // Détecter si c'est un repost
    final isRepost = raw['original_post_id'] != null;

    // Détecter si c'est un quote repost (repost avec texte ajouté)
    final repostContent = raw['repost_content']?.toString();
    final isQuoteRepost =
        isRepost && repostContent != null && repostContent.trim().isNotEmpty;

    // Si c'est un repost, utiliser les données du post original
    final originalPost = isRepost
        ? (raw['original_post'] as Map<String, dynamic>? ?? {})
        : raw;

    // L'auteur du repost (celui qui a republié)
    final reposter = _extractPostAuthorInfo(raw);

    // L'auteur du post original
    final author = isRepost ? _extractPostAuthorInfo(originalPost) : reposter;

    final content = originalPost['content']?.toString() ?? '';
    final createdAt = originalPost['created_at']?.toString();
    final timeAgo = _buildTimeAgo(createdAt);
    final allMediaUrls = _extractAllMediaUrls(originalPost);

    // For simple reposts (no text), use original post's reactions
    // For quote reposts (with text), use the repost's own reactions
    final originalPostId = raw['original_post_id']?.toString() ?? '';
    String reactionEntityId;
    if (isRepost && !isQuoteRepost && originalPostId.isNotEmpty) {
      // Simple repost: reactions go to original post
      reactionEntityId = originalPostId;
      _seedReactionFromFeed('posts', originalPostId, originalPost);
    } else {
      // Original post or quote repost: reactions are on this post itself
      reactionEntityId = postId;
      if (postId.isNotEmpty) {
        _seedReactionFromFeed('posts', postId, isQuoteRepost ? raw : raw);
      }
    }

    return _PostCardWidget(
      postId: postId,
      isRepost: isRepost,
      isQuoteRepost: isQuoteRepost,
      repostContent: repostContent,
      reposter: reposter,
      author: author,
      content: content,
      timeAgo: timeAgo,
      mediaUrls: allMediaUrls,
      onToggleReaction: (type) =>
          _toggleReaction('posts', reactionEntityId, type),
      buildReactionBar: () =>
          _buildReactionBar('posts', reactionEntityId, postData: raw),
      buildTypeTag: _buildTypeTag,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> _loadAnnonces() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnnonces = true;
      _annoncesError = null;
    });

    try {
      // Determine which user's announcements to fetch
      // widget.userId is set when viewing another user's profile
      final targetUserId = widget.userId;

      final results = await Future.wait([
        ApiClient().authenticatedGet(
          targetUserId != null
              ? '/bonplans?user_id=$targetUserId'
              : '/bonplans',
        ),
        ApiClient().authenticatedGet(
          targetUserId != null
              ? '/job-offers?user_id=$targetUserId'
              : '/job-offers',
        ),
        ApiClient().authenticatedGet(
          targetUserId != null
              ? '/trainings?user_id=$targetUserId'
              : '/trainings',
        ),
        ApiClient().authenticatedGet(
          targetUserId != null ? '/events?user_id=$targetUserId' : '/events',
        ),
        ApiClient().authenticatedGet(
          targetUserId != null
              ? '/demandes?user_id=$targetUserId'
              : '/demandes',
        ),
      ]);

      final bonPlans = _extractList(results[0]);
      final jobOffers = _extractList(results[1]);
      final trainings = _extractList(results[2]);
      final events = _extractList(results[3]);
      final demandes = _extractList(results[4]);

      if (!mounted) return;
      // Seed reactions BEFORE setState to prevent _getReaction pre-populating with empty data
      for (final bp in bonPlans) {
        final bpId = bp['id']?.toString() ?? '';
        if (bpId.isNotEmpty) _seedReactionFromResource('bon-plans', bpId, bp);
      }
      for (final job in jobOffers) {
        final jobId = job['id']?.toString() ?? '';
        if (jobId.isNotEmpty)
          _seedReactionFromResource('job-offers', jobId, job);
      }
      for (final tr in trainings) {
        final trId = tr['id']?.toString() ?? '';
        if (trId.isNotEmpty) _seedReactionFromResource('trainings', trId, tr);
      }
      for (final evt in events) {
        final evtId = evt['id']?.toString() ?? '';
        if (evtId.isNotEmpty) _seedReactionFromResource('events', evtId, evt);
      }
      for (final d in demandes) {
        final dId = d['id']?.toString() ?? '';
        if (dId.isNotEmpty) _seedReactionFromResource('demandes', dId, d);
      }
      setState(() {
        _bonPlans = bonPlans;
        _jobOffers = jobOffers;
        _trainings = trainings;
        _events = events;
        _demandes = demandes;
        _isLoadingAnnonces = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _annoncesError = e.message;
        _isLoadingAnnonces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _annoncesError = 'Erreur de chargement';
        _isLoadingAnnonces = false;
      });
    }
  }

  String? _resolveAvatarUrl() {
    final profile = _profileResponse?['profile'];
    final raw = profile is Map ? profile['avatar_url']?.toString() : null;
    return raw;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profileResponse?['profile'];
    final companyName = profile is Map
        ? profile['company_name']?.toString()
        : null;
    final firstName = profile is Map ? profile['first_name']?.toString() : null;
    final lastName = profile is Map ? profile['last_name']?.toString() : null;
    final nameParts = <String>[];
    if (firstName != null && firstName.trim().isNotEmpty) {
      nameParts.add(firstName.trim());
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      nameParts.add(lastName.trim());
    }
    final displayName = companyName ?? nameParts.join(' ');
    final siret = profile is Map ? profile['siret']?.toString() : null;
    final secteur = profile is Map
        ? profile['secteur_activite']?.toString()
        : null;
    final avatarUrl = _resolveAvatarUrl();

    // Get social links
    final socialLinks = profile is Map
        ? (profile['social_links'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    final facebookUrl = socialLinks['facebook']?.toString();
    final instagramUrl = socialLinks['instagram']?.toString();
    final youtubeUrl = socialLinks['youtube']?.toString();
    final linkedinUrl = socialLinks['linkedin']?.toString();
    final snapchatUrl = socialLinks['snapchat']?.toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: _isViewingOwnProfile
            ? null
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportConfirmation();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Signaler le compte',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 10,
                          top: 40,
                        ),
                        padding: const EdgeInsets.only(
                          top: 68,
                          left: 30,
                          right: 20,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2E9B5B),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              displayName.isNotEmpty ? displayName : '—',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              siret != null && siret.trim().isNotEmpty
                                  ? 'SIRET: $siret'
                                  : 'SIRET: —',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/profil_pro/profil-etiq.png',
                                  width: 17,
                                  height: 17,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  (secteur != null && secteur.trim().isNotEmpty)
                                      ? secteur
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_averageRating.toStringAsFixed(1)} ($_totalReviews avis)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E9B5B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF8A40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF2E9B5B),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: avatarUrl != null
                                  ? (avatarUrl.startsWith('http')
                                        ? NetworkImage(avatarUrl)
                                              as ImageProvider
                                        : NetworkImage(
                                                ApiConfig.resolveMediaUrl(
                                                      avatarUrl,
                                                    ) ??
                                                    '',
                                              )
                                              as ImageProvider)
                                  : AssetImage(
                                          'assets/images/dashboard_particulier/Ellipse 10.png',
                                        )
                                        as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 75,
                        left: 30,
                        child: Column(
                          children: [
                            // Facebook
                            if (facebookUrl != null && facebookUrl.isNotEmpty)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1877F2,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(facebookUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch Facebook: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.facebook,
                                    color: Color(0xFF1877F2),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            if (facebookUrl != null && facebookUrl.isNotEmpty)
                              const SizedBox(height: 12),
                            // Instagram
                            if (instagramUrl != null && instagramUrl.isNotEmpty)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE1306C,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(instagramUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch Instagram: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.instagram,
                                    color: Color(0xFFE1306C),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            if (instagramUrl != null && instagramUrl.isNotEmpty)
                              const SizedBox(height: 12),
                            // YouTube
                            if (youtubeUrl != null && youtubeUrl.isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF0000,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(youtubeUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch YouTube: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.youtube,
                                    color: Color(0xFFFF0000),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Message and Suivre buttons - only show when viewing other users' profiles
                  if (!_isViewingOwnProfile)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.only(bottom: 10, top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startConversation,
                              icon: const Icon(
                                Icons.message_outlined,
                                size: 18,
                              ),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3AAE5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingFollow
                                  ? null
                                  : _toggleFollow,
                              icon: _isLoadingFollow
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF3AAE5E),
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isFollowing
                                          ? Icons.check
                                          : Icons.person_add_outlined,
                                      size: 18,
                                    ),
                              label: Text(_isFollowing ? 'Suivi' : 'Suivre'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3AAE5E),
                                side: const BorderSide(
                                  color: Color(0xFF3AAE5E),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(
                      left: 14,
                      right: 14,
                      bottom: 4,
                      top: 8,
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF8A40).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF666666),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      labelPadding: EdgeInsets.zero,
                      indicator: BoxDecoration(
                        color: const Color(0xFFEF8A40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      tabs: [
                        const Tab(
                          height: 32,
                          child: Text(
                            'Présentation',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Annonce(${_totalCount})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Posts(${_myPosts.where((p) => !_isRepost(p) || _isQuoteRepost(p)).length})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Avis($_totalReviews)',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPresentationTab(),
                        _buildAnnonceTab(),
                        _buildPostsTab(),
                        _buildAvisTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresentationTab() {
    final profile = _profileResponse?['profile'];
    final presentation = profile is Map
        ? profile['presentation']?.toString()
        : null;
    final bannerUrl = profile is Map ? profile['banner_url']?.toString() : null;
    final gallery = profile is Map
        ? (profile['gallery'] as List<dynamic>? ?? [])
        : <dynamic>[];

    // Get social links
    final socialLinks = profile is Map
        ? (profile['social_links'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    final facebookUrl = socialLinks['facebook']?.toString();
    final instagramUrl = socialLinks['instagram']?.toString();
    final youtubeUrl = socialLinks['youtube']?.toString();
    final linkedinUrl = socialLinks['linkedin']?.toString();
    final tiktokUrl = socialLinks['tiktok']?.toString();
    final snapchatUrl = socialLinks['snapchat']?.toString();
    final xUrl = socialLinks['x']?.toString();

    // Filter images and videos
    final images = gallery.where((item) {
      final url = item.toString().toLowerCase();
      return !url.endsWith('.mp4') &&
          !url.endsWith('.mov') &&
          !url.endsWith('.avi') &&
          !url.endsWith('.webm') &&
          !url.endsWith('.mkv');
    }).toList();

    final videos = gallery.where((item) {
      final url = item.toString().toLowerCase();
      return url.endsWith('.mp4') ||
          url.endsWith('.mov') ||
          url.endsWith('.avi') ||
          url.endsWith('.webm') ||
          url.endsWith('.mkv');
    }).toList();

    String buildImageUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      if (url.startsWith('http') || url.startsWith('https')) return url;
      return '$serverBase/storage/$url';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merged Banner + Presentation + Social Links Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(-2, 3),
                ),
              ],
            ),
            child:
                _isViewingOwnProfile &&
                    bannerUrl == null &&
                    (presentation?.trim().isEmpty ?? true)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
                    child: Column(
                      children: [
                        Text(
                          "Ajoutez une banniere et une presentation pour attirer plus de clients",
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProProfileEntrepriseScreen(),
                              ),
                            );
                          },
                          child: Text("Modifier"),
                        ),
                      ],
                    ),
                  )
                : (!_isViewingOwnProfile &&
                          (bannerUrl == null ||
                              (presentation?.trim().isEmpty ?? true))
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
                          child: Column(
                            children: [
                              Text(
                                "Aucune presentation",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: bannerUrl != null && bannerUrl.isNotEmpty
                                    ? Image.network(
                                        buildImageUrl(bannerUrl),
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const SizedBox.shrink();
                                            },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),

                            // Presentation Section
                            if (presentation?.trim().isNotEmpty == true) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  20,
                                  18,
                                  0,
                                ),
                                child: Text(
                                  'Présentation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  20,
                                ),
                                child: Text(
                                  presentation!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],

                            // Social Links Section
                            if (facebookUrl != null ||
                                instagramUrl != null ||
                                youtubeUrl != null ||
                                linkedinUrl != null ||
                                snapchatUrl != null ||
                                xUrl != null) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  0,
                                ),
                                child: Divider(color: Colors.grey[200]),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  8,
                                ),
                                child: Text(
                                  'Réseaux sociaux',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  8,
                                  18,
                                  20,
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    if (facebookUrl != null &&
                                        facebookUrl.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.facebook,
                                        const Color(0xFF1877F2),
                                        facebookUrl,
                                      ),
                                    if (instagramUrl != null &&
                                        instagramUrl.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.camera_alt,
                                        const Color(0xFFE1306C),
                                        instagramUrl,
                                      ),
                                    if (youtubeUrl != null &&
                                        youtubeUrl.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.play_circle_filled,
                                        const Color(0xFFFF0000),
                                        youtubeUrl,
                                      ),
                                    if (linkedinUrl != null &&
                                        linkedinUrl.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.business,
                                        const Color(0xFF0A66C2),
                                        linkedinUrl,
                                      ),
                                    if (snapchatUrl != null &&
                                        snapchatUrl.isNotEmpty)
                                      _buildSocialIcon(
                                        Icons.screenshot,
                                        const Color(0xFFFFFC00),
                                        snapchatUrl,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        )),
          ),
          const SizedBox(height: 24),
          // Media Gallery Card
          if (gallery.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(-2, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                    child: Text(
                      'Médias photos et vidéos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMediaTab = 0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                color: _selectedMediaTab == 0
                                    ? const Color(0xFFEF8A40)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                color: _selectedMediaTab == 0
                                    ? const Color(0xFFEF8A40)
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMediaTab = 1),
                          child: Column(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                color: _selectedMediaTab == 1
                                    ? const Color(0xFFEF8A40)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                color: _selectedMediaTab == 1
                                    ? const Color(0xFFEF8A40)
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    child: _selectedMediaTab == 0
                        ? _buildPhotosGrid(images, buildImageUrl)
                        : _buildVideosGrid(videos, buildImageUrl),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Could not launch $url: $e');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPhotosGrid(
    List<dynamic> images,
    String Function(String?) buildUrl,
  ) {
    if (images.isEmpty) {
      return Center(
        child: Text('Aucune photo', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            buildUrl(images[index].toString()),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 30),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVideosGrid(
    List<dynamic> videos,
    String Function(String?) buildUrl,
  ) {
    if (videos.isEmpty) {
      return Center(
        child: Text('Aucune vidéo', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnonceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Tout', _selectedAnnonceFilter == 'Tout'),
                    _buildFilterChip(
                      'Bons plans',
                      _selectedAnnonceFilter == 'Bons plans',
                    ),
                    _buildFilterChip(
                      'Offres d\'emploi',
                      _selectedAnnonceFilter == "Offres d'emploi",
                    ),
                    _buildFilterChip(
                      'Formations',
                      _selectedAnnonceFilter == 'Formations',
                    ),
                    _buildFilterChip(
                      'Événements',
                      _selectedAnnonceFilter == 'Événements',
                    ),
                    _buildFilterChip(
                      'Demandes',
                      _selectedAnnonceFilter == 'Demandes',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingAnnonces)
            const Center(child: CircularProgressIndicator())
          else if (_annoncesError != null)
            Text(_annoncesError!, style: const TextStyle(color: Colors.red))
          else if (_selectedAnnonceFilter == 'Tout')
            Column(
              children: [
                if (_bonPlans.isNotEmpty) _buildBonPlansList(),
                if (_jobOffers.isNotEmpty) _buildJobOffersList(),
                if (_trainings.isNotEmpty) _buildTrainingsList(),
                if (_events.isNotEmpty) _buildEventsList(),
                if (_demandes.isNotEmpty) _buildDemandesList(),
                if (_bonPlans.isEmpty &&
                    _jobOffers.isEmpty &&
                    _trainings.isEmpty &&
                    _events.isEmpty &&
                    _demandes.isEmpty)
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: const Text(
                            'Aucune annonce',
                            style: TextStyle(color: Color(0xFF666666)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            )
          else if (_selectedAnnonceFilter == 'Bons plans')
            _buildBonPlansList()
          else if (_selectedAnnonceFilter == "Offres d'emploi")
            _buildJobOffersList()
          else if (_selectedAnnonceFilter == 'Formations')
            _buildTrainingsList()
          else if (_selectedAnnonceFilter == 'Événements')
            _buildEventsList()
          else if (_selectedAnnonceFilter == 'Demandes')
            _buildDemandesList(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final postsOnly = _myPosts
        .where((p) => !_isRepost(p) || _isQuoteRepost(p))
        .toList();
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_isLoadingPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_postsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(_postsError!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadPosts(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (postsOnly.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(
                child: Text(
                  _isViewingOwnProfile
                      ? "Vous n'avez pas encore publié de post."
                      : "Aucun post disponible pour l'instant.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            for (final post in postsOnly) ...[
              _buildPostCard(post),
              const SizedBox(height: 4),
            ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAvisTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviews list
            if (_isLoadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviewsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      _reviewsError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadReviews,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            else if (_reviews.isNotEmpty)
              ..._reviews
                  .map(
                    (review) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildReviewCard(
                        avatarPath:
                            review['author_avatar'] ??
                            'assets/images/dashboard_particulier/Ellipse 10.png',
                        name: review['author_name'] ?? 'Utilisateur',
                        timeAgo: review['time_ago'] ?? '',
                        reviewText: review['comment'] ?? '',
                        rating: review['rating'] ?? 0,
                      ),
                    ),
                  )
                  .toList()
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text(
                    'Aucun avis pour le moment.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            // Review form - only show when viewing other users' profiles
            if (!_isViewingOwnProfile)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donner votre avis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _reviewRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < _reviewRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Votre commentaire...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Envoyer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manjari',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required String avatarPath,
    required String name,
    required String timeAgo,
    required String reviewText,
    required int rating,
  }) {
    // Resolve avatar URL
    ImageProvider avatarImage;
    if (avatarPath.startsWith('http')) {
      avatarImage = NetworkImage(avatarPath);
    } else if (avatarPath.startsWith('assets/')) {
      avatarImage = AssetImage(avatarPath);
    } else {
      final resolvedUrl = ApiConfig.resolveMediaUrl(avatarPath);
      avatarImage = resolvedUrl != null
          ? NetworkImage(resolvedUrl)
          : AssetImage('assets/images/dashboard_particulier/Ellipse 10.png');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: avatarImage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                        fontFamily: 'Manjari',
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (index) =>
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reviewText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4F4F4F),
              height: 1.4,
              fontFamily: 'Manjari',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAnnonceFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A8143) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A8143) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnonceCard(
    String userName,
    String userType,
    String description,
    String? imagePath,
    String price,
    String? oldPrice,
    String? discount,
    String? category,
    String? availability,
    String time,
    int? likes,
    int? comments,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: const AssetImage(
                  'assets/images/dashboard_particulier/Ellipse 10.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: userType == 'Pro'
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: userType == 'Pro' ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        userType,
                        style: TextStyle(
                          color: userType == 'Pro'
                              ? Colors.green.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Icon(Icons.close, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              children: [
                TextSpan(text: description),
                const TextSpan(
                  text: '...plus',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF8A40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (category != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          if (availability != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'En ligne disponible chez '),
                        TextSpan(
                          text: 'Amazon',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF8A40),
                ),
              ),
              if (oldPrice != null) ...[
                const SizedBox(width: 10),
                Text(
                  oldPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF8A40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Image.asset(
                  'assets/images/profil_pro/paper.png',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Voir le bon plan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (likes != null) ...[
                Icon(
                  Icons.thumb_up_outlined,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '$likes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
              ],
              if (comments != null) ...[
                Image.asset(
                  'assets/images/profil_pro/ann-card-comm.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$comments',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
              ],
              Image.asset(
                'assets/images/profil_pro/ann-card-share.png',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(String time, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Publier ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [
                TextSpan(
                  text: time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageUrl,
                  width: 90,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore ...voir plus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 4),
              Text('125', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-comm.png',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 4),
              Text('10', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-share.png',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 4),
              Text('2', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewConfirmationDialog extends StatelessWidget {
  const _ReviewConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF0E0),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFFF8600),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _AvisSuccessBadge(),
            const SizedBox(height: 24),
            const Text(
              'Cet avis sera définitif après publication et ne pourra être modifié ou supprimé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                      foregroundColor: const Color(0xFF6F6F6F),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manjari',
                      ),
                    ),
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

class _AvisSuccessBadge extends StatelessWidget {
  const _AvisSuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9EF), Color(0xFFFFE0B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(top: 12, right: 18, child: _buildBubble(14, 0.4)),
          Positioned(top: 20, left: 24, child: _buildBubble(10, 0.35)),
          Positioned(bottom: 20, right: 30, child: _buildBubble(12, 0.3)),
          Positioned(bottom: 10, left: 30, child: _buildBubble(9, 0.45)),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC477), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/profil/avis/streamline-ultimate-color_smiley-happy.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.4),
          width: 1,
        ),
      ),
    );
  }
}
