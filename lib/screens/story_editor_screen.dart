import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
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
                Column(
                  children: [
                    if (!_isEditingText)
                      _buildCircleIconButton(
                        icon: Icons.text_fields,
                        label: 'Aa',
                        onTap: _startTextEditing,
                      ),
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
                    if (!_isEditingText) const SizedBox(height: 12),
                    if (!_isEditingText)
                      _buildCircleIconButton(icon: Icons.keyboard_arrow_down),
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

          // Bottom Section - Hidden when editing text
          if (!_isEditingText)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    TextField(
                      maxLength: 300,
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter une légende...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        counterStyle: const TextStyle(
                          color: Colors.transparent,
                        ),
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
