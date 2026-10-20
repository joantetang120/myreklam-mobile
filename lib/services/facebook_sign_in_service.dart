import 'package:myreklam/services/api_client.dart';

class FacebookSignInService {
  static final FacebookSignInService _instance =
      FacebookSignInService._internal();
  factory FacebookSignInService() => _instance;
  FacebookSignInService._internal();

  Future<Map<String, dynamic>> signIn({
    String? ageBand,
    Future<String?> Function()? confirmNewAccountAge,
  }) async {
    // No native SDK is loaded while verified Facebook authentication is disabled.
    throw ApiException(
      statusCode: 503,
      code: 'SOCIAL_PROVIDER_UNAVAILABLE',
      message:
          'Connexion Facebook indisponible. Utilisez votre adresse e-mail.',
    );
  }

  Future<void> signOut() async {}
}
