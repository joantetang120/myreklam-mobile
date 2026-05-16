import 'package:myreklam/services/api_client.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final ApiClient _api = ApiClient();

  /// GET /api/referral/my-code
  Future<Map<String, dynamic>> getMyReferralCode() async {
    return await _api.authenticatedGet('/referral/my-code');
  }

  /// POST /api/referral/validate
  Future<Map<String, dynamic>> validateReferralCode({
    required String referralCode,
  }) async {
    return await _api.post('/referral/validate', body: {
      'parrainage_code': referralCode,
    });
  }
}
