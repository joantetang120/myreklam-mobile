import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_data.dart';

class LocationService {
  static const String _baseUrl = 'https://api-adresse.data.gouv.fr/search';

  /// Search for addresses using the French government geo API
  /// Returns a list of location suggestions
  static Future<List<LocationSuggestion>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&limit=5&autocomplete=1');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGeoJsonResponse(data);
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Location search failed: $e');
    }
  }

  /// Parse the GeoJSON response from the French government API
  static List<LocationSuggestion> _parseGeoJsonResponse(Map<String, dynamic> data) {
    final features = data['features'] as List? ?? [];
    
    return features.map((feature) {
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List? ?? [0, 0];
      
      // GeoJSON coordinates are [longitude, latitude]
      final lng = coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0.0;
      final lat = coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0.0;

      return LocationSuggestion(
        label: properties['label']?.toString() ?? '',
        city: properties['city']?.toString(),
        postalCode: properties['postcode']?.toString(),
        latitude: lat,
        longitude: lng,
        context: properties['context']?.toString(),
        fullAddress: properties['name']?.toString() ?? properties['label']?.toString() ?? '',
      );
    }).where((s) => s.label.isNotEmpty).toList();
  }

  /// Reverse geocode - get address from coordinates
  static Future<LocationData?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse?lat=$lat&lon=$lng');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = _parseGeoJsonResponse(data);
        if (suggestions.isNotEmpty) {
          return suggestions.first.toLocationData();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
