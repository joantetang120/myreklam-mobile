import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:myreklam/services/auth_service.dart';

class FacebookSignInService {
  static final FacebookSignInService _instance = FacebookSignInService._internal();
  factory FacebookSignInService() => _instance;
  FacebookSignInService._internal();

  final _authService = AuthService();

  Future<Map<String, dynamic>> signIn() async {
    // Trigger Facebook login dialog
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw Exception('Connexion Facebook annulée.');
    }

    if (result.status == LoginStatus.failed) {
      throw Exception(result.message ?? 'Erreur de connexion Facebook.');
    }

    final AccessToken? accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('Impossible de récupérer le token Facebook.');
    }

    // Get user email from Facebook
    final userData = await FacebookAuth.instance.getUserData(fields: 'email');
    final String? email = userData['email'];

    // Send token to backend
    final response = await _authService.socialLogin(
      provider: 'facebook',
      token: accessToken.tokenString,
      email: email,
    );

    return response;
  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }
}
