import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/public_document_filter.dart';

void main() {
  group('filterPublicProfileDocuments', () {
    test('keeps only visible documents owned by the displayed profile', () {
      final result = filterPublicProfileDocuments([
        {
          'id': 1,
          'user_id': 42,
          'is_visible': true,
          'file_path': 'candidate-documents/cv.pdf',
        },
        {
          'id': 2,
          'user_id': 99,
          'is_visible': true,
          'file_path': 'candidate-documents/ghost.pdf',
        },
        {
          'id': 3,
          'user_id': 42,
          'is_visible': false,
          'file_path': 'candidate-documents/private.pdf',
        },
      ], profileUserId: '42');

      expect(result.map((document) => document['id']), [1]);
    });

    test('fails closed when the API omits the document owner', () {
      final result = filterPublicProfileDocuments([
        {
          'id': 1,
          'is_visible': true,
          'file_path': 'candidate-documents/unowned.pdf',
        },
      ], profileUserId: '42');

      expect(result, isEmpty);
    });

    test(
      'rejects stale rows without a file and accepts API boolean variants',
      () {
        final result = filterPublicProfileDocuments([
          {'id': 1, 'user_id': '42', 'is_visible': 1, 'file_path': ''},
          {
            'id': 2,
            'user': {'id': '42'},
            'is_visible': '1',
            'file_url': 'https://example.test/cv.pdf',
          },
        ], profileUserId: '42');

        expect(result.map((document) => document['id']), [2]);
      },
    );

    test('removes duplicate rows', () {
      final document = {
        'id': 7,
        'owner_id': 42,
        'is_visible': true,
        'file_path': 'candidate-documents/cv.pdf',
      };

      final result = filterPublicProfileDocuments([
        document,
        Map<String, dynamic>.from(document),
      ], profileUserId: '42');

      expect(result, hasLength(1));
    });
  });
}
