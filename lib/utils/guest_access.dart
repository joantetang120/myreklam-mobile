import 'package:myreklam/theme/app_theme.dart';
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
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AdaptiveColors.foreground(context, Color(0xFF2E9B5B)),
            ),
            SizedBox(width: 10),
            Expanded(child: Text('Connexion requise')),
          ],
        ),
        content: Text(
          'Connectez-vous pour acceder a $featureName.',
          style: TextStyle(
            fontSize: 14,
            color: AdaptiveColors.foreground(context, Color(0xFF616161)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdaptiveColors.surface(
                context,
                const Color(0xFF2E9B5B),
              ),
              foregroundColor: AdaptiveColors.foreground(context, Colors.white),
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
