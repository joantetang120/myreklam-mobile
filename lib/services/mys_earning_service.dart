import 'package:myreklam/services/api_client.dart';

class MysEarningService {
  static final MysEarningService _instance = MysEarningService._internal();
  factory MysEarningService() => _instance;
  MysEarningService._internal();

  final ApiClient _api = ApiClient();

  /// POST /api/mys/award
  /// Award My's to the current user for completing an action
  Future<Map<String, dynamic>> awardMys({
    required String actionType,
    String? referenceId,
  }) async {
    final body = <String, dynamic>{
      'action_type': actionType,
    };
    if (referenceId != null) {
      body['reference_id'] = referenceId;
    }

    final response = await _api.authenticatedPost('/mys/award', body: body);
    return response;
  }

  /// GET /api/mys/history
  /// Get user's My's earnings history
  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final response = await _api.authenticatedGet('/mys/history?page=$page');
    return response;
  }
}
