/// Keeps only documents that are safe to expose on a public profile.
///
/// The API has historically returned documents belonging to another user when
/// filtering by `user_id`. Public profiles therefore fail closed: a document
/// must explicitly identify the requested owner, be visible and reference a
/// real file.
List<Map<String, dynamic>> filterPublicProfileDocuments(
  Iterable<Map<String, dynamic>> documents, {
  required String profileUserId,
}) {
  final expectedOwnerId = profileUserId.trim();
  if (expectedOwnerId.isEmpty) return const <Map<String, dynamic>>[];

  final seen = <String>{};
  final result = <Map<String, dynamic>>[];

  for (final document in documents) {
    if (!_isEnabled(document['is_visible'])) continue;
    if (_documentOwnerId(document) != expectedOwnerId) continue;

    final filePath = _firstNonEmpty(document, const [
      'file_path',
      'file_url',
      'download_url',
      'url',
      'path',
    ]);
    if (filePath == null) continue;

    final identity = document['id']?.toString().trim();
    final deduplicationKey = identity != null && identity.isNotEmpty
        ? 'id:$identity'
        : 'file:$filePath';
    if (!seen.add(deduplicationKey)) continue;

    result.add(document);
  }

  return result;
}

bool _isEnabled(dynamic value) {
  if (value == true || value == 1) return true;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String? _documentOwnerId(Map<String, dynamic> document) {
  final directOwner = _firstNonEmpty(document, const [
    'user_id',
    'owner_id',
    'profile_user_id',
  ]);
  if (directOwner != null) return directOwner;

  for (final key in const ['user', 'owner', 'candidate']) {
    final nested = document[key];
    if (nested is! Map) continue;
    final ownerId = _firstNonEmpty(Map<String, dynamic>.from(nested), const [
      'user_id',
      'id',
    ]);
    if (ownerId != null) return ownerId;
  }

  return null;
}

String? _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return null;
}
