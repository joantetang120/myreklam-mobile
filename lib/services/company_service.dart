import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';

/// A company (pro account) returned by the search endpoint.
class CompanyResult {
  final int id;
  final String name;
  final String? avatar;

  CompanyResult({required this.id, required this.name, this.avatar});

  factory CompanyResult.fromJson(Map<String, dynamic> json) {
    return CompanyResult(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      avatar: ApiConfig.resolveMediaUrl(json['avatar']?.toString()),
    );
  }
}

class CompanyService {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  final ApiClient _api = ApiClient();

  /// Search existing companies (pro accounts) by name.
  Future<List<CompanyResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _api.authenticatedGet(
      '/companies/search?q=${Uri.encodeComponent(query.trim())}',
    );
    return (res['data'] as List? ?? [])
        .map((e) => CompanyResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Invite a company not yet on Myreklam (sends an email invitation).
  Future<void> invite({
    required String companyName,
    required String email,
  }) async {
    await _api.authenticatedPost(
      '/companies/invite',
      body: {'company_name': companyName, 'email': email},
    );
  }
}
