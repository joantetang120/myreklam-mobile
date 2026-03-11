import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => message;

  String get firstError {
    if (errors != null && errors!.isNotEmpty) {
      final firstField = errors!.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        return firstField.first.toString();
      }
    }
    return message;
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool auth = false,
  }) async {
    final token = auth ? await TokenStorage.getAccessToken() : null;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .get(url, headers: _headers(token: token))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre. Veuillez réessayer.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    } on http.ClientException {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final token = auth ? await TokenStorage.getAccessToken() : null;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .post(
            url,
            headers: _headers(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre. Veuillez réessayer.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    } on http.ClientException {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final token = auth ? await TokenStorage.getAccessToken() : null;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .put(
            url,
            headers: _headers(token: token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre. Veuillez réessayer.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    } on http.ClientException {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Une erreur est survenue.',
      errors: body['errors'] != null
          ? Map<String, dynamic>.from(body['errors'])
          : null,
    );
  }

  Future<Map<String, dynamic>> authenticatedGet(String endpoint) async {
    try {
      return await get(endpoint, auth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return await get(endpoint, auth: true);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> authenticatedPost(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await post(endpoint, body: body, auth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return await post(endpoint, body: body, auth: true);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> authenticatedPut(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await put(endpoint, body: body, auth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return await put(endpoint, body: body, auth: true);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool auth = false,
  }) async {
    final token = auth ? await TokenStorage.getAccessToken() : null;
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client
          .delete(url, headers: _headers(token: token))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre. Veuillez réessayer.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    } on http.ClientException {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  Future<Map<String, dynamic>> authenticatedDelete(String endpoint) async {
    try {
      return await delete(endpoint, auth: true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return await delete(endpoint, auth: true);
        }
      }
      rethrow;
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token');
      final response = await _client.post(
        url,
        headers: _headers(token: refreshToken),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        await TokenStorage.saveTokens(
          accessToken: body['token'],
          refreshToken: body['refresh_token'],
        );
        return true;
      }

      await TokenStorage.clearTokens();
      return false;
    } catch (_) {
      await TokenStorage.clearTokens();
      return false;
    }
  }
}
