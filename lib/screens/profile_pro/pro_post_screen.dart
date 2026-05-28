import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myreklam/services/share_service.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/create_post_screen.dart';
import 'package:myreklam/screens/image_preview_screen.dart';
import 'package:myreklam/screens/post_detail_full_screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/report_reason_dialog.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<_PostCardWidget> {
  bool _isExpanded = false;
  static const int _collapsedMaxLength = 150;
  double _dragOffset = 0.0;
  static const double _maxDrag = 120.0;
  static const double _actionWidth = 60.0;

  Widget _buildAuthorRow(_PostAuthorInfo authorInfo) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {},
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
                onTap: () {},
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

    // Build the card content
    final cardContent = InkWell(
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

    // Wrap with draggable functionality if owner
    if (!widget.isOwner) {
      return cardContent;
    }

    return Stack(
      children: [
        // Background actions
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button (only if onEdit is provided)
                if (widget.onEdit != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0);
                      widget.onEdit?.call();
                    },
                    child: Container(
                      width: _actionWidth,
                      height: double.infinity,
                      // decoration: const BoxDecoration(color: Colors.grey),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.grey, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Modifier',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Delete button (only if onDelete is provided)
                if (widget.onDelete != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _dragOffset = 0);
                      widget.onDelete?.call();
                    },
                    child: Container(
                      width: _actionWidth,
                      height: double.infinity,
                      // decoration: const BoxDecoration(
                      //   color: Colors.red,
                      //   borderRadius: BorderRadius.only(
                      //     topRight: Radius.circular(12),
                      //     bottomRight: Radius.circular(12),
                      //   ),
                      // ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Suppr.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 10,
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
        ),
        // Draggable card foreground
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (!widget.isOwner) return;
            setState(() {
              _dragOffset += details.delta.dx;
              _dragOffset = _dragOffset.clamp(-_maxDrag, 0.0);
            });
          },
          onHorizontalDragEnd: (details) {
            if (!widget.isOwner) return;
            final hasEdit = widget.onEdit != null;
            final hasDelete = widget.onDelete != null;
            final actionCount = (hasEdit ? 1 : 0) + (hasDelete ? 1 : 0);
            setState(() {
              // Snap to open or closed based on available actions
              if (_dragOffset < -_actionWidth / 2) {
                _dragOffset = -(_actionWidth * actionCount); // Show actions
              } else {
                _dragOffset = 0.0; // Snap back
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: cardContent,
          ),
        ),
      ],
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

class ProPostScreen extends StatefulWidget {
  const ProPostScreen({super.key});

  @override
  State<ProPostScreen> createState() => _ProPostScreenState();
}

class _ProPostScreenState extends State<ProPostScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = true;
  String? _error;
  late final TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
    _getCurrentUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadPosts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final response = await ApiClient().authenticatedGet('/posts');
      final data = response['data'];
      List<Map<String, dynamic>> posts = [];
      if (data is List) {
        posts = List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        posts = List<Map<String, dynamic>>.from(data['data'] as List);
      }
      // Seed reactions from fresh API data (force=true)
      for (final post in posts) {
        final postId = post['id']?.toString() ?? '';
        final originalPostId = post['original_post_id']?.toString();
        if (postId.isNotEmpty) {
          // For original posts and quote reposts, seed from the post itself
          if (originalPostId == null || originalPostId.isEmpty) {
            _seedReactionFromFeed('posts', postId, post, force: true);
          }
          // For simple reposts, also seed the original post's reactions
          if (originalPostId != null && originalPostId.isNotEmpty) {
            final originalPost = post['original_post'] as Map<String, dynamic>?;
            if (originalPost != null) {
              _seedReactionFromFeed(
                'posts',
                originalPostId,
                originalPost,
                force: true,
              );
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Impossible de charger vos posts.';
          _isLoading = false;
        });
    }
  }

  Future<void> _refreshPosts() => _loadPosts(showLoader: false);

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase/storage/$url';
  }

  void _showPostMenu(Map<String, dynamic> post) {
    final postId = post['id']?.toString();
    if (postId == null) return;

    final isRepost = _isRepost(post);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!isRepost)
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFFF9800),
                ),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(post);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(postId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final postId = post['id']?.toString();
    if (postId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(postId: postId, initialData: post),
      ),
    );
    if (result == 'updated' && mounted) {
      _loadPosts();
    }
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce post ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePost(postId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await ApiClient().authenticatedDelete('/posts/$postId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post supprimé avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
        _refreshPosts();
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    // Posts tab: original posts + quote reposts (with text)
    final myPostsOnly = _myPosts
        .where((p) => !_isRepost(p) || _isQuoteRepost(p))
        .toList();
    // Republications tab: simple reposts only (without text)
    final repostsOnly = _myPosts
        .where((p) => _isRepost(p) && !_isQuoteRepost(p))
        .toList();

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
          'Mes posts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3AAE5E),
          tabs: [
            Tab(text: 'Posts(${myPostsOnly.length})'),
            Tab(text: 'Republications(${repostsOnly.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBody(postsOverride: myPostsOnly),
          _buildBody(postsOverride: repostsOnly),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFF3AAE5E),
      //   onPressed: _createNewPost,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildBody({required List<Map<String, dynamic>> postsOverride}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3AAE5E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AAE5E),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (postsOverride.isEmpty) {
      return const Center(
        child: Text(
          'Vous n\'avez aucun post/republication pour l\'instant',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF3AAE5E),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: postsOverride.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAE5E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3AAE5E).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF3AAE5E), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pour supprimer un post, glissez vers la gauche',
                      style: TextStyle(
                        color: Color(0xFF3AAE5E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final post = postsOverride[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPostCard(post),
          );
        },
      ),
    );
  }

  bool _isRepost(Map<String, dynamic> post) {
    final originalPostId = post['original_post_id'];
    return originalPostId != null && originalPostId.toString().isNotEmpty;
  }

  bool _isQuoteRepost(Map<String, dynamic> post) {
    final isRepost = _isRepost(post);
    final repostContent = post['repost_content']?.toString();
    return isRepost && repostContent != null && repostContent.trim().isNotEmpty;
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

  String get _defaultAvatar =>
      'assets/images/dashboard_particulier/Ellipse 10.png';

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

    final avatarCandidates = [
      authorMap?['avatar_url'],
      authorMap?['avatar_url'],
    ];

    String avatar = _defaultAvatar;
    for (final candidate in avatarCandidates) {
      if (candidate == null) continue;
      final resolved = candidate.toString();
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

  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) =>
      '${apiSlug}_$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromFeed(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource, {
    bool force = false,
  }) {
    final key = _reactionKey(apiSlug, entityId);
    if (!_reactions.containsKey(key) || force) {
      final apiReaction = resource['user_reaction']?.toString();
      // Prefer API value over cache - cache is for offline fallback only
      final userReaction =
          apiReaction ??
          (ReactionCacheService.isCached(apiSlug, entityId)
              ? ReactionCacheService.load(apiSlug, entityId)
              : null);
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      final apiRepostsCount = _asInt(resource['reposts_count']);
      _reactions[key] = _ReactionData(
        likesCount: (cachedCount != null && cachedCount > apiCount)
            ? cachedCount
            : apiCount,
        commentsCount: _asInt(resource['comments_count']),
        repostsCount: apiRepostsCount,
        userReaction: userReaction,
      );
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
          final apiRepostsCount = _asInt(data['reposts_count']);
          final apiReaction = data['user_reaction']?.toString();
          final currentData = _getReaction(apiSlug, entityId);
          final preservedLikesCount = apiLikesCount > currentData.likesCount
              ? apiLikesCount
              : currentData.likesCount;
          final preservedCommentsCount =
              apiCommentsCount > currentData.commentsCount
              ? apiCommentsCount
              : currentData.commentsCount;
          final preservedRepostsCount =
              apiRepostsCount > currentData.repostsCount
              ? apiRepostsCount
              : currentData.repostsCount;
          final cachedReaction = ReactionCacheService.load(apiSlug, entityId);
          final preservedReaction =
              currentData.userReaction ?? cachedReaction ?? apiReaction;
          _reactions[key] = _ReactionData(
            likesCount: preservedLikesCount,
            commentsCount: preservedCommentsCount,
            repostsCount: preservedRepostsCount,
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

                // Refresh posts to update comment count in feed
                await _refreshPosts();

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

                // Refresh posts to update comment count in feed
                await _refreshPosts();

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

              return reportableCommentGesture(
                context: context,
                comment: comment,
                currentUserId: _currentUserId,
                child: Padding(
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
              ));
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

  Future<void> _repostPost(
    String postId, {
    Map<String, dynamic>? originalPostData,
    String? initialText,
    bool isEditing = false,
  }) async {
    final textController = TextEditingController(text: initialText);
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
                        Expanded(
                          child: Text(
                            isEditing
                                ? 'Modifier la republication'
                                : 'Republier cette publication',
                            style: const TextStyle(
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
                                hintText: isEditing
                                    ? 'Modifiez votre commentaire...'
                                    : 'Ajoutez un commentaire à votre republication...',
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
                                  if (isEditing) {
                                    // Update existing repost
                                    await ApiClient().authenticatedPut(
                                      '/posts/$postId/repost',
                                      body: body,
                                    );
                                    _refreshPosts();
                                  } else {
                                    // Create new repost
                                    await ApiClient().authenticatedPost(
                                      '/posts/$postId/repost',
                                      body: body,
                                    );
                                    _refreshPosts();
                                  }
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
                            : Text(
                                isEditing ? 'Enregistrer' : 'Republier',
                                style: const TextStyle(
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
          SnackBar(
            content: Text(
              isEditing
                  ? 'Republication modifiée avec succès'
                  : 'Publication republiée avec succès',
            ),
            backgroundColor: const Color(0xFF3AAE5E),
            duration: const Duration(seconds: 2),
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
      ],
    );
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

    // Déterminer si l'utilisateur courant est le propriétaire du post
    // Pour un repost, c'est le reposter qui peut modifier/supprimer son repost
    final isOwner =
        _currentUserId != null &&
        (reposter.id == _currentUserId ||
            (!isRepost && author.id == _currentUserId));

    // Can edit: owner AND (not a repost OR is a quote repost with text)
    // Simple reposts (without text) cannot be edited
    final canEdit = isOwner && (!isRepost || isQuoteRepost);

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
      _seedReactionFromFeed('posts', originalPostId, originalPost, force: true);
    } else {
      // Original post or quote repost: reactions are on this post itself
      reactionEntityId = postId;
      if (postId.isNotEmpty) {
        _seedReactionFromFeed(
          'posts',
          postId,
          isQuoteRepost ? raw : raw,
          force: true,
        );
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
      isOwner: isOwner,
      onEdit: canEdit
          ? () {
              // Navigate to edit post screen
              _navigateToEditPost(context, raw);
            }
          : null,
      onDelete: isOwner
          ? () {
              // Show delete confirmation dialog
              _showDeletePostConfirmation(context, postId, isRepost);
            }
          : null,
    );
  }

  void _navigateToEditPost(
    BuildContext context,
    Map<String, dynamic> postData,
  ) async {
    final postId = postData['id']?.toString();
    if (postId == null) return;

    // Check if it's a repost (quote repost with content)
    final isRepost = postData['original_post_id'] != null;
    final repostContent = postData['repost_content']?.toString();
    final isQuoteRepost =
        isRepost && repostContent != null && repostContent.trim().isNotEmpty;

    if (isQuoteRepost) {
      // For quote reposts, open the repost modal with pre-filled content
      await _repostPost(
        postId,
        originalPostData: postData,
        initialText: repostContent,
        isEditing: true,
      );
      _refreshPosts();
    } else if (isRepost) {
      // Simple repost - no content to edit, show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Les republications simples ne peuvent pas être modifiées',
            ),
          ),
        );
      }
    } else {
      // Regular post - navigate to CreatePostScreen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreatePostScreen(postId: postId, initialData: postData),
        ),
      );
      if (result == 'updated' && mounted) {
        _refreshPosts();
      }
    }
  }

  void _showDeletePostConfirmation(
    BuildContext context,
    String postId,
    bool isRepost,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRepost ? 'Supprimer le repost?' : 'Supprimer le post?'),
        content: Text(
          isRepost
              ? 'Voulez-vous vraiment supprimer ce repost? Cette action est irréversible.'
              : 'Voulez-vous vraiment supprimer ce post? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(postId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
