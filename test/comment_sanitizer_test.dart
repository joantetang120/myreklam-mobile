import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/comment_sanitizer.dart';

void main() {
  test('removes orphan comments older than the current entity', () {
    final comments = [
      {
        'id': 1,
        'commentable_id': '42',
        'body': 'Ancien commentaire',
        'created_at': '2025-01-01T10:00:00Z',
      },
      {
        'id': 2,
        'commentable_id': '42',
        'body': 'Commentaire actuel',
        'created_at': '2026-07-20T10:00:00Z',
      },
    ];

    final result = CommentSanitizer.forEntity(
      comments,
      entityId: '42',
      entityCreatedAt: '2026-07-01T10:00:00Z',
    );

    expect(result.map((comment) => comment['id']), [2]);
  });

  test('removes comments belonging to another entity and duplicate ids', () {
    final comments = [
      {'id': 1, 'commentable_id': '99'},
      {'id': 2, 'commentable_id': '42'},
      {'id': 2, 'commentable_id': '42'},
    ];

    final result = CommentSanitizer.forEntity(comments, entityId: '42');

    expect(result.map((comment) => comment['id']), [2]);
  });

  test('supports nested entity data and camelCase API dates', () {
    final entityDate = CommentSanitizer.entityCreatedAtFrom({
      'data': {'createdAt': '2026-07-10 10:00:00'},
    });
    final result = CommentSanitizer.forEntity(
      [
        {'id': 1, 'createdAt': '2026-05-01 10:00:00'},
        {'id': 2, 'createdAt': '2026-07-11 10:00:00'},
      ],
      entityId: '42',
      entityCreatedAt: entityDate,
    );

    expect(result.map((comment) => comment['id']), [2]);
  });
}
