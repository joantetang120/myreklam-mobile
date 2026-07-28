import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';
import 'package:video_player/video_player.dart';

bool _isVideoUrl(String url) {
  final videoExtensions = ['.mp4', '.mov', '.avi', '.quicktime', '.x-msvideo'];
  final lowerUrl = url.toLowerCase();
  return videoExtensions.any((ext) => lowerUrl.contains(ext));
}

class _InlineVideoPlayer extends StatefulWidget {
  final String url;

  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initError = false;
  bool _isMuted = true;
  Timer? _positionTimer;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      await _controller!.play();
      _startPositionTimer();
    } catch (_) {
      if (mounted) setState(() => _initError = true);
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final c = _controller;
      if (!mounted || c == null || !c.value.isInitialized) return;
      final newPos = c.value.position;
      if (newPos.inSeconds != _position.inSeconds) {
        setState(() {
          _position = newPos;
        });
      }
    });
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
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final newMuted = !_isMuted;
    await c.setVolume(newMuted ? 0.0 : 1.0);
    if (mounted) {
      setState(() {
        _isMuted = newMuted;
      });
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Constrain video height to avoid taking too much screen space
    const maxVideoHeight = 400.0;

    if (_initError) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxVideoHeight),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxVideoHeight),
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final duration = c.value.duration;
    final remaining = _remaining(duration, _position);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxVideoHeight),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio == 0
                ? 16 / 9
                : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
          // Duration countdown (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
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
          // Mute toggle (top-left)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
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
}

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
                  ReklamAvatar(
                    avatarUrl: author['avatar'],
                    displayName: author['displayName'],
                    radius: 24,
                    accountType: author['accountType'],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
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
                children: mediaUrls
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _isVideoUrl(url)
                            ? _InlineVideoPlayer(url: url)
                            : Image.network(
                                url,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Reaction Bar
            Padding(padding: const EdgeInsets.all(16.0), child: reactionBar),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
