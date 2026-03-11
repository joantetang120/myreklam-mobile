import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/config/api_config.dart';

class TrainingService {
  static final TrainingService _instance = TrainingService._internal();
  factory TrainingService() => _instance;
  TrainingService._internal();

  final ApiClient _api = ApiClient();

  /// Get training metadata (types, options, etc.)
  Future<Map<String, dynamic>> getMetadata() async {
    final response = await _api.authenticatedGet('/trainings/meta');
    // API returns {"status": "success", "data": {...}}
    if (response['data'] != null) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  /// Get categories from Categorie.php
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.post(
      Uri.parse('https://api.myreklam.fr/Categorie.php'),
      body: {
        'Method': 'getByType',
        'type': 'formations',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // API returns {"status": "success", "data": {"main": [...], "subs": {...}}}
      if (responseData is Map && responseData['data'] != null) {
        final data = responseData['data'];
        if (data is Map) {
          final mainCategories = List<Map<String, dynamic>>.from(data['main'] ?? []);
          final subsByParent = data['subs'] is Map ? Map<String, dynamic>.from(data['subs']) : <String, dynamic>{};

          return mainCategories.map((category) {
            final id = category['id'];
            final subListRaw = subsByParent[id?.toString()] ?? [];
            final subcategories = subListRaw is List
                ? subListRaw
                    .map<Map<String, dynamic>>(
                      (sub) => {
                        'id': sub['id'],
                        'code': sub['code'],
                        'label': sub['label'],
                        'name': sub['label'],
                      },
                    )
                    .toList()
                : <Map<String, dynamic>>[];

            return {
              'id': id,
              'code': category['code'],
              'label': category['label'],
              'name': category['label'],
              'subcategories': subcategories,
            };
          }).toList();
        }
      }
    }
    throw Exception('Failed to load categories');
  }

  /// Create a new training
  Future<Map<String, dynamic>> createTraining(Map<String, dynamic> data) async {
    return await _api.authenticatedPost('/trainings', body: data);
  }

  /// Update an existing training
  Future<Map<String, dynamic>> updateTraining(String id, Map<String, dynamic> data) async {
    return await _api.authenticatedPut('/trainings/$id', body: data);
  }

  /// Upload media files
  Future<Map<String, dynamic>> uploadMedia(String trainingId, List<File> files) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId/media');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('media[]', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to upload media: ${response.body}');
  }

  /// Upload document files
  Future<Map<String, dynamic>> uploadDocuments(String trainingId, List<File> files) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId/documents');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('documents[]', file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to upload documents: ${response.body}');
  }

  /// Delete media
  Future<void> deleteMedia(String trainingId, String mediaId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId/media/$mediaId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete media: ${response.body}');
    }
  }

  /// Delete document
  Future<void> deleteDocument(String trainingId, String documentId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId/documents/$documentId');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  /// Get user's trainings
  Future<Map<String, dynamic>> getTrainings({
    String? status,
    int? perPage,
    int? page,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (perPage != null) queryParams['per_page'] = perPage.toString();
    if (page != null) queryParams['page'] = page.toString();

    final uri = Uri.parse('/trainings').replace(queryParameters: queryParams);
    return await _api.authenticatedGet(uri.toString());
  }

  /// Get single training
  Future<Map<String, dynamic>> getTraining(String id) async {
    return await _api.authenticatedGet('/trainings/$id');
  }

  /// Delete training
  Future<void> deleteTraining(String id) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/trainings/$id');
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete training: ${response.body}');
    }
  }
}
