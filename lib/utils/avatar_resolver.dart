class AvatarResolver {
  const AvatarResolver._();

  static const _avatarKeys = [
    'avatar_url',
    'avatar',
    'profile_picture',
    'photo_url',
    'logo_url',
    'company_logo',
  ];

  static const _nestedKeys = [
    'profile',
    'particulier_profile',
    'pro_profile',
    'user',
    'author',
    'owner',
    'data',
  ];

  /// Finds an avatar in the different user shapes returned by the API.
  static String? resolve(dynamic source, {int maxDepth = 4}) {
    return _resolve(source, depth: 0, maxDepth: maxDepth);
  }

  static String? _resolve(
    dynamic source, {
    required int depth,
    required int maxDepth,
  }) {
    if (source == null || depth > maxDepth) return null;
    if (source is String) return _normalize(source);
    if (source is! Map) return null;

    for (final key in _avatarKeys) {
      final avatar = _normalize(source[key]?.toString());
      if (avatar != null) return avatar;
    }

    for (final key in _nestedKeys) {
      final avatar = _resolve(
        source[key],
        depth: depth + 1,
        maxDepth: maxDepth,
      );
      if (avatar != null) return avatar;
    }

    return null;
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.toLowerCase() == 'null') return null;
    if (normalized == 'assets/images/dashboard_particulier/Ellipse 10.png') {
      return null;
    }
    return normalized;
  }
}
