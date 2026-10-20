import 'dart:convert';
import 'dart:io';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/gallery_picker.dart';
import 'package:path_provider/path_provider.dart';

class AnnouncementAiResult {
  final Map<String, dynamic> fields;
  final List<Map<String, dynamic>> media;
  final List<String> warnings;
  final List<String> missingFields;
  AnnouncementAiResult({
    required this.fields,
    required this.media,
    required this.warnings,
    required this.missingFields,
  });
  factory AnnouncementAiResult.parse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map || data['fields'] is! Map)
      throw ApiException(
        statusCode: 422,
        message: 'Aucune information trouvée. Essayez une source plus lisible.',
      );
    final fields = Map<String, dynamic>.from(data['fields'])
      ..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    final media = (data['media'] is List ? data['media'] as List : [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    if (fields.isEmpty && media.isEmpty)
      throw ApiException(
        statusCode: 422,
        message: 'Aucune information trouvée. Essayez une source plus lisible.',
      );
    return AnnouncementAiResult(
      fields: fields,
      media: media,
      warnings: (data['warnings'] is List ? data['warnings'] as List : [])
          .whereType<String>()
          .toList(),
      missingFields:
          (data['missing_fields'] is List ? data['missing_fields'] as List : [])
              .whereType<String>()
              .toList(),
    );
  }
}

class AnnouncementAiService {
  static const kinds = ['bonplans', 'job-offers', 'events', 'trainings'];
  static const timeout = Duration(minutes: 2);
  Future<AnnouncementAiResult> extract({
    required String kind,
    String? url,
    GalleryMedia? image,
    Map<String, List<String>> categories = const {},
  }) async {
    if (!kinds.contains(kind))
      throw ArgumentError('Unsupported announcement type');
    if (image == null &&
        (url == null ||
            Uri.tryParse(url)?.scheme != 'https' ||
            (Uri.tryParse(url)?.host.isEmpty ?? true)))
      throw ApiException(
        statusCode: 422,
        message: 'Saisissez un lien HTTPS valide.',
      );
    final api = ApiClient();
    Map<String, dynamic> response;
    if (image != null) {
      if (await File(image.path).length() > 8 * 1024 * 1024)
        throw ApiException(
          statusCode: 422,
          message: 'Choisissez une image de moins de 8 Mo.',
        );
      final fields = <String, String>{};
      for (final e in categories.entries) {
        for (var i = 0; i < e.value.length; i++) {
          fields['categories[${e.key}][$i]'] = e.value[i];
        }
      }
      response = await api.authenticatedMultipart(
        '/$kind/ai-extract',
        file: File(image.path),
        fileField: 'image',
        fields: fields,
        timeout: timeout,
      );
    } else {
      response = await api.authenticatedPost(
        '/$kind/ai-extract',
        body: {'url': url, 'categories': categories},
        timeout: timeout,
      );
    }
    return AnnouncementAiResult.parse(response);
  }

  /// API sends downloaded image bytes, not an external URL to hotlink.
  Future<List<GalleryMedia>> materializeImages(
    List<Map<String, dynamic>> media, {
    Directory? destination,
  }) async {
    final images = <GalleryMedia>[];
    if (media.isEmpty) return images;
    final directory =
        destination ??
        Directory(
          '${(await getTemporaryDirectory()).path}/myreklam_ai_imports',
        );
    await directory.create(recursive: true);
    for (final row in media.take(3)) {
      final ext = {
        'image/jpeg': 'jpg',
        'image/png': 'png',
        'image/webp': 'webp',
      }[row['mime']];
      final encoded = row['base64'];
      if (ext == null ||
          encoded is! String ||
          encoded.length > 12 * 1024 * 1024)
        continue;
      try {
        final bytes = base64Decode(encoded);
        if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) continue;
        final name =
            'ai-${DateTime.now().microsecondsSinceEpoch}-${images.length}.$ext';
        final file = File('${directory.path}/$name');
        await file.writeAsBytes(bytes, flush: true);
        images.add(
          GalleryMedia(
            path: file.path,
            name: name,
            bytes: bytes,
            extension: ext,
            size: bytes.length,
          ),
        );
      } on FormatException {
        continue;
      }
    }
    return images;
  }
}
