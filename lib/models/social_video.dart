class SocialVideo {
  final String provider;
  final String url;
  final String? thumbnail;
  const SocialVideo(this.provider, this.url, {this.thumbnail});

  static SocialVideo? fromText(String text) {
    for (final match in RegExp(
      r'https://[^\s<]+',
      caseSensitive: false,
    ).allMatches(text)) {
      final video = parse(
        match.group(0)!.replaceFirst(RegExp(r'''[),.!?;:'"\]}]+$'''), ''),
      );
      if (video != null) return video;
    }
    return null;
  }

  static SocialVideo? parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort)
      return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    String? id;
    if (host == 'youtu.be' && uri.pathSegments.length == 1)
      id = uri.pathSegments.first;
    if ([
      'youtube.com',
      'm.youtube.com',
      'youtube-nocookie.com',
    ].contains(host)) {
      if (uri.path == '/watch') id = uri.queryParameters['v'];
      if (uri.pathSegments.length == 2 &&
          ['shorts', 'embed', 'live'].contains(uri.pathSegments.first))
        id = uri.pathSegments[1];
    }
    if (id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
      return SocialVideo(
        'YouTube',
        'https://www.youtube.com/watch?v=$id',
        thumbnail: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      );
    }
    if (['instagram.com', 'm.instagram.com'].contains(host)) {
      final match = RegExp(
        r'^/(reel|reels|p|tv)/([\w-]+)/?$',
      ).firstMatch(uri.path);
      if (match != null)
        return SocialVideo(
          'Instagram',
          'https://www.instagram.com/${match[1] == 'reels' ? 'reel' : match[1]}/${match[2]}/',
        );
    }
    if ([
      'tiktok.com',
      'm.tiktok.com',
      'vm.tiktok.com',
      'vt.tiktok.com',
    ].contains(host)) {
      if (RegExp(r'^/@[^/]+/video/\d+/?$').hasMatch(uri.path) ||
          ['vm.tiktok.com', 'vt.tiktok.com'].contains(host) &&
              uri.pathSegments.isNotEmpty ||
          RegExp(r'^/t/\w+').hasMatch(uri.path))
        return SocialVideo('TikTok', uri.toString());
    }
    if ([
      'facebook.com',
      'm.facebook.com',
      'web.facebook.com',
      'fb.watch',
    ].contains(host)) {
      if (host == 'fb.watch' && uri.pathSegments.isNotEmpty ||
          RegExp(r'/(reel|videos|watch|share/(v|r))\b').hasMatch(uri.path) ||
          uri.queryParameters.containsKey('v'))
        return SocialVideo('Facebook', uri.toString());
    }
    return null;
  }
}
