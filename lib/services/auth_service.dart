import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/utils/user_session.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _api = ApiClient();

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? parrainageCode,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (parrainageCode != null && parrainageCode.isNotEmpty) {
      body['parrainage_code'] = parrainageCode;
    }

    final response = await _api.post('/auth/register', body: body);
    return response;
  }

  /// POST /api/referral/validate
  Future<Map<String, dynamic>> validateParrainageCode({
    required String parrainageCode,
  }) async {
    final response = await _api.post('/referral/validate', body: {
      'parrainage_code': parrainageCode,
    });
    return response;
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
    }

    return response;
  }

  /// POST /api/auth/logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _api.authenticatedPost('/auth/logout');
      return response;
    } finally {
      await TokenStorage.clearTokens();
      UserSession().clear();
      // Note: We do NOT clear onboarding flags here
      // Onboarding modal should only show once for new users
    }
  }

  /// POST /api/auth/otp/send
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String purpose,
  }) async {
    return await _api.post('/auth/otp/send', body: {
      'email': email,
      'purpose': purpose,
    });
  }

  /// POST /api/auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final response = await _api.post('/auth/otp/verify', body: {
      'email': email,
      'code': code,
      'purpose': purpose,
    });

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
    }

    return response;
  }

  /// POST /api/auth/otp/resend
  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String purpose,
  }) async {
    return await _api.post('/auth/otp/resend', body: {
      'email': email,
      'purpose': purpose,
    });
  }

  /// POST /api/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await _api.post('/auth/forgot-password', body: {
      'email': email,
    });
  }

  /// POST /api/auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    return await _api.post('/auth/reset-password', body: {
      'email': email,
      'otp_code': otpCode,
      'new_password': newPassword,
    });
  }

  /// POST /api/auth/social/google
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'provider': provider,
      'token': token,
    };
    if (email != null) body['email'] = email;

    final response = await _api.post('/auth/social/$provider', body: body);

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
    }

    return response;
  }

  /// PUT /api/auth/account-type
  Future<Map<String, dynamic>> setAccountType({
    required String accountType,
  }) async {
    final response = await _api.authenticatedPut('/auth/account-type', body: {
      'account_type': accountType,
    });

    UserSession().setUserType(accountType);
    return response;
  }

  /// GET /api/profile/me - used for session restoration
  Future<Map<String, dynamic>?> restoreSessionFromStorage() async {
    final hasTokens = await TokenStorage.hasTokens();
    if (!hasTokens) return null;

    try {
      final response = await _api.authenticatedGet('/profile/me');
      if (response['user'] == null) return null;

      final user = Map<String, dynamic>.from(response['user']);
      if (response['subscription'] is Map) {
        user['subscription'] = Map<String, dynamic>.from(response['subscription']);
      }

      _updateSessionFromUser(user);
      return user;
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  void _updateSessionFromUser(Map<String, dynamic> user) {
    final accountType = user['account_type'];
    if (accountType != null) {
      UserSession().setUserType(accountType);
    }

    // subscription can be a Map or null from the API
    Map<String, dynamic>? subscription;
    if (user['subscription'] is Map) {
      subscription = Map<String, dynamic>.from(user['subscription']);
    }

    UserSession().updateFromApi(
      id: user['id']?.toString(),
      email: user['email'],
      accountType: user['account_type'],
      isEmailVerified: user['is_email_verified'],
      profileCompleted: user['profile_completed'],
      subscription: subscription,
      parrainageCode: user['parrainage_code'],
      mys: user['mys'],
    );
  }
}
