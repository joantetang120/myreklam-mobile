import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:myreklam/services/token_storage.dart';

/// Wraps [LocalAuthentication] + the persisted biometric preference.
///
/// Biometric unlock gates an already-persisted session: the user logs in once
/// with a password/OTP (tokens stored securely), enables biometric, and on
/// every subsequent app launch a fingerprint / Face ID check is required before
/// the session is restored. Disabling it (or logging out) removes the gate.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// True when the device has hardware + at least one enrolled biometric.
  Future<bool> isDeviceAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// A user-facing label + icon describing the available biometric.
  Future<({String label, IconData icon})> describe() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        return (
          label: Platform.isIOS ? 'Face ID' : 'la reconnaissance faciale',
          icon: Icons.face,
        );
      }
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong)) {
        return (label: 'l\'empreinte digitale', icon: Icons.fingerprint);
      }
    } catch (_) {}
    return (
      label: Platform.isIOS ? 'Face ID' : 'la biométrie',
      icon: Platform.isIOS ? Icons.face : Icons.fingerprint,
    );
  }

  /// Prompt the OS biometric dialog. Returns true only on success.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // Allow device passcode/PIN as a fallback to avoid lock-out.
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() => TokenStorage.isBiometricEnabled();

  /// Runs a biometric check and, on success, persists the preference.
  Future<bool> enable({required String email, required String reason}) async {
    final ok = await authenticate(reason: reason);
    if (ok) {
      await TokenStorage.setBiometricEnabled(true, email: email);
    }
    return ok;
  }

  Future<void> disable() => TokenStorage.setBiometricEnabled(false);

  /// After a fresh registration/login, offer to turn biometric unlock on.
  /// No-op when the device can't do biometrics or it's already enabled.
  Future<void> maybePromptEnroll(
    BuildContext context, {
    required String email,
  }) async {
    if (await isEnabled()) return;
    if (!await isDeviceAvailable()) return;
    if (!context.mounted) return;

    final desc = await describe();
    if (!context.mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(desc.icon, size: 40, color: const Color(0xFFE7412A)),
        title: const Text(
          'Connexion rapide',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Voulez-vous utiliser ${desc.label} pour vous connecter plus '
          'rapidement et sécuriser l\'accès à votre compte ?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Plus tard',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE7412A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await enable(
        email: email,
        reason: 'Confirmez pour activer la connexion biométrique',
      );
    }
  }
}
