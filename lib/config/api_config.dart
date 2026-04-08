import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================================
  // 🔧 CHANGE THIS URL TO POINT TO YOUR BACKEND SERVER
  // ============================================================
  static const String baseUrl = 'https://myreklam-admin.maisoft-group.com/api';
  // static const String baseUrl = 'https://api.myreklam.fr/api';
  // static const String baseUrl = 'http://192.168.10.169:8000/api';
  // Examples:
  //   Local Android emulator:  'http://10.0.2.2:8000/api'
  //   Local iOS simulator:     'http://localhost:8000/api'
  //   Local device (WiFi):     'http://192.168.1.XX:8000/api'
  //   Production:              'https://api.myreklam.com/api'
  // ============================================================

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Token expiry durations (matching backend)
  // Backend: access token = 2 hours, refresh token = 60 days
  static const Duration accessTokenExpiry = Duration(hours: 2);
  static const Duration refreshTokenExpiry = Duration(days: 60);

  // OTP expiry
  static const int otpExpirySeconds = 252; // 4 min 12 sec

  // Google OAuth (Web client ID from google-services.json oauth_client with client_type: 3)
  static const String googleClientId =
      '166441708619-tt4a3fg0ah3g5ol3mmt0f5a65hgif4f8.apps.googleusercontent.com';

  static String _apiHost() {
    final Uri uri = Uri.parse(baseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }

  /// Resolves backend media/storage URLs (which may be relative) into
  /// fully-qualified URLs reachable by the client.
  static String? resolveMediaUrl(String? path) {
    debugPrint('resolveMediaUrl input: $path');
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http') || trimmed.startsWith('https'))
      return trimmed;

    final host = _apiHost();
    debugPrint('host: $host, trimmed: $trimmed');
    if (trimmed.startsWith('/')) {
      return '$host$trimmed';
    }
    if (trimmed.startsWith('storage/')) {
      return '$host/$trimmed';
    }
    // Handle candidate-documents paths
    if (trimmed.startsWith('candidate-documents/')) {
      final result = '$host/storage/$trimmed';
      debugPrint('candidate-documents result: $result');
      return result;
    }
    // Handle avatar paths and other storage paths without storage/ prefix
    if (trimmed.startsWith('avatars/')) {
      final result = '$host/storage/$trimmed';
      debugPrint('avatars result: $result');
      return result;
    }
    debugPrint('fallback return: $trimmed');
    return trimmed;
  }
}
