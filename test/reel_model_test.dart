import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/models/reel_model.dart';

void main() {
  test('converts a video post from the unified feed into a reel', () {
    final reel = ReelModel.fromFeedItem({
      'feed_type': 'post',
      'id': 42,
      'author': {'display_name': 'Marie', 'avatar_url': null},
      'resource': {
        'id': 42,
        'content': 'Mon Reel',
        'likes_count': 3,
        'comments_count': 2,
        'user_reaction': 'like',
        'media': [
          {'file_type': 'video', 'url': 'https://example.test/reel.mp4'},
        ],
      },
    });

    expect(reel, isNotNull);
    expect(reel!.id, '42');
    expect(reel.videoUrl, 'https://example.test/reel.mp4');
    expect(reel.authorName, 'Marie');
    expect(reel.likesCount, 3);
    expect(reel.commentsCount, 2);
    expect(reel.isLiked, isTrue);
  });

  test('ignores image-only posts', () {
    final reel = ReelModel.fromFeedItem({
      'feed_type': 'post',
      'resource': {
        'id': 1,
        'media': [
          {'file_type': 'image', 'url': 'https://example.test/photo.jpg'},
        ],
      },
    });

    expect(reel, isNull);
  });
}
