import 'package:myreklam/services/api_client.dart';

class CandidateActivityResult {
  CandidateActivityResult(this.items, this.failedTypes);
  final List<Map<String, dynamic>> items;
  final List<String> failedTypes;
}

class CandidateActivityService {
  CandidateActivityService({Future<Map<String, dynamic>> Function(String)? get})
    : _get = get ?? ((path) => ApiClient().authenticatedGet(path));
  final Future<Map<String, dynamic>> Function(String) _get;

  Future<CandidateActivityResult> load() async {
    final items = <Map<String, dynamic>>[];
    final failures = <String>[];
    await Future.wait(
      {
        'emploi': '/job-offers/my-applications',
        'formation': '/trainings/my-subscriptions',
        'evenement': '/events/my-participations',
      }.entries.map((entry) async {
        final rows = <Map<String, dynamic>>[];
        try {
          var page = 1;
          var last = 1;
          do {
            final response = await _get(
              '${entry.value}?page=$page&per_page=50',
            );
            if (response['success'] == false)
              throw StateError('Failed activity');
            final payload = response['data'];
            final list = payload is List
                ? payload
                : payload is Map
                ? payload['data']
                : null;
            if (list is! List) throw StateError('Invalid activity');
            final meta = response['meta'];
            final rawLast = meta is Map
                ? meta['last_page']
                : payload is Map
                ? payload['last_page']
                : 1;
            last = int.tryParse('$rawLast') ?? 1;
            if (last > 100) throw StateError('Activity exceeds safety bound');
            for (final value in list) {
              final row = Map<String, dynamic>.from(value);
              if (entry.key == 'emploi') {
                final offer = row['job_offer'] is Map
                    ? row['job_offer'] as Map
                    : const {};
                final user = offer['user'] is Map
                    ? offer['user'] as Map
                    : const {};
                final pro = user['pro_profile'] is Map
                    ? user['pro_profile'] as Map
                    : const {};
                row['title'] = offer['title'] ?? 'Offre indisponible';
                row['owner'] = {
                  'id': user['id'],
                  'name':
                      pro['company_name'] ??
                      user['display_name'] ??
                      'Recruteur',
                };
              }
              row['type'] = entry.key;
              rows.add(row);
            }
            page++;
          } while (page <= last);
          items.addAll(rows);
        } catch (_) {
          failures.add(entry.key);
        }
      }),
    );
    String date(Map row) =>
        '${row['subscribed_at'] ?? row['participated_at'] ?? row['created_at'] ?? ''}';
    items.sort((a, b) => date(b).compareTo(date(a)));
    return CandidateActivityResult(items, failures);
  }
}
