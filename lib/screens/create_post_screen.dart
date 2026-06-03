import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  final String? postId;
  final Map<String, dynamic>? initialData;
  final VoidCallback? onPostCreated;
  final VoidCallback? onBackPressed;

  const CreatePostScreen({
    super.key,
    this.postId,
    this.initialData,
    this.onPostCreated,
    this.onBackPressed,
  });

  bool get isEditMode => postId != null;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedPrivacy = 'public';
  bool _isPosting = false;
  bool _isUploadingMedia = false;
  List<PlatformFile> _selectedMediaFiles = [];
  bool _showLocationField = false;
  List<Map<String, dynamic>> _existingMedia = [];
  final List<int> _deletedMediaIds = [];
  String? _userAvatar;
  String? _username;
  bool _isLoadingAvatar = true;

  bool get _isEditMode => widget.isEditMode;

  static const _visibilityOptions = [
    {'value': 'public', 'label': 'Public'},
    {'value': 'friends', 'label': 'Amis'},
    {'value': 'private', 'label': 'Privé'},
  ];

  String get _privacyLabel => _visibilityOptions.firstWhere(
    (o) => o['value'] == _selectedPrivacy,
  )['label']!;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.initialData != null) {
      _prefillFromData(widget.initialData!);
    }
    _fetchUserAvatar();
  }

  Future<void> _fetchUserAvatar() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final user = response['profile'] as Map<String, dynamic>?;

      final avatarUrl =
          user?['avatar_url']?.toString() ?? user?['avatar']?.toString();

      // Get username from display_name, name, or pseudo fields
      final displayName = user?['display_name']?.toString();
      final name = user?['name']?.toString();
      final pseudo = user?['pseudo']?.toString();
      final username = displayName?.isNotEmpty == true
          ? displayName
          : (name?.isNotEmpty == true ? name : pseudo);

      if (mounted) {
        setState(() {
          _userAvatar = ApiConfig.resolveMediaUrl(avatarUrl);
          _username = username;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvatar = false);
      }
    }
  }

  void _prefillFromData(Map<String, dynamic> data) {
    _postController.text = data['content']?.toString() ?? '';
    _selectedPrivacy = data['visibility']?.toString() ?? 'public';
    final locationLabel = data['location_label']?.toString();
    if (locationLabel != null && locationLabel.isNotEmpty) {
      _locationController.text = locationLabel;
      _showLocationField = true;
    }
    final mediaFiles =
        data['media_files'] as List? ?? data['media'] as List? ?? [];
    _existingMedia = mediaFiles.whereType<Map<String, dynamic>>().toList();
  }

  @override
  void dispose() {
    _postController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (_selectedMediaFiles.length >= 10) {
      _showSnack('Maximum 10 fichiers autorisés.', isError: true);
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov'],
        withData: true,
      );
      if (result == null) return;
      final remaining = 10 - _selectedMediaFiles.length;
      final toAdd = result.files.take(remaining).toList();
      setState(() => _selectedMediaFiles.addAll(toAdd));
    } catch (_) {
      _showSnack('Impossible d\'accéder aux fichiers.', isError: true);
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedMediaFiles.removeAt(index));
  }

  Future<void> _publishPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) {
      _showSnack('Le contenu ne peut pas être vide.', isError: true);
      return;
    }

    setState(() => _isPosting = true);
    try {
      final body = <String, dynamic>{
        'content': content,
        'visibility': _selectedPrivacy,
      };
      final locationText = _locationController.text.trim();
      if (_showLocationField && locationText.isNotEmpty) {
        body['location_label'] = locationText;
      } else {
        body['location_label'] = null;
        body['latitude'] = null;
        body['longitude'] = null;
      }

      String? postId;
      if (_isEditMode) {
        await ApiClient().authenticatedPut(
          '/posts/${widget.postId}',
          body: body,
        );
        postId = widget.postId;
        // Delete removed media
        for (final mediaId in _deletedMediaIds) {
          try {
            await ApiClient().authenticatedDelete(
              '/posts/$postId/media/$mediaId',
            );
          } catch (_) {}
        }
        if (postId != null && _selectedMediaFiles.isNotEmpty) {
          await _uploadMediaFiles(postId);
        }
        if (!mounted) return;
        _showSnack('Post mis à jour avec succès !');
      } else {
        final response = await ApiClient().authenticatedPost(
          '/posts',
          body: body,
        );
        postId = response['data']?['id']?.toString();
        if (postId != null && _selectedMediaFiles.isNotEmpty) {
          await _uploadMediaFiles(postId);
        }
        if (!mounted) return;
        _showSnack('Post publié avec succès !');
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      if (widget.onPostCreated != null) {
        widget.onPostCreated!();
      } else {
        Navigator.pop(context, 'updated');
      }
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack(
        'Erreur lors de ${_isEditMode ? 'la mise à jour' : 'la publication'}.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<bool> _uploadMediaFiles(String postId) async {
    setState(() => _isUploadingMedia = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;
      final uri = Uri.parse('${ApiConfig.baseUrl}/posts/$postId/media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';
      for (final file in _selectedMediaFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files[]',
              file.path!,
              filename: file.name,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'files[]',
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        setState(() => _selectedMediaFiles.clear());
        return true;
      }
      final msg =
          _extractErrorMessage(body) ??
          'Impossible d\'envoyer les médias (${streamed.statusCode}).';
      _showSnack(msg, isError: true);
      return false;
    } catch (_) {
      _showSnack('Échec de l\'upload des médias.', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['errors'] != null) {
          final errors = decoded['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final first = errors.values.first;
            if (first is List && first.isNotEmpty)
              return first.first.toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showVisibilityPicker() {
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
            const SizedBox(height: 16),
            const Text(
              'Visibilité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._visibilityOptions.map(
              (opt) => ListTile(
                leading: Icon(
                  opt['value'] == 'public'
                      ? Icons.public
                      : opt['value'] == 'friends'
                      ? Icons.people_outline
                      : Icons.lock_outline,
                  color: _selectedPrivacy == opt['value']
                      ? const Color(0xFFFF9800)
                      : Colors.grey[700],
                ),
                title: Text(opt['label']!),
                trailing: _selectedPrivacy == opt['value']
                    ? const Icon(Icons.check, color: Color(0xFFFF9800))
                    : null,
                onTap: () {
                  setState(() => _selectedPrivacy = opt['value']!);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
          onPressed: () {
            if (_isEditMode) {
              Navigator.pop(context);
            } else if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ParticulierMainScreen(initialIndex: 0),
                ),
              );
            }
          },
        ),
        title: Text(
          _isEditMode ? 'Modifier le post' : 'Créer un post',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: avatar + visibility + publish button
              Row(
                children: [
                  _isLoadingAvatar
                      ? Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : ReklamAvatar(
                          avatarUrl: _userAvatar,
                          displayName: _username,
                          radius: 25,
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? 'Mon compte',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showVisibilityPicker,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedPrivacy == 'public'
                                    ? Icons.public
                                    : _selectedPrivacy == 'friends'
                                    ? Icons.people_outline
                                    : Icons.lock_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _privacyLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (_isPosting || _isUploadingMedia)
                        ? null
                        : _publishPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: (_isPosting || _isUploadingMedia)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Mettre à jour' : 'Publier',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content text field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _postController,
                  maxLines: 8,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    hintText: 'Quoi de neuf?',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Partagez un moment ou une information avec votre communauté',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Existing media previews (edit mode)
              if (_existingMedia.isNotEmpty) ...[
                _buildExistingMediaGrid(),
                const SizedBox(height: 12),
              ],
              // New media previews grid
              if (_selectedMediaFiles.isNotEmpty) ...[
                _buildMediaGrid(),
                const SizedBox(height: 16),
              ],

              // Location field (shown when toggled)
              if (_showLocationField) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Color(0xFFFF9800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: 'Ex: Paris, France',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _showLocationField = false;
                            _locationController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              _buildActionButton(
                icon: Icons.image_outlined,
                label: _selectedMediaFiles.isEmpty
                    ? 'Photos / Vidéos'
                    : 'Photos / Vidéos (${_selectedMediaFiles.length}/10)',
                color: const Color(0xFF00BCD4),
                onTap: _pickMedia,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.location_on_outlined,
                label: 'Ajouter un lieu',
                color: const Color(0xFFFF9800),
                onTap: () =>
                    setState(() => _showLocationField = !_showLocationField),
              ),
              const SizedBox(height: 40),

              // Bottom publish button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isPosting || _isUploadingMedia)
                      ? null
                      : _publishPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: (_isPosting || _isUploadingMedia)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Mettre à jour' : 'Publier',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedMediaFiles.length,
      itemBuilder: (_, i) {
        final file = _selectedMediaFiles[i];
        final ext = file.extension?.toLowerCase() ?? '';
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
        final isVideo = ['mp4', 'mov', 'avi'].contains(ext);

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage && file.bytes != null
                  ? Image.memory(file.bytes!, fit: BoxFit.cover)
                  : isVideo && file.path != null
                  ? _VideoThumbnailWidget(videoPath: file.path!)
                  : Container(
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
            ),
            if (isVideo)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeMedia(i),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase$url';
  }

  Widget _buildExistingMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _existingMedia.length,
      itemBuilder: (_, i) {
        final media = _existingMedia[i];
        final url = _buildStorageUrl(media['url']?.toString());
        final fileType = media['file_type']?.toString() ?? 'image';
        final isImage = fileType == 'image';
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : url.isNotEmpty
                  ? _VideoThumbnailWidget(videoPath: url)
                  : Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            if (!isImage)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  final mediaId = media['id'];
                  if (mediaId != null) {
                    _deletedMediaIds.add(
                      mediaId is int
                          ? mediaId
                          : int.tryParse(mediaId.toString()) ?? 0,
                    );
                  }
                  setState(() => _existingMedia.removeAt(i));
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display video thumbnail using video_thumbnail package
class _VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;

  const _VideoThumbnailWidget({required this.videoPath});

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
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_thumbnailData != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_thumbnailData!, fit: BoxFit.cover),
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
      );
    }

    // Fallback if thumbnail generation failed
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 40, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }
}
