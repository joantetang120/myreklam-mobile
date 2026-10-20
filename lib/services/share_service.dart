import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myreklam/config/api_config.dart';

/// Centralised share service for all entity types.
/// Uses the configured backend deep links so mobile users can open the app.
class ShareService {
  static String get _baseUrl => ApiConfig.publicWebsiteOrigin;

  /// Maps the internal API slug to the public URL path segment used on the website.
  static String _urlPath(String apiSlug) {
    switch (apiSlug) {
      case 'bon-plans':
        return 'bons-plans';
      case 'events':
        return 'evenements';
      case 'trainings':
        return 'formations';
      case 'job-offers':
        return 'emplois';
      case 'demandes':
        return 'demandes';
      case 'posts':
        return 'posts';
      case 'reels':
        return 'reels';
      case 'profiles':
        return 'profil';
      default:
        return apiSlug;
    }
  }

  /// Builds the public share URL for an entity.
  /// Public preview page with explicit website and app links.
  static String buildUrl(String apiSlug, String entityId) =>
      '$_baseUrl/s/${_urlPath(apiSlug)}/${Uri.encodeComponent(entityId)}';

  /// Shares an entity using the native OS share sheet.
  /// [title] is used as the share subject and prepended to the link.
  static Future<void> shareEntity(
    String apiSlug,
    String entityId, {
    String? title,
    String? mediaUrl,
  }) async {
    final url = buildUrl(apiSlug, entityId);
    final text = title != null && title.isNotEmpty ? '$title\n\n$url' : url;

    if (mediaUrl != null && _isVideoUrl(mediaUrl)) {
      try {
        final response = await http.get(Uri.parse(mediaUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final directory = await getTemporaryDirectory();
          final extension = _videoExtension(mediaUrl);
          final file = File(
            '${directory.path}${Platform.pathSeparator}myreklam-$entityId.$extension',
          );
          await file.writeAsBytes(response.bodyBytes, flush: true);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: _videoMimeType(extension))],
            text: text,
            subject: title ?? 'MyReklam',
          );
          return;
        }
      } catch (_) {
        // If a network or target-app restriction blocks file sharing, the
        // public link below remains shareable everywhere.
      }
    }

    await Share.share(text, subject: title ?? 'MyReklam');
  }

  static bool _isVideoUrl(String url) {
    final clean = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return ['.mp4', '.mov', '.avi', '.webm', '.mkv'].any(clean.endsWith);
  }

  static String _videoExtension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    for (final extension in ['mp4', 'mov', 'avi', 'webm', 'mkv']) {
      if (path.endsWith('.$extension')) return extension;
    }
    return 'mp4';
  }

  static String _videoMimeType(String extension) => switch (extension) {
    'mov' => 'video/quicktime',
    'avi' => 'video/x-msvideo',
    'webm' => 'video/webm',
    'mkv' => 'video/x-matroska',
    _ => 'video/mp4',
  };
}
