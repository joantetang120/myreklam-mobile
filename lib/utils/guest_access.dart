import 'package:flutter/material.dart';
import 'package:myreklam/utils/user_session.dart';

class GuestAccess {
  static bool get isGuest => UserSession().isGuest;

  static bool ensureAuthenticated(
    BuildContext context, {
    String featureName = 'cette fonctionnalite',
  }) {
    if (!isGuest) return true;

    showLoginRequiredDialog(context, featureName: featureName);
    return false;
  }

  static void showLoginRequiredDialog(
    BuildContext context, {
    String featureName = 'cette fonctionnalite',
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF2E9B5B)),
            SizedBox(width: 10),
            Expanded(child: Text('Connexion requise')),
          ],
        ),
        content: Text(
          'Connectez-vous pour acceder a $featureName.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF616161)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9B5B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              UserSession().clear();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
