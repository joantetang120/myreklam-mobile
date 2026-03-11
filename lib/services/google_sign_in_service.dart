import 'package:google_sign_in/google_sign_in.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/auth_service.dart';

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  final _authService = AuthService();

  Future<Map<String, dynamic>> signIn() async {
    // Trigger Google sign-in flow
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      throw Exception('Connexion Google annulée.');
    }

    // Get auth tokens
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    final String? accessToken = auth.accessToken;

    final String token = idToken ?? accessToken ?? '';

    if (token.isEmpty) {
      throw Exception('Impossible de récupérer le token Google.');
    }

    // Send token to backend
    final response = await _authService.socialLogin(
      provider: 'google',
      token: token,
      email: account.email,
    );

    return response;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
