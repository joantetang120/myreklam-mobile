import 'package:myreklam/services/api_client.dart';

class SpaceDashboardData {
  SpaceDashboardData(this.profileResponse, this.responses);
  final Map<String, dynamic> profileResponse;
  final Map<String, Map<String, dynamic>?> responses;
  static const verticals = [
    'bonplans',
    'job-offers',
    'trainings',
    'events',
    'demandes',
  ];

  static int? listTotal(Map<String, dynamic>? response) {
    if (response == null) return null;
    final data = response['data'];
    final meta = response['meta'];
    final rawTotal = data is Map
        ? data['total'] ?? (meta is Map ? meta['total'] : null)
        : (meta is Map ? meta['total'] : response['total']);
    final total = rawTotal is num
        ? rawTotal.toInt()
        : int.tryParse('$rawTotal');
    if (total != null && total >= 0) return total;
    final rows = data is List
        ? data
        : data is Map
        ? data['data']
        : null;
    final lastPage = data is Map
        ? data['last_page']
        : meta is Map
        ? meta['last_page']
        : null;
    if (lastPage != null && (int.tryParse('$lastPage') ?? 2) > 1) return null;
    return rows is List ? rows.length : null;
  }

  int? totalAcross(bool favourites) {
    var sum = 0;
    for (final vertical in verticals) {
      final total = listTotal(
        responses['/$vertical${favourites ? '/my-favorites' : ''}'],
      );
      if (total == null) return null;
      sum += total;
    }
    return sum;
  }

  Map get user => profileResponse['user'] as Map? ?? {};
  Map get profile => profileResponse['profile'] as Map? ?? {};
  bool get isPro => user['account_type'] == 'pro';
  int? get searches => listTotal(responses['/saved-searches']);
  num? get balance {
    final raw = responses['/mys/history']?['current_balance'] ?? user['mys'];
    return raw is num ? raw : num.tryParse('$raw');
  }

  int? get referred {
    final stats = responses['/referral/stats']?['stats'];
    final value = stats is Map ? stats['total_referred'] : null;
    return value is num ? value.toInt() : int.tryParse('$value');
  }

  List<bool?> get completion => [
    user['is_email_verified'] == true || user['is_email_verified'] == 1,
    '${profile['avatar_url'] ?? ''}'.trim().isNotEmpty,
    '${profile['phone'] ?? profile['telephone'] ?? ''}'.trim().isNotEmpty,
    '${profile['bio'] ?? profile['presentation'] ?? ''}'.trim().isNotEmpty,
    totalAcross(false) == null ? null : totalAcross(false)! > 0,
    searches == null ? null : searches! > 0,
  ];
}

class SpaceDashboardService {
  SpaceDashboardService({Future<Map<String, dynamic>> Function(String)? get})
    : _get = get ?? ((path) => ApiClient().authenticatedGet(path));
  final Future<Map<String, dynamic>> Function(String) _get;

  Future<SpaceDashboardData> load() async {
    final profile = await _get('/profile/me');
    if (profile['user'] is! Map || profile['success'] == false) {
      throw StateError('Profile unavailable');
    }
    final paths = [
      for (final vertical in SpaceDashboardData.verticals) ...[
        '/$vertical',
        '/$vertical/my-favorites',
      ],
      '/saved-searches',
      '/mys/history',
      '/referral/stats',
      if (profile['user']['account_type'] == 'pro') ...[
        '/subscriptions/current',
        '/delegations',
        '/delegations/received',
      ],
    ];
    final responses = <String, Map<String, dynamic>?>{};
    await Future.wait(
      paths.map((path) async {
        try {
          final result = await _get(path);
          responses[path] = result['success'] == false ? null : result;
        } catch (_) {
          responses[path] = null;
        }
      }),
    );
    return SpaceDashboardData(profile, responses);
  }
}
