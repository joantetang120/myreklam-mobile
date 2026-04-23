import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';

class SavedSearchService {
  static final SavedSearchService _instance = SavedSearchService._internal();
  factory SavedSearchService() => _instance;
  SavedSearchService._internal();

  /// Get authentication headers with bearer token
  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all saved searches for current user with optional filters
  Future<List<Map<String, dynamic>>> getSavedSearches({
    String? date, // Filter by date (YYYY-MM-DD)
    String? sortBy, // Sort field: created_at, name, category, search_type
    String? order, // Sort order: asc, desc
  }) async {
    try {
      final headers = await _authHeaders();

      // Build query parameters
      final queryParams = <String, String>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
      if (order != null && order.isNotEmpty) queryParams['order'] = order;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/saved-searches',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as List;
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      debugPrint('Error fetching saved searches: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching saved searches: $e');
      return [];
    }
  }

  /// Save a new search
  Future<Map<String, dynamic>?> saveSearch({
    required String name,
    String? searchType,
    String? searchQuery,
    String? category,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
    String? locationCity,
    String? locationPostalCode,
    double? searchRadius,
    bool? searchAllFrance,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'name': name,
        if (searchType != null) 'search_type': searchType,
        if (searchQuery != null) 'search_query': searchQuery,
        if (category != null) 'category': category,
        if (locationAddress != null) 'location_address': locationAddress,
        if (locationLat != null) 'location_lat': locationLat,
        if (locationLng != null) 'location_lng': locationLng,
        if (locationCity != null) 'location_city': locationCity,
        if (locationPostalCode != null)
          'location_postal_code': locationPostalCode,
        if (searchRadius != null) 'search_radius': searchRadius,
        if (searchAllFrance != null) 'search_all_france': searchAllFrance,
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/saved-searches'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          debugPrint('Search saved successfully: $name');
          return responseData['data'] as Map<String, dynamic>;
        }
      }

      debugPrint(
        'Error saving search: ${response.statusCode} - ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('Error saving search: $e');
      return null;
    }
  }

  /// Delete a saved search
  Future<bool> deleteSearch(int searchId) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/saved-searches/$searchId'),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          debugPrint('Search deleted successfully: ID $searchId');
          return true;
        }
      }

      debugPrint('Error deleting search: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error deleting search: $e');
      return false;
    }
  }
}
