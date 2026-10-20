import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/models/social_video.dart';

/// Uses the same bounded metadata endpoint as the web. Never sends auth tokens.
class SocialVideoPreview extends StatefulWidget {
  final String text;
  final Future<Map<String, dynamic>?> Function(String url)? metadataLoader;
  const SocialVideoPreview({
    super.key,
    required this.text,
    this.metadataLoader,
  });
  @override
  State<SocialVideoPreview> createState() => _SocialVideoPreviewState();
}

class _SocialVideoPreviewState extends State<SocialVideoPreview> {
  static final Map<String, Map<String, dynamic>> _cache = {};
  SocialVideo? _video;
  Map<String, dynamic>? _metadata;
  int _generation = 0;
  bool _externalContentEnabled = false;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant SocialVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _externalContentEnabled = false;
      _resolve();
    }
  }

  void _resolve() {
    ++_generation;
    _video = SocialVideo.fromText(widget.text);
    _metadata = null;
  }

  Future<void> _activate() async {
    final video = _video;
    if (video == null) return;
    final generation = ++_generation;
    setState(() => _externalContentEnabled = true);
    final cached = widget.metadataLoader == null ? _cache[video.url] : null;
    if (cached != null) {
      setState(() => _metadata = cached);
      return;
    }
    try {
      Map<String, dynamic>? metadata;
      if (widget.metadataLoader != null) {
        metadata = await widget.metadataLoader!(video.url);
      } else {
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
        metadata = Map<String, dynamic>.from(data);
      }
      // A withdrawn choice, new link or disposed card invalidates pending results.
      if (!mounted ||
          generation != _generation ||
          !_externalContentEnabled ||
          metadata == null) {
        return;
      }
      if (widget.metadataLoader == null) {
        if (_cache.length >= 100) _cache.remove(_cache.keys.first);
        _cache[video.url] = metadata;
      }
      setState(() => _metadata = metadata);
    } catch (_) {
      /* Keep a usable platform card when metadata is blocked. */
    }
  }

  void _withdraw() {
    ++_generation;
    setState(() {
      _externalContentEnabled = false;
      _metadata = null;
    });
  }

  @override
  void dispose() {
    ++_generation;
    super.dispose();
  }

  Future<void> _open() async {
    try {
      if (await launchUrl(
        Uri.parse(_video!.url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la vidéo. Réessayez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video == null) return const SizedBox.shrink();
    if (!_externalContentEnabled) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.play_circle_outline),
          title: Text('Vidéo ${video.provider}'),
          subtitle: const Text(
            'Afficher l’aperçu peut transmettre votre adresse IP au fournisseur de l’image.',
          ),
          trailing: TextButton(
            onPressed: _activate,
            child: const Text('Afficher'),
          ),
        ),
      );
    }
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
              trailing: IconButton(
                icon: const Icon(Icons.visibility_off_outlined),
                tooltip: 'Masquer le contenu externe',
                onPressed: _withdraw,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
