import 'api_client.dart';

/// Authenticated privacy operations. The backend owns consent proofs and policy.
class PrivacyService {
  final ApiClient _api = ApiClient();
  Future<Map<String, dynamic>> preferences() =>
      _api.authenticatedGet('/privacy/preferences');
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) =>
      _api.authenticatedPut('/privacy/preferences', body: body);
  Future<Map<String, dynamic>> exportData() =>
      _api.authenticatedGet('/privacy/export');
  Future<Map<String, dynamic>> requestRights(Map<String, dynamic> body) =>
      _api.authenticatedPost('/privacy/requests', body: body);
  Future<Map<String, dynamic>> requests({int page = 1}) =>
      _api.authenticatedGet('/privacy/requests?page=$page');
  Future<Map<String, dynamic>> postMortem() =>
      _api.authenticatedGet('/privacy/post-mortem');
  Future<Map<String, dynamic>> updatePostMortem(Map<String, dynamic> body) =>
      _api.authenticatedPut('/privacy/post-mortem', body: body);
  Future<Map<String, dynamic>> revokePostMortem() =>
      _api.authenticatedDelete('/privacy/post-mortem');
}
