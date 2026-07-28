class CommentSanitizer {
  const CommentSanitizer._();

  static dynamic entityCreatedAtFrom(Map<String, dynamic>? entity) {
    if (entity == null) return null;
    final nested = entity['data'];
    return entity['created_at'] ??
        entity['createdAt'] ??
        entity['published_at'] ??
        entity['publishedAt'] ??
        entity['date_creation'] ??
        entity['created_date'] ??
        entity['publication_date'] ??
        (nested is Map
            ? entityCreatedAtFrom(Map<String, dynamic>.from(nested))
            : null);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value < 100000000000 ? value * 1000 : value,
        isUtc: true,
      );
    }
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  static List<Map<String, dynamic>> forEntity(
    Iterable<Map<String, dynamic>> comments, {
    required String entityId,
    dynamic entityCreatedAt,
  }) {
    final createdAt = _parseDate(entityCreatedAt);
    final seenIds = <String>{};

    return comments.where((comment) {
      final commentEntityId = comment['commentable_id']?.toString();
      if (commentEntityId != null &&
          commentEntityId.isNotEmpty &&
          commentEntityId != entityId) {
        return false;
      }

      if (createdAt != null) {
        final commentCreatedAt = _parseDate(
          comment['created_at'] ??
              comment['createdAt'] ??
              comment['date_creation'],
        );
        if (commentCreatedAt != null && commentCreatedAt.isBefore(createdAt)) {
          return false;
        }
      }

      final id = comment['id']?.toString();
      return id == null || id.isEmpty || seenIds.add(id);
    }).toList();
  }
}
