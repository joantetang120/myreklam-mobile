import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myreklam/screens/reels_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/reel_service.dart';
import 'package:myreklam/services/video_compression_service.dart';
import 'package:video_player/video_player.dart';
import 'package:myreklam/models/social_video.dart';
import 'package:myreklam/widgets/social_video_preview.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  static const int _maxBytes = 50 * 1024 * 1024;
  final _caption = TextEditingController();
  final _link = TextEditingController();
  final _picker = ImagePicker();
  final _service = ReelService();
  File? _video;
  VideoPlayerController? _controller;
  bool _publishing = false;
  bool _compressing = false;
  String _visibility = 'public';

  @override
  void dispose() {
    _caption.dispose();
    _link.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    if (_publishing || _compressing) return;
    setState(() => _compressing = true);
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      if (mounted) setState(() => _compressing = true);
      final compressed = await VideoCompressionService.compress(
        File(picked.path),
      );
      final file = compressed.file;
      if (compressed.compressedBytes > _maxBytes) {
        if (mounted) setState(() => _compressing = false);
        _message(
          'La vidéo reste supérieure à 50 Mo après compression.',
          error: true,
        );
        return;
      }
      final next = VideoPlayerController.file(file);
      try {
        await next.initialize();
        await next.setLooping(true);
        await next.play();
      } catch (_) {
        await next.dispose();
        if (mounted) setState(() => _compressing = false);
        _message('Cette vidéo ne peut pas être lue.', error: true);
        return;
      }
      await _controller?.dispose();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _video = file;
        _link.clear();
        _controller = next;
        _compressing = false;
      });
      if (compressed.wasCompressed) {
        final before = compressed.originalBytes / (1024 * 1024);
        final after = compressed.compressedBytes / (1024 * 1024);
        _message(
          'Vidéo compressée : ${before.toStringAsFixed(1)} Mo → ${after.toStringAsFixed(1)} Mo.',
        );
      }
    } catch (_) {
      _message('Impossible de préparer cette vidéo. Réessayez.', error: true);
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  Future<void> _publish() async {
    final video = _video;
    final external = SocialVideo.parse(_link.text);
    if ((video == null && external == null) || _publishing) return;
    setState(() => _publishing = true);
    try {
      final id = await _service.publish(
        video: video,
        videoLink: video == null ? external?.url : null,
        caption: _caption.text,
        visibility: _visibility,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReelsScreen(initialReelId: id)),
      );
    } on ApiException catch (error) {
      _message(error.firstError, error: true);
    } catch (_) {
      _message('Le Reel n’a pas pu être publié. Réessayez.', error: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08110E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08110E),
        foregroundColor: Colors.white,
        title: const Text('Créer un Reel'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextField(
              controller: _link,
              enabled: !_publishing && !_compressing,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Ou collez un lien vidéo',
                hintText: 'YouTube, Facebook, Instagram ou TikTok',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white54),
              ),
              onChanged: (_) {
                final previous = _controller;
                setState(() {
                  _video = null;
                  _controller = null;
                });
                previous?.dispose();
              },
            ),
            if (_link.text.isNotEmpty) SocialVideoPreview(text: _link.text),
            if (_link.text.isNotEmpty && SocialVideo.parse(_link.text) == null)
              const Text(
                'Collez un lien vidéo public valide.',
                style: TextStyle(color: Colors.orange),
              ),
            if (_link.text.isEmpty)
              AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _controller?.value.isInitialized == true
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          }),
                          child: VideoPlayer(_controller!),
                        )
                      : Material(
                          color: Colors.white.withValues(alpha: .08),
                          child: InkWell(
                            onTap: _compressing ? null : _pickVideo,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  color: Colors.white,
                                  size: 52,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Choisir une vidéo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Compression automatique · 50 Mo maximum',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            if (_video != null)
              TextButton.icon(
                onPressed: _publishing || _compressing ? null : _pickVideo,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Changer la vidéo'),
              ),
            if (_compressing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Compression de la vidéo…',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLength: 500,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Légende',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _visibility,
              dropdownColor: const Color(0xFF17221E),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Visibilité',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'friends', child: Text('Amis')),
                DropdownMenuItem(value: 'private', child: Text('Privé')),
              ],
              onChanged: _publishing
                  ? null
                  : (value) => setState(() => _visibility = value ?? 'public'),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed:
                  (_video == null && SocialVideo.parse(_link.text) == null) ||
                      _publishing ||
                      _compressing
                  ? null
                  : _publish,
              icon: _publishing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_creation_outlined),
              label: Text(
                _publishing ? 'Publication en cours…' : 'Publier le Reel',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
