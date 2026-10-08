import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/models/social_video.dart';

/// Uses the same bounded metadata endpoint as the web. Never sends auth tokens.
class SocialVideoPreview extends StatefulWidget {
  final String text;
  const SocialVideoPreview({super.key, required this.text});
  @override
  State<SocialVideoPreview> createState() => _SocialVideoPreviewState();
}

class _SocialVideoPreviewState extends State<SocialVideoPreview> {
  static final Map<String, Map<String, dynamic>> _cache = {};
  SocialVideo? _video;
  Map<String, dynamic>? _metadata;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant SocialVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _resolve();
  }

  Future<void> _resolve() async {
    final video = SocialVideo.fromText(widget.text);
    if (video?.url == _video?.url) return;
    final generation = ++_generation;
    _video = video;
    _metadata = video == null ? null : _cache[video.url];
    if (video == null || _metadata != null) return;
    try {
      final response = await http
          .get(
            Uri.https('www.myreklam.fr', '/api/social-preview', {
              'url': video.url,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! Map) return;
      final metadata = Map<String, dynamic>.from(data);
      if (_cache.length >= 100) _cache.remove(_cache.keys.first);
      _cache[video.url] = metadata;
      if (mounted && generation == _generation)
        setState(() => _metadata = metadata);
    } catch (_) {
      /* Keep a usable platform card when metadata is blocked. */
    }
  }

  Future<void> _open() async {
    try {
      if (await launchUrl(
        Uri.parse(_video!.url),
        mode: LaunchMode.externalApplication,
      ))
        return;
    } catch (_) {}
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la vidéo. Réessayez.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video == null) return const SizedBox.shrink();
    final raw = _metadata?['thumbnail']?.toString() ?? video.thumbnail;
    final thumbnail = raw != null && Uri.tryParse(raw)?.scheme == 'https'
        ? raw
        : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumbnail != null)
              Image.network(
                thumbnail,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ListTile(
              leading: const Icon(Icons.play_circle_fill, size: 36),
              title: Text(
                _metadata?['title']?.toString() ?? 'Vidéo ${video.provider}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Ouvrir sur ${video.provider}'),
              trailing: const Icon(Icons.open_in_new),
            ),
          ],
        ),
      ),
    );
  }
}
