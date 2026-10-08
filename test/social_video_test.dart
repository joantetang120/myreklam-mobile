import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/models/social_video.dart';
import 'package:myreklam/models/reel_model.dart';

void main() {
  test('YouTube shorts and links in text are canonicalized', () {
    final video = SocialVideo.fromText(
      'Regarde https://youtu.be/FODbuCKSKNU?t=12.',
    );
    expect(video?.url, 'https://www.youtube.com/watch?v=FODbuCKSKNU');
    expect(video?.thumbnail, contains('FODbuCKSKNU'));
    expect(
      SocialVideo.parse('https://www.youtube.com/shorts/FODbuCKSKNU')?.provider,
      'YouTube',
    );
  });
  test('supports Instagram, TikTok full/short and Facebook share/watch', () {
    for (final url in [
      'https://www.instagram.com/reel/ABC_123/',
      'https://www.tiktok.com/@user/video/123456',
      'https://vm.tiktok.com/ABCD/',
      'https://www.facebook.com/share/r/abc/',
      'https://fb.watch/ABCD/',
    ]) {
      expect(SocialVideo.parse(url), isNotNull, reason: url);
    }
  });
  test(
    'rejects unrelated pages, spoofed domains and unsafe URL credentials',
    () {
      for (final url in [
        'http://youtube.com/watch?v=FODbuCKSKNU',
        'https://youtube.com.evil.test/watch?v=FODbuCKSKNU',
        'https://user:pass@youtube.com/watch?v=FODbuCKSKNU',
        'https://youtube.com:8443/watch?v=FODbuCKSKNU',
        'https://instagram.com/user/',
        'https://youtube.com/watch?v=invalid',
        'https://example.com/video.mp4',
      ]) {
        expect(SocialVideo.parse(url), isNull, reason: url);
      }
    },
  );
  test('link publications appear in the reels feed without uploaded media', () {
    final reel = ReelModel.fromFeedItem({
      'feed_type': 'post',
      'resource': {
        'id': 42,
        'content': 'Ma vidéo\nhttps://www.instagram.com/reel/ABC_123/',
      },
      'author': {'display_name': 'Alice'},
    });
    expect(reel?.id, '42');
    expect(reel?.videoUrl, 'https://www.instagram.com/reel/ABC_123/');
    expect(reel?.authorName, 'Alice');
    expect(
      ReelModel.fromFeedItem({
        'feed_type': 'post',
        'resource': {'id': 43, 'content': 'Texte uniquement'},
      }),
      isNull,
    );
  });
}
