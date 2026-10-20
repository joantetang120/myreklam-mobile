import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/services/candidate_activity_service.dart';

void main() {
  test('loads all job pages with trainings and events', () async {
    final calls = <String>[];
    final result = await CandidateActivityService(
      get: (path) async {
        calls.add(path);
        if (path.startsWith('/job-offers')) {
          final second = path.contains('page=2&');
          return {
            'success': true,
            'data': [
              {
                'id': second ? 2 : 1,
                'job_offer_id': 'offer',
                'created_at': second ? '2026-10-20' : '2026-10-19',
                'job_offer': {
                  'title': 'Plombier',
                  'user': {
                    'id': 8,
                    'pro_profile': {'company_name': 'Entreprise'},
                  },
                },
              },
            ],
            'meta': {'last_page': 2},
          };
        }
        return {
          'success': true,
          'data': [
            {'id': 3, 'title': 'Autre'},
          ],
        };
      },
    ).load();
    expect(result.failedTypes, isEmpty);
    expect(result.items, hasLength(4));
    expect(result.items.first['type'], 'emploi');
    expect(result.items.first['id'], 2);
    expect(result.items.first['title'], 'Plombier');
    expect(result.items.first['owner']['name'], 'Entreprise');
    expect(calls.where((p) => p.startsWith('/job-offers')), hasLength(2));
    expect(
      result.items.map((row) => row['type']),
      containsAll(['emploi', 'formation', 'evenement']),
    );
  });

  test('reports a failed category without losing other results', () async {
    final result = await CandidateActivityService(
      get: (path) async {
        if (path.startsWith('/job-offers')) throw StateError('unavailable');
        return {
          'success': true,
          'data': [
            {'id': 1},
          ],
        };
      },
    ).load();
    expect(result.failedTypes, ['emploi']);
    expect(result.items, hasLength(2));
  });
}
