import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/push_notification_service.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/message_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    required String ageBand,
    required bool termsAccepted,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'age_band': ageBand,
      'terms_accepted': termsAccepted,
      'terms_version': '2026-10-10',
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
    final response = await _api.post(
      '/referral/validate',
      body: {'parrainage_code': parrainageCode},
    );
    return response;
  }

  /// POST /api/auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
      await _registerPushToken();
    }

    return response;
  }

  /// POST /api/auth/logout
  Future<Map<String, dynamic>> logout() async {
    // Unregister the device's FCM token first, while the auth token is still
    // valid, so this device stops receiving this user's push notifications.
    try {
      await PushNotificationService.instance.unregisterToken();
      final response = await _api.authenticatedPost('/auth/logout');
      return response;
    } finally {
      await clearLocalAccountData();
    }
  }

  static Future<void> clearLocalAccountData() async {
    bool failed = false;
    Future<void> attempt(Future<void> Function() cleanup) async {
      try {
        await cleanup();
      } catch (_) {
        failed = true;
      }
    }

    try {
      await attempt(TokenStorage.clearTokens);
      await attempt(PushNotificationService.instance.clearLocalNotifications);
      await attempt(ReactionCacheService.clearCurrentUserCache);
      await attempt(MessageDatabase.instance.clearAllMessages);
      await attempt(() async {
        final temporaryDirectory = await getTemporaryDirectory();
        for (final name in [
          'myreklam_private_documents',
          'myreklam_ai_imports',
        ]) {
          final directory = Directory('${temporaryDirectory.path}/$name');
          if (await directory.exists()) {
            await for (final file in directory.list(followLinks: false)) {
              if (file is File) await attempt(file.delete);
            }
          }
        }
      });
      await attempt(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      });
    } finally {
      UserSession().clear();
    }
    if (failed) {
      throw StateError(
        'Certaines données locales n’ont pas pu être effacées. Fermez puis relancez l’application avant d’utiliser un autre compte.',
      );
    }
  }

  /// POST /api/auth/otp/send
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String purpose,
  }) async {
    return await _api.post(
      '/auth/otp/send',
      body: {'email': email, 'purpose': purpose},
    );
  }

  /// POST /api/auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final response = await _api.post(
      '/auth/otp/verify',
      body: {'email': email, 'code': code, 'purpose': purpose},
    );

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
      await _registerPushToken();
    }

    return response;
  }

  /// POST /api/auth/otp/resend
  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String purpose,
  }) async {
    return await _api.post(
      '/auth/otp/resend',
      body: {'email': email, 'purpose': purpose},
    );
  }

  /// POST /api/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return await _api.post('/auth/forgot-password', body: {'email': email});
  }

  /// POST /api/auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    return await _api.post(
      '/auth/reset-password',
      body: {'email': email, 'otp_code': otpCode, 'new_password': newPassword},
    );
  }

  /// POST /api/auth/social/google
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    String? email,
    String? ageBand,
    Future<String?> Function()? confirmNewAccountAge,
    Future<bool> Function()? confirmNewAccountTerms,
  }) async {
    final body = <String, dynamic>{'provider': provider, 'token': token};
    if (email != null) body['email'] = email;
    if (ageBand != null) body['age_band'] = ageBand;

    late Map<String, dynamic> response;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        response = await _api.post('/auth/social/$provider', body: body);
        break;
      } on ApiException catch (error) {
        if (attempt == 2) rethrow;
        if (error.code == 'AGE_CONFIRMATION_REQUIRED' &&
            confirmNewAccountAge != null) {
          final age = await confirmNewAccountAge();
          if (age == null) rethrow;
          body['age_band'] = age;
        } else if (error.code == 'TERMS_ACCEPTANCE_REQUIRED' &&
            confirmNewAccountTerms != null) {
          if (!await confirmNewAccountTerms()) rethrow;
          body['terms_accepted'] = true;
          body['terms_version'] = '2026-10-10';
        } else {
          rethrow;
        }
      }
    }

    if (response['token'] != null) {
      await TokenStorage.saveTokens(
        accessToken: response['token'],
        refreshToken: response['refresh_token'] ?? '',
      );
    }

    if (response['user'] != null) {
      _updateSessionFromUser(response['user']);
      await _registerPushToken();
    }

    return response;
  }

  /// PUT /api/auth/account-type
  Future<Map<String, dynamic>> setAccountType({
    required String accountType,
  }) async {
    final response = await _api.authenticatedPut(
      '/auth/account-type',
      body: {'account_type': accountType},
    );

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
        user['subscription'] = Map<String, dynamic>.from(
          response['subscription'],
        );
      }

      _updateSessionFromUser(user);
      // Re-register the FCM token on cold start for an already-logged-in user.
      await _registerPushToken();
      return user;
    } on ApiException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Register this device's FCM token with the backend. Best-effort: never
  /// throws, so a push-registration failure can't break the auth flow.
  Future<void> _registerPushToken() async {
    try {
      await PushNotificationService.instance.registerToken();
    } catch (_) {
      // Ignored — registration is retried on next auth / token refresh.
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
