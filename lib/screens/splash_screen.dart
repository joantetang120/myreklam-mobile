import 'package:flutter/material.dart';
import '../widgets/dot_loader.dart';
import 'onboarding_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/auth_navigator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = await _authService.restoreSessionFromStorage();
      if (!mounted) return;

      if (user != null) {
        AuthNavigator.navigateAfterAuth(context, user);
        return;
      }
    } on ApiException catch (_) {
      await TokenStorage.clearTokens();
    } catch (_) {
      await TokenStorage.clearTokens();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Image.asset(
              'assets/images/splash.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(child: DotLoader(size: 40)),
            ),
          ),
        ],
      ),
    );
  }
}
