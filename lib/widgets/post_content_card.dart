import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PostTag {
  final String title;
  final IconData icon;
  final Color color;

  PostTag({required this.title, required this.icon, required this.color});
}

class PostContentCard extends StatelessWidget {
  final List<PostTag> tags;
  final PostTag? subtags;
  final String title;
  final String time;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final String? imageUrl;
  final List<String>? imageUrls;
  final VoidCallback? onMorePressed;

  const PostContentCard({
    super.key,
    required this.tags,
    this.subtags,
    required this.title,
    required this.time,
    this.onLike,
    this.onShare,
    this.imageUrl,
    this.imageUrls,
    this.onMorePressed,
  });

  List<String> get _effectiveUrls {
    if (imageUrls != null && imageUrls!.isNotEmpty) return imageUrls!;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  bool _isVideoUrl(String url) {
    final videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.quicktime',
      '.x-msvideo',
    ];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  Widget _buildMediaItem(
    String url, {
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (_isVideoUrl(url)) {
      return _VideoThumbnailWidget(videoUrl: url, height: height, fit: fit);
    }
    return Image.network(
      url,
      fit: fit,
      height: height,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 14, right: 14, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (subtags != null) _buildTag(subtags!),
                ...tags.map((tag) => _buildTag(tag)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF616161),
              height: 1.4,
            ),
          ),
          // Post image(s)
          if (_effectiveUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMediaGrid(_effectiveUrls),
          ],
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // IconButton(
                  //   onPressed: onLike,
                  //   icon: Icon(
                  //     Icons.favorite_border,
                  //     color: Colors.grey[500],
                  //     size: 20,
                  //   ),
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(),
                  // ),
                  // IconButton(
                  //   onPressed: onShare,
                  //   icon: Icon(Icons.reply, color: Colors.grey[500], size: 20),
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(),
                  // ),
                  if (onMorePressed != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onMorePressed,
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaItem(urls[0], height: 180),
      );
    }
    if (urls.length == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(child: _buildMediaItem(urls[0], height: 160)),
              const SizedBox(width: 3),
              Expanded(child: _buildMediaItem(urls[1], height: 160)),
            ],
          ),
        ),
      );
    }
    if (urls.length == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildMediaItem(urls[0], height: 180)),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildMediaItem(urls[1])),
                    const SizedBox(height: 3),
                    Expanded(child: _buildMediaItem(urls[2])),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 4+ images: 2x2 grid with overflow counter on the last cell
    final int remaining = urls.length - 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(urls[0])),
                  const SizedBox(width: 3),
                  Expanded(child: _buildMediaItem(urls[1])),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(urls[2])),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(urls[3]),
                        if (remaining > 0)
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildTag(PostTag tag) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tag.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 14, color: tag.color),
          const SizedBox(width: 6),
          Text(
            tag.title,
            style: TextStyle(
              color: tag.color,
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple video thumbnail widget with fallback
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

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 500,
        quality: 80,
        timeMs: 5000,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_thumbnailData != null)
            Image.memory(
              _thumbnailData!,
              fit: widget.fit,
              width: double.infinity,
            )
          else
            Container(
              color: Colors.black87,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          // Play icon overlay
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          // VIDEO badge
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
