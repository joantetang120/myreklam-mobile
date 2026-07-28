import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/services/auth_state_manager.dart';
import 'package:myreklam/services/delegation_manager.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.statusCode, required this.message, this.errors});

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
  Future<bool>? _refreshInProgress;

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint, {bool auth = false}) async {
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
        message:
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
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
        message:
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
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
        message:
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      );
    } on http.ClientException {
      throw ApiException(
        statusCode: 0,
        message: 'Erreur de connexion. Veuillez réessayer.',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) =>
      parseApiResponse(response);

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

  Future<Map<String, dynamic>> authenticatedPostMultipart(
    String endpoint, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    return authenticatedMultipart(
      endpoint,
      file: file,
      fileField: fileField,
      fields: fields,
      method: 'POST',
    );
  }

  Future<Map<String, dynamic>> authenticatedMultipart(
    String endpoint, {
    required File file,
    required String fileField,
    String method = 'POST',
    Map<String, String>? fields,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest(method, url);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Single file - no array index
      final multipartFile = await http.MultipartFile.fromPath(
        fileField,
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final token = await TokenStorage.getAccessToken();
          final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
          final request = http.MultipartRequest(method, url);
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';
          if (fields != null) request.fields.addAll(fields);
          // Single file - no array index
          final multipartFile = await http.MultipartFile.fromPath(
            fileField,
            file.path,
          );
          request.files.add(multipartFile);
          final streamedResponse = await request.send().timeout(
            ApiConfig.connectTimeout,
          );
          final response = await http.Response.fromStream(streamedResponse);
          return _handleResponse(response);
        }
      }
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur.',
      );
    } on Exception {
      throw ApiException(statusCode: 0, message: 'Erreur inattendue.');
    }
  }

  Future<Map<String, dynamic>> authenticatedMultipartMultiple(
    String endpoint, {
    required List<File> files,
    required String fileField,
    String method = 'POST',
    Map<String, String>? fields,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest(method, url);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      for (var i = 0; i < files.length; i++) {
        final multipartFile = await http.MultipartFile.fromPath(
          '$fileField[$i]',
          files[i].path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final token = await TokenStorage.getAccessToken();
          final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
          final request = http.MultipartRequest(method, url);
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';
          if (fields != null) request.fields.addAll(fields);
          for (var i = 0; i < files.length; i++) {
            final multipartFile = await http.MultipartFile.fromPath(
              '$fileField[$i]',
              files[i].path,
            );
            request.files.add(multipartFile);
          }
          final streamedResponse = await request.send().timeout(
            ApiConfig.connectTimeout,
          );
          final response = await http.Response.fromStream(streamedResponse);
          return _handleResponse(response);
        }
      }
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        message: 'Le serveur met trop de temps à répondre.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de se connecter au serveur.',
      );
    } on Exception {
      throw ApiException(statusCode: 0, message: 'Erreur inattendue.');
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
        message:
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
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
    final pendingRefresh = _refreshInProgress;
    if (pendingRefresh != null) return pendingRefresh;

    final refresh = _performTokenRefresh();
    _refreshInProgress = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    }
  }

  Future<bool> _performTokenRefresh() async {
    try {
      // Delegated sessions are intentionally non-refreshable (so they can't be
      // escalated to full owner access). If the delegated token expired, end
      // the delegation and restore the manager's own session.
      if (await TokenStorage.isDelegated()) {
        await DelegationManager.instance.exitLocal();
        AuthStateManager().setSessionExpired();
        return false;
      }

      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        // No refresh token, session expired
        AuthStateManager().setSessionExpired();
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token');
      final response = await _client
          .post(url, headers: _headers(token: refreshToken))
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final body = parseApiResponse(response);
        final accessToken = body['token']?.toString();
        final newRefreshToken = body['refresh_token']?.toString();
        if (accessToken == null ||
            accessToken.isEmpty ||
            newRefreshToken == null ||
            newRefreshToken.isEmpty) {
          await TokenStorage.clearTokens();
          AuthStateManager().setSessionExpired();
          return false;
        }
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
        );
        return true;
      }

      // Refresh failed (expired or invalid), clear tokens and notify
      await TokenStorage.clearTokens();
      AuthStateManager().setSessionExpired();
      return false;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      await TokenStorage.clearTokens();
      AuthStateManager().setSessionExpired();
      return false;
    }
  }
}

Map<String, dynamic> parseApiResponse(http.Response response) {
  final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
  final rawBody = response.body.trim();

  if (rawBody.isEmpty) {
    if (isSuccess) return <String, dynamic>{};
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Une erreur est survenue.',
    );
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(rawBody);
  } on FormatException {
    if (isSuccess) return <String, dynamic>{'data': rawBody};
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Réponse invalide du serveur.',
    );
  }

  final body = decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{'data': decoded};
  if (isSuccess) return body;

  final rawErrors = body['errors'];
  throw ApiException(
    statusCode: response.statusCode,
    message: body['message']?.toString() ?? 'Une erreur est survenue.',
    errors: rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : null,
  );
}
