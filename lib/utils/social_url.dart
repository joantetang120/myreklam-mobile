String normalizeSocialUrl(String key, String input) {
  final value = input.trim();
  if (value.isEmpty) return '';
  const bases = {
    'facebook': 'https://www.facebook.com/',
    'instagram': 'https://www.instagram.com/',
    'linkedin': 'https://www.linkedin.com/in/',
    'youtube': 'https://www.youtube.com/@',
    'snapchat': 'https://www.snapchat.com/add/',
    'x': 'https://x.com/',
    'tiktok': 'https://www.tiktok.com/@',
    'dribbble': 'https://dribbble.com/',
  };
  if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(value) &&
      !RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
    throw const FormatException('Utilisez un lien http ou https.');
  }
  final full = RegExp(r'^https?://', caseSensitive: false).hasMatch(value);
  final domain =
      key == 'website' ||
      RegExp(
        r'^(www\.|[a-z0-9.-]+\.(com|fr|net|org)/)',
        caseSensitive: false,
      ).hasMatch(value);
  final candidate = full
      ? value
      : domain
      ? 'https://$value'
      : '${bases[key] ?? 'https://'}${value.replaceFirst(RegExp(r'^@'), '')}';
  final uri = Uri.tryParse(candidate);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException('Lien de réseau social invalide.');
  }
  return uri.toString();
}
