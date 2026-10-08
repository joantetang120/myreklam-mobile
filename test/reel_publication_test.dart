import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/reel_service.dart';

class RecordingApi implements ApiClient {
  Map<String, dynamic>? published;
  final List<String> deleted = [];
  int uploads = 0;
  bool failUpload = false;
  @override
  Future<Map<String, dynamic>> authenticatedPost(String endpoint, {Map<String, dynamic>? body, Duration? timeout}) async {
    expect(endpoint, '/posts');
    published = body;
    return {'data': {'id': 42}};
  }
  @override
  Future<Map<String, dynamic>> authenticatedMultipartMultiple(String endpoint, {required List<File> files, required String fileField, String method = 'POST', Map<String, String>? fields}) async {
    uploads++;
    if (failUpload) throw StateError('Upload failed');
    return {};
  }
  @override
  Future<Map<String, dynamic>> authenticatedDelete(String endpoint, {Map<String, dynamic>? body}) async {
    deleted.add(endpoint);
    return {};
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a video link is published in content without uploading media', () async {
    final api = RecordingApi();
    final id = await ReelService(api: api).publish(caption: 'Ma vidéo', videoLink: 'https://youtu.be/FODbuCKSKNU', visibility: 'friends');
    expect(id, '42');
    expect(api.published, {'content': 'Ma vidéo\n\nhttps://www.youtube.com/watch?v=FODbuCKSKNU', 'visibility': 'friends'});
    expect(api.uploads, 0);
  });
  test('unsupported or conflicting sources do not create a post', () async {
    final api = RecordingApi();
    final service = ReelService(api: api);
    await expectLater(service.publish(caption: '', videoLink: 'https://example.com'), throwsArgumentError);
    await expectLater(service.publish(caption: '', video: File('video.mp4'), videoLink: 'https://youtu.be/FODbuCKSKNU'), throwsArgumentError);
    expect(api.published, isNull);
  });
  test('file videos keep media upload and clean up failed publication', () async {
    final api = RecordingApi()..failUpload = true;
    await expectLater(ReelService(api: api).publish(caption: 'Vidéo', video: File('video.mp4')), throwsStateError);
    expect(api.uploads, 1);
    expect(api.deleted, ['/posts/42']);
  });
}
