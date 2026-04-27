import 'package:share_plus/share_plus.dart';

/// Centralised share service for all entity types.
/// Uses myreklam.fr deep links so that mobile users are prompted to open the app.
class ShareService {
  static const String _baseUrl = 'https://myreklam.fr';

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
      default:
        return apiSlug;
    }
  }

  /// Builds the public deep-link URL for an entity.
  static String buildUrl(String apiSlug, String entityId) =>
      '$_baseUrl/${_urlPath(apiSlug)}/$entityId';

  /// Shares an entity using the native OS share sheet.
  /// [title] is used as the share subject and prepended to the link.
  static Future<void> shareEntity(
    String apiSlug,
    String entityId, {
    String? title,
  }) async {
    final url = buildUrl(apiSlug, entityId);
    final text = title != null && title.isNotEmpty ? '$title\n\n$url' : url;
    await Share.share(text, subject: title ?? 'MyReklam');
  }
}
