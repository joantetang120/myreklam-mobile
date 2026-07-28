import 'package:flutter/material.dart';
import 'package:myreklam/screens/onboarding_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/biometric_service.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/utils/auth_navigator.dart';
import 'package:myreklam/utils/user_session.dart';

/// Shown at launch when biometric unlock is enabled. Requires a fingerprint /
/// Face ID check before the (already-restored) session is entered.
class BiometricLockScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const BiometricLockScreen({super.key, required this.user});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String _label = 'la biométrie';
  IconData _icon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final desc = await BiometricService.instance.describe();
    if (mounted) {
      setState(() {
        _label = desc.label;
        _icon = desc.icon;
      });
    }
    _unlock();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    final ok = await BiometricService.instance.authenticate(
      reason: 'Déverrouillez Myreklam pour continuer',
    );

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (ok) {
      AuthNavigator.navigateAfterAuth(context, widget.user);
    }
  }

  /// Bail out to the login flow (used another account / can't unlock).
  Future<void> _useAnotherAccount() async {
    try {
      await AuthService().logout();
    } catch (_) {
      await TokenStorage.clearTokens();
      UserSession().clear();
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/splash.png',
                width: MediaQuery.of(context).size.width * 0.45,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7412A).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 48, color: const Color(0xFFE7412A)),
              ),
              const SizedBox(height: 24),
              Text(
                'Déverrouillez avec $_label',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirmez votre identité pour accéder à votre compte.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _authenticating ? null : _unlock,
                  icon: _authenticating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_icon, size: 20),
                  label: Text(
                    _authenticating ? 'Vérification…' : 'Déverrouiller',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7412A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _authenticating ? null : _useAnotherAccount,
                child: const Text(
                  'Utiliser un autre compte',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
