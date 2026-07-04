import 'dart:io';
import 'package:myreklam/services/api_client.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ApiClient _api = ApiClient();

  /// PUT /api/profile/particulier
  Future<Map<String, dynamic>> completeParticulierProfile({
    required String pseudo,
    required String phone,
  }) async {
    return await _api.authenticatedPut(
      '/profile/particulier',
      body: {'pseudo': pseudo, 'phone': phone},
    );
  }

  /// PUT /api/profile/pro/step1
  Future<Map<String, dynamic>> completeProStep1({
    required String companyName,
    required String siret,
    required String address,
    String? secteurActivite,
    String? telephone,
    String? codePostal,
    String? ville,
  }) async {
    final body = <String, dynamic>{
      'company_name': companyName,
      'siret': siret,
      'address': address,
    };
    if (secteurActivite != null && secteurActivite.isNotEmpty) {
      body['secteur_activite'] = secteurActivite;
    }
    if (telephone != null && telephone.isNotEmpty) {
      body['telephone'] = telephone;
    }
    if (codePostal != null && codePostal.isNotEmpty) {
      body['code_postal'] = codePostal;
    }
    if (ville != null && ville.isNotEmpty) {
      body['ville'] = ville;
    }
    
    // Debug: Log the request body
    print('📤 PUT /profile/pro/step1 body: $body');
    
    final response = await _api.authenticatedPut('/profile/pro/step1', body: body);
    
    // Debug: Log the response
    print('📥 PUT /profile/pro/step1 response keys: ${response.keys}');
    if (response['profile'] != null) {
      print('📥 Profile fields returned: ${response['profile'].keys}');
      print('📥 secteur_activite: ${response['profile']['secteur_activite']}');
      print('📥 code_postal: ${response['profile']['code_postal']}');
      print('📥 ville: ${response['profile']['ville']}');
    }
    
    return response;
  }

  /// PUT /api/profile/pro/step2
  Future<Map<String, dynamic>> completeProStep2({
    required String firstName,
    required String lastName,
    required String contactEmail,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'contact_email': contactEmail,
    };
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    return await _api.authenticatedPut('/profile/pro/step2', body: body);
  }

  /// GET /api/profile/me
  Future<Map<String, dynamic>> getProfile() async {
    return await _api.authenticatedGet('/profile/me');
  }

  /// GET /api/profile/{userId}
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _api.authenticatedGet('/profile/$userId');
  }

  /// POST /api/profile/{userId}/follow
  Future<Map<String, dynamic>> followUser(String userId) async {
    return await _api.authenticatedPost('/profile/$userId/follow');
  }

  /// DELETE /api/profile/{userId}/unfollow
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    return await _api.authenticatedDelete('/profile/$userId/unfollow');
  }

  /// POST /api/profile/{userId}/report
  Future<Map<String, dynamic>> reportUser(String userId, String reason) async {
    return await _api.authenticatedPost(
      '/profile/$userId/report',
      body: {'reason': reason.trim()},
    );
  }

  /// PUT /api/profile/me
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> fields,
  ) async {
    return await _api.authenticatedPut('/profile/me', body: fields);
  }

  /// POST /api/profile/avatar
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    return await _api.authenticatedMultipart(
      '/profile/avatar',
      file: imageFile,
      fileField: 'image',
    );
  }

  /// POST /api/profile/me/banner
  Future<Map<String, dynamic>> uploadBanner(File imageFile) async {
    return await _api.authenticatedMultipart(
      '/profile/me/banner',
      file: imageFile,
      fileField: 'image',
    );
  }

  /// POST /api/profile/me/gallery - Upload single image
  Future<Map<String, dynamic>> uploadGalleryImage(File imageFile) async {
    return await _api.authenticatedMultipart(
      '/profile/me/gallery',
      file: imageFile,
      fileField: 'image',
    );
  }

  /// POST /api/profile/me/gallery - Upload multiple images
  Future<Map<String, dynamic>> uploadGalleryImages(
    List<File> imageFiles,
  ) async {
    return await _api.authenticatedMultipartMultiple(
      '/profile/me/gallery',
      files: imageFiles,
      fileField: 'images',
    );
  }

  /// POST /api/profile/me/gallery - Upload single video
  Future<Map<String, dynamic>> uploadGalleryVideo(File videoFile) async {
    return await _api.authenticatedMultipart(
      '/profile/me/gallery',
      file: videoFile,
      fileField: 'video',
    );
  }

  /// DELETE /api/profile/me/gallery/{index}
  Future<Map<String, dynamic>> deleteGalleryImage(int index) async {
    return await _api.authenticatedDelete('/profile/me/gallery/$index');
  }

  /// GET /api/profile/{userId}/followers
  Future<List<dynamic>> getFollowers(String userId) async {
    final response = await _api.authenticatedGet('/profile/$userId/followers');
    return response['data'] ?? [];
  }

  /// GET /api/profile/{userId}/following
  Future<List<dynamic>> getFollowing(String userId) async {
    final response = await _api.authenticatedGet('/profile/$userId/following');
    return response['data'] ?? [];
  }

  Future<List<dynamic>> getSuggestions({String? query}) async {
    String url = '/profile/suggestions';
    if (query != null && query.isNotEmpty) {
      url += '?query=${Uri.encodeComponent(query)}';
    }
    final response = await _api.authenticatedGet(url);
    return response['data'] ?? [];
  }

  /// GET /api/profile/pseudo/check?pseudo=xxx
  Future<Map<String, dynamic>> checkPseudo(String pseudo) async {
    final encodedPseudo = Uri.encodeComponent(pseudo);
    return await _api.authenticatedGet(
      '/profile/pseudo/check?pseudo=$encodedPseudo',
    );
  }


  /// GET /api/profile/pseudo/suggestions?pseudo=xxx
  Future<List<String>> getPseudoSuggestions(String pseudo) async {
    final encodedPseudo = Uri.encodeComponent(pseudo);
    final response = await _api.authenticatedGet(
      '/profile/pseudo/suggestions?pseudo=$encodedPseudo',
    );
    return (response['suggestions'] as List?)
            ?.map((s) => s.toString())
            .toList() ??
        [];
  }

  /// GET /api/profile/me/pseudo-limit
  Future<Map<String, dynamic>> getPseudoChangeLimit() async {
    return await _api.authenticatedGet('/profile/me/pseudo-limit');
  }
}
