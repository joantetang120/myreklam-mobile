import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/models/story_overlay.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/story_service.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class StoryEditorScreen extends StatefulWidget {
  final AssetEntity? asset;
  final XFile? cameraFile;

  const StoryEditorScreen({super.key, this.asset, this.cameraFile})
    : assert(
        asset != null || cameraFile != null,
        'Either asset or cameraFile must be provided',
      );

  Future<Uint8List?> _getImageBytes() async {
    if (cameraFile != null) {
      return File(cameraFile!.path).readAsBytes();
    }
    return asset?.originBytes;
  }

  Future<String> _getFileName() async {
    if (cameraFile != null) {
      return cameraFile!.name;
    }
    return await asset!.titleAsync;
  }

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final TextEditingController _captionController = TextEditingController();
  final StoryService _storyService = StoryService();
  bool _isUploading = false;
  String? _userAvatar;

  // Video playback state
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;

  // Text overlay state - simplified WhatsApp style
  bool _isEditingText = false;
  String _overlayText = '';
  double _textX = 0.5;
  double _textY = 0.5;
  Color _textColor = Colors.black;
  int _textStyleIndex = 4;

  final _textEditController = TextEditingController();
  final _textFocusNode = FocusNode();
  final _colorBarKey = GlobalKey();

  // Mentions (@) state
  List<MentionUser> _followers = [];
  bool _followersLoaded = false;
  bool _showMentions = false;
  List<MentionUser> _mentionSuggestions = [];
  final Map<int, String> _selectedMentions = {}; // userId -> displayed name

  // Structured overlays (stickers, location, drawing)
  final List<StoryOverlay> _overlays = [];
  int? _selectedOverlayIndex;
  double _gestureBaseScale = 1.0;
  double _gestureBaseRotation = 0.0;

  // Drawing mode
  bool _isDrawing = false;
  final List<DrawStroke> _drawStrokes = [];
  List<Offset> _currentStroke = [];
  Color _drawColor = Colors.white;
  double _drawWidth = 6.0;
  bool _isAddingLocation = false;

  static const List<Color> _drawColors = [
    Colors.white,
    Colors.black,
    Color(0xFFE53935),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
  ];

  static const List<String> _stickerEmojis = [
    '❤️', '😂', '😍', '🔥', '👍', '🎉', '😎', '🥳', '😭', '🙌',
    '✨', '💯', '😱', '🤩', '😡', '🤔', '👏', '🙏', '💪', '🌟',
    '⚡', '🌈', '☀️', '🌙', '⭐', '💔', '💖', '🎁', '🏆', '👑',
    '🍕', '🍔', '☕', '🍻', '⚽', '🏀', '🎵', '📍', '✅', '❌',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Check if asset is video via AssetEntity type
    if (widget.asset != null) {
      if (widget.asset!.type == AssetType.video) {
        setState(() => _isVideo = true);
        await _initializeVideoPlayer();
      }
    } else if (widget.cameraFile != null) {
      // Check file extension for camera file
      final name = widget.cameraFile!.name.toLowerCase();
      if (name.endsWith('.mp4') ||
          name.endsWith('.mov') ||
          name.endsWith('.avi') ||
          name.endsWith('.mkv') ||
          name.endsWith('.3gp') ||
          name.endsWith('.webm')) {
        setState(() => _isVideo = true);
        await _initializeVideoPlayer();
      }
    }
  }

  Future<String?> _getFilePath() async {
    if (widget.cameraFile != null) {
      return widget.cameraFile!.path;
    }
    if (widget.asset != null) {
      final file = await widget.asset!.file;
      return file?.path;
    }
    return null;
  }

  Future<void> _initializeVideoPlayer() async {
    final path = await _getFilePath();
    if (path == null) return;

    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();

    // Add listener to limit playback to 1 minute (videos longer than 1min will be truncated)
    _videoController!.addListener(_limitVideoDuration);

    if (mounted) {
      setState(() => _isVideoInitialized = true);
      _videoController!.play();
      _videoController!.setLooping(true);

      // Auto-hide controls after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showVideoControls = false);
        }
      });
    }
  }

  void _limitVideoDuration() {
    if (_videoController?.value.isInitialized != true) return;

    final position = _videoController!.value.position;
    const oneMinute = Duration(minutes: 1);

    // If video exceeds 1 minute, seek back to start (loop only first minute)
    if (position >= oneMinute) {
      _videoController!.seekTo(Duration.zero);
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _showVideoControls = true;
    });

    // Auto-hide controls after 2 seconds if playing
    if (_videoController!.value.isPlaying) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _videoController?.value.isPlaying == true) {
          setState(() => _showVideoControls = false);
        }
      });
    }
  }

  void _showControls() {
    setState(() => _showVideoControls = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _videoController?.value.isPlaying == true) {
        setState(() => _showVideoControls = false);
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final userData = response['profile'] as Map<String, dynamic>?;
      if (mounted && userData != null) {
        setState(() {
          _userAvatar = userData['avatar_url']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // ─── Mentions (@) ──────────────────────────────────────────────────────────

  Future<void> _ensureFollowersLoaded() async {
    if (_followersLoaded) return;
    _followersLoaded = true;
    final followers = await _storyService.getMyFollowers();
    if (mounted) _followers = followers;
  }

  /// Detect an in-progress "@token" at the cursor and show the picker.
  void _onCaptionChanged(String text) {
    final sel = _captionController.selection;
    final cursor = (sel.baseOffset >= 0 ? sel.baseOffset : text.length)
        .clamp(0, text.length);
    final beforeCursor = text.substring(0, cursor);
    final match = RegExp(r'@([\p{L}0-9_]*)$', unicode: true)
        .firstMatch(beforeCursor);

    if (match == null) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    final query = match.group(1)!.toLowerCase();
    _ensureFollowersLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _showMentions = true;
        _mentionSuggestions = _followers
            .where((f) => f.name.toLowerCase().contains(query))
            .take(30)
            .toList();
      });
    });
  }

  void _selectMention(MentionUser user) {
    final text = _captionController.text;
    final sel = _captionController.selection;
    final cursor = (sel.baseOffset >= 0 ? sel.baseOffset : text.length)
        .clamp(0, text.length);
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final atIndex = before.lastIndexOf('@');
    if (atIndex < 0) return;

    final newBefore = '${before.substring(0, atIndex)}@${user.name} ';
    final newText = newBefore + after;
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newBefore.length),
    );
    _selectedMentions[user.id] = user.name;
    setState(() => _showMentions = false);
  }

  /// Mentions still present in the caption at publish time.
  List<int> _resolveMentions() {
    final caption = _captionController.text;
    return _selectedMentions.entries
        .where((e) => caption.contains('@${e.value}'))
        .map((e) => e.key)
        .toList();
  }

  Widget _buildMentionSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: _mentionSuggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun abonné à mentionner',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _mentionSuggestions.length,
              itemBuilder: (context, index) {
                final user = _mentionSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: ReklamAvatar(
                    avatarUrl: user.avatar,
                    displayName: user.name,
                    radius: 16,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectMention(user),
                );
              },
            ),
    );
  }

  // ─── Overlays: stickers / location / drawing ───────────────────────────────

  String _overlaysJson() => jsonEncode(StoryOverlay.listToJson(_overlays));

  void _openStickerPicker() {
    setState(() => _selectedOverlayIndex = null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stickers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    children: [
                      for (final emoji in _stickerEmojis)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addSticker(emoji);
                          },
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addSticker(String emoji) {
    setState(() {
      _overlays.add(StickerOverlay(emoji: emoji, x: 0.5, y: 0.45));
      _selectedOverlayIndex = _overlays.length - 1;
    });
  }

  Future<void> _addLocation() async {
    if (_isAddingLocation) return;
    setState(() => _isAddingLocation = true);
    try {
      // Permission + position
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Permission de localisation refusée';
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 12));

      String name = 'Ma position';
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = (p.locality?.isNotEmpty == true)
              ? p.locality!
              : (p.subAdministrativeArea ?? p.administrativeArea ?? '');
          final area = p.subLocality?.isNotEmpty == true ? p.subLocality! : '';
          name = [area, city].where((s) => s.isNotEmpty).join(', ');
          if (name.isEmpty) name = p.country ?? 'Ma position';
        }
      } catch (_) {
        // Keep fallback name if reverse geocoding fails.
      }

      if (!mounted) return;
      setState(() {
        _overlays.add(LocationOverlay(
          name: name,
          lat: pos.latitude,
          lng: pos.longitude,
          x: 0.5,
          y: 0.8,
        ));
        _selectedOverlayIndex = _overlays.length - 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Localisation indisponible: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingLocation = false);
    }
  }

  void _deleteSelectedOverlay() {
    if (_selectedOverlayIndex == null) return;
    setState(() {
      _overlays.removeAt(_selectedOverlayIndex!);
      _selectedOverlayIndex = null;
    });
  }

  Widget _buildOverlaysLayer() {
    return Stack(
      children: [
        for (int i = 0; i < _overlays.length; i++)
          if (_overlays[i] is DrawingOverlay)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: StoryDrawingPainter(
                    (_overlays[i] as DrawingOverlay).strokes,
                  ),
                ),
              ),
            )
          else if (_overlays[i] is PositionedOverlay)
            _buildInteractiveOverlay(i),
      ],
    );
  }

  Widget _buildInteractiveOverlay(int index) {
    final o = _overlays[index] as PositionedOverlay;
    final size = MediaQuery.of(context).size;
    final selected = _selectedOverlayIndex == index;

    return Positioned(
      left: o.x * size.width,
      top: o.y * size.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => setState(() => _selectedOverlayIndex = index),
          onScaleStart: (_) {
            _gestureBaseScale = o.scale;
            _gestureBaseRotation = o.rotation;
            setState(() => _selectedOverlayIndex = index);
          },
          onScaleUpdate: (d) {
            setState(() {
              o.x = (o.x + d.focalPointDelta.dx / size.width).clamp(0.0, 1.0);
              o.y = (o.y + d.focalPointDelta.dy / size.height).clamp(0.0, 1.0);
              o.scale = (_gestureBaseScale * d.scale).clamp(0.3, 5.0);
              o.rotation = _gestureBaseRotation + d.rotation;
            });
          },
          child: Transform.rotate(
            angle: o.rotation,
            child: Transform.scale(
              scale: o.scale,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: buildOverlayChild(o),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Drawing mode ───────────────────────────────────────────────────────────

  void _enterDrawMode() {
    // Resume from an existing drawing if present.
    final existingIndex =
        _overlays.indexWhere((o) => o is DrawingOverlay);
    setState(() {
      _selectedOverlayIndex = null;
      _drawStrokes.clear();
      if (existingIndex >= 0) {
        _drawStrokes.addAll((_overlays[existingIndex] as DrawingOverlay).strokes);
      }
      _isDrawing = true;
    });
  }

  void _commitDrawing() {
    setState(() {
      _overlays.removeWhere((o) => o is DrawingOverlay);
      if (_drawStrokes.isNotEmpty) {
        // Drawing sits at the bottom so stickers stay tappable above it.
        _overlays.insert(0, DrawingOverlay(strokes: List.of(_drawStrokes)));
      }
      _isDrawing = false;
      _currentStroke = [];
    });
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawing = false;
      _currentStroke = [];
      _drawStrokes.clear();
    });
  }

  void _undoStroke() {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _currentStroke = [];
      } else if (_drawStrokes.isNotEmpty) {
        _drawStrokes.removeLast();
      }
    });
  }

  void _onDrawUpdate(Offset localPos, Size size) {
    setState(() {
      _currentStroke.add(
        Offset(
          (localPos.dx / size.width).clamp(0.0, 1.0),
          (localPos.dy / size.height).clamp(0.0, 1.0),
        ),
      );
    });
  }

  void _onDrawEnd() {
    if (_currentStroke.isEmpty) return;
    setState(() {
      _drawStrokes.add(DrawStroke(
        color: _drawColor.value,
        width: _drawWidth,
        points: List.of(_currentStroke),
      ));
      _currentStroke = [];
    });
  }

  Widget _buildDrawingMode() {
    final size = MediaQuery.of(context).size;
    final liveStrokes = [
      ..._drawStrokes,
      if (_currentStroke.isNotEmpty)
        DrawStroke(
          color: _drawColor.value,
          width: _drawWidth,
          points: _currentStroke,
        ),
    ];

    return Positioned.fill(
      child: Stack(
        children: [
          // Drawing canvas
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onDrawUpdate(d.localPosition, size),
            onPanUpdate: (d) => _onDrawUpdate(d.localPosition, size),
            onPanEnd: (_) => _onDrawEnd(),
            child: CustomPaint(
              size: Size.infinite,
              painter: StoryDrawingPainter(liveStrokes),
            ),
          ),
          // Top actions
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _cancelDrawing,
                  child: const Text('Annuler',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                Row(
                  children: [
                    _buildCircleIconButton(
                      icon: Icons.undo,
                      onTap: _undoStroke,
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _commitDrawing,
                      child: const Text('Terminé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Color palette
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _drawColors.length,
                itemBuilder: (context, i) {
                  final c = _drawColors[i];
                  final isSel = c.value == _drawColor.value;
                  return GestureDetector(
                    onTap: () => setState(() => _drawColor = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isSel ? 3 : 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return ReklamAvatar(
      avatarUrl: _userAvatar,
      radius: 12,
    );
  }

  void _startTextEditing() {
    _textEditController.text = _overlayText;
    setState(() {
      _isEditingText = true;
    });
    // Auto focus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textFocusNode.requestFocus();
    });
  }

  void _finishTextEditing() {
    setState(() {
      _overlayText = _textEditController.text.trim();
      _isEditingText = false;
    });
    _textFocusNode.unfocus();
  }

  void _deleteText() {
    setState(() {
      _overlayText = '';
      _isEditingText = false;
    });
    _textEditController.clear();
  }

  void _onTextDragUpdate(DragUpdateDetails details) {
    setState(() {
      _textX += details.delta.dx / MediaQuery.of(context).size.width;
      _textY += details.delta.dy / MediaQuery.of(context).size.height;
      _textX = _textX.clamp(0.1, 0.9);
      _textY = _textY.clamp(0.1, 0.9);
    });
  }

  void _setTextColor(Color color) {
    setState(() {
      _textColor = color;
    });
  }

  Color _getTextBackgroundColor() {
    if (_textColor == Colors.white ||
        _textColor == Colors.yellow ||
        _textColor == Colors.lime ||
        _textColor == Colors.cyan) {
      return Colors.black.withOpacity(0.4);
    }
    return Colors.white;
  }

  TextStyle _getTextStyle() {
    final baseStyle = TextStyle(
      color: _textColor,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      shadows: const [
        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );

    final styles = [
      baseStyle, // Modern
      baseStyle.copyWith(
        fontFamily: 'serif',
        fontWeight: FontWeight.w600,
      ), // Classic
      baseStyle.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ), // Typewriter
      baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ), // Wide
      baseStyle.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ), // Bold condensed
    ];
    return styles[_textStyleIndex % styles.length];
  }

  void _setTextStyle(int index) {
    setState(() {
      _textStyleIndex = index;
    });
  }

  FontWeight _getStyleFontWeight(int index) {
    final weights = [
      FontWeight.w700,
      FontWeight.w600,
      FontWeight.w600,
      FontWeight.w500,
      FontWeight.w900,
      FontWeight.w400,
      FontWeight.w800,
    ];
    return weights[index % weights.length];
  }

  String? _getStyleFontFamily(int index) {
    final families = [
      null, // Default
      'serif',
      'monospace',
      null,
      null,
      'cursive',
      null,
    ];
    return families[index % families.length];
  }

  double _getStyleLetterSpacing(int index) {
    final spacings = [0.0, 0.0, 0.0, 1.5, -1.0, 0.5, -0.5];
    return spacings[index % spacings.length];
  }

  @override
  void dispose() {
    _captionController.dispose();
    _textEditController.dispose();
    _textFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _showControls,
      child: Stack(
        fit: StackFit.loose,
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),

          // Play/Pause Button Overlay
          if (_showVideoControls)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),

          // Video Progress Indicator (bottom)
          if (_showVideoControls)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media (Image or Video)
          if (_isVideo)
            _buildVideoPlayer()
          else
            FutureBuilder<Uint8List?>(
              future: widget._getImageBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                return Image.memory(snapshot.data!, fit: BoxFit.contain);
              },
            ),

          // Structured overlays: stickers, location, drawing
          if (!_isDrawing) _buildOverlaysLayer(),

          // Text Display (when not editing)
          if (!_isEditingText && _overlayText.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: _onTextDragUpdate,
                onTap: _startTextEditing,
                child: Stack(
                  children: [
                    Positioned(
                      left: _textX * MediaQuery.of(context).size.width - 100,
                      top: _textY * MediaQuery.of(context).size.height - 25,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTextBackgroundColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _overlayText,
                          style: _getTextStyle(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Text Editing Mode - Center Input with background bubble (only when text exists)
          if (_isEditingText)
            Positioned.fill(
              child: GestureDetector(
                onTap: _finishTextEditing,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: IntrinsicWidth(
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 0,
                            maxWidth: 280,
                          ),
                          padding: _overlayText.isNotEmpty
                              ? const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                )
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            // color: _overlayText.isNotEmpty
                            //     ? _getTextBackgroundColor()
                            //     : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _textEditController,
                            focusNode: _textFocusNode,
                            maxLength: 100,
                            minLines: 1,
                            maxLines: null,
                            textAlign: TextAlign.center,
                            style: _getTextStyle().copyWith(fontSize: 24),
                            decoration: InputDecoration(
                              hintText: 'Ajouter du texte',
                              hintStyle: TextStyle(
                                color: _overlayText.isEmpty
                                    ? Colors.white.withOpacity(0.5)
                                    : _textColor,
                                fontSize: 24,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              counterStyle: const TextStyle(
                                color: Colors.transparent,
                              ),
                            ),
                            onChanged: (text) {
                              setState(() {
                                _overlayText = text;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top Controls (simplified)
          if (!_isDrawing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 2,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Delete button shown when an overlay is selected.
                  if (!_isEditingText && _selectedOverlayIndex != null)
                    _buildCircleIconButton(
                      icon: Icons.delete_outline,
                      onTap: _deleteSelectedOverlay,
                    ),
                  Column(
                    children: [
                      if (!_isEditingText) ...[
                        _buildCircleIconButton(
                          icon: Icons.text_fields,
                          label: 'Aa',
                          onTap: _startTextEditing,
                        ),
                        const SizedBox(height: 12),
                        _buildCircleIconButton(
                          icon: Icons.emoji_emotions_outlined,
                          onTap: _openStickerPicker,
                        ),
                        const SizedBox(height: 12),
                        _buildCircleIconButton(
                          icon: Icons.brush_outlined,
                          onTap: _enterDrawMode,
                        ),
                        const SizedBox(height: 12),
                        _isAddingLocation
                            ? Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : _buildCircleIconButton(
                                icon: Icons.location_on_outlined,
                                onTap: _addLocation,
                              ),
                      ],
                      if (_isEditingText)
                        Row(
                          children: [
                            _buildCircleIconButton(
                              icon: Icons.check,
                              onTap: _finishTextEditing,
                            ),
                            const SizedBox(width: 12),
                            _buildCircleIconButton(
                              icon: Icons.delete,
                              onTap: _deleteText,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Vertical Color Gradient Bar (right side) - WhatsApp style
          if (_isEditingText)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).padding.top + 200,
              bottom: 340,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  // Calculate color based on position within the bar
                  final renderBox =
                      _colorBarKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (renderBox != null) {
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final barHeight = renderBox.size.height;
                    final percentage =
                        localPosition.dy.clamp(0.0, barHeight) / barHeight;
                    final hue = (percentage * 360).clamp(0.0, 360.0);
                    _setTextColor(
                      HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                    );
                  }
                },
                onTapDown: (details) {
                  // Also update color on tap
                  final renderBox =
                      _colorBarKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (renderBox != null) {
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final barHeight = renderBox.size.height;
                    final percentage =
                        localPosition.dy.clamp(0.0, barHeight) / barHeight;
                    final hue = (percentage * 360).clamp(0.0, 360.0);
                    _setTextColor(
                      HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
                    );
                  }
                },
                child: Container(
                  key: _colorBarKey,
                  width: 10,
                  child: Column(
                    children: [
                      // Rainbow gradient bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.cyan,
                                Colors.blue,
                                Colors.purple,
                                Colors.pink,
                                Colors.red,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Section - Hidden when editing text or drawing
          if (!_isEditingText && !_isDrawing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                // Add the system navigation-bar inset so the caption + publish
                // controls sit above it (they were hidden low on Samsung).
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showMentions) _buildMentionSuggestions(),
                    TextField(
                      maxLength: 300,
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      controller: _captionController,
                      onChanged: _onCaptionChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter une légende... (@ pour mentionner)',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: Colors.transparent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _buildUserAvatar(),
                              const SizedBox(width: 8),
                              const Text(
                                'Votre Story',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(width: 10),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 12,
                        //     vertical: 6,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.15),
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Row(
                        //     children: const [
                        //       Icon(Icons.public, color: Colors.white, size: 16),
                        //       SizedBox(width: 6),
                        //       Text(
                        //         'Public',
                        //         style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: 13,
                        //         ),
                        //       ),
                        //       SizedBox(width: 4),
                        //       Icon(
                        //         Icons.keyboard_arrow_down,
                        //         color: Colors.white,
                        //         size: 16,
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _isUploading
                              ? null
                              : () async {
                                  setState(() => _isUploading = true);
                                  try {
                                    Uint8List mediaBytes;

                                    if (_isVideo) {
                                      // For videos, read the file bytes
                                      final path = await _getFilePath();
                                      if (path == null) {
                                        setState(() => _isUploading = false);
                                        return;
                                      }
                                      mediaBytes = await File(
                                        path,
                                      ).readAsBytes();
                                    } else {
                                      // For images, use the existing method
                                      final bytes = await widget
                                          ._getImageBytes();
                                      if (bytes == null) {
                                        setState(() => _isUploading = false);
                                        return;
                                      }
                                      mediaBytes = bytes;
                                    }

                                    final title = await widget._getFileName();
                                    final story = await _storyService.uploadStory(
                                      mediaBytes: mediaBytes,
                                      fileName: title,
                                      caption: _captionController.text.trim(),
                                      overlayText: _overlayText.isNotEmpty
                                          ? _overlayText
                                          : null,
                                      overlayColor: _overlayText.isNotEmpty
                                          ? '#${_textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}'
                                          : null,
                                      overlayStyle: _overlayText.isNotEmpty
                                          ? _textStyleIndex
                                          : null,
                                      overlayX: _overlayText.isNotEmpty
                                          ? _textX
                                          : null,
                                      overlayY: _overlayText.isNotEmpty
                                          ? _textY
                                          : null,
                                      mediaType: _isVideo ? 'video' : 'image',
                                      mentions: _resolveMentions(),
                                      overlaysJson: _overlaysJson(),
                                    );
                                    if (story != null && mounted) {
                                      Navigator.pop(context, story);
                                    } else if (mounted) {
                                      setState(() => _isUploading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Erreur lors de la publication de la story',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isUploading = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
                                  }
                                },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.keyboard_arrow_right,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Font Style Selector - WhatsApp style with circles
          if (_isEditingText)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isSelected = _textStyleIndex == index;
                    return GestureDetector(
                      onTap: () => _setTextStyle(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            width: isSelected ? 0 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 16,
                              fontWeight: _getStyleFontWeight(index),
                              fontFamily: _getStyleFontFamily(index),
                              letterSpacing: _getStyleLetterSpacing(index),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Drawing mode (full-screen, on top of everything)
          if (_isDrawing) _buildDrawingMode(),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    String? label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
