import 'package:flutter/material.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/screens/splash_screen.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/services/delegation_service.dart';

/// Persistent banner shown while a manager is acting as a managed account.
/// "Quitter" disconnects (server + local) and returns to the manager's session.
class DelegationBanner extends StatefulWidget {
  const DelegationBanner({super.key});

  @override
  State<DelegationBanner> createState() => _DelegationBannerState();
}

class _DelegationBannerState extends State<DelegationBanner> {
  bool _exiting = false;

  Future<void> _exit() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await DelegationService().disconnect();
    await DelegationManager.instance.exitLocal();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = DelegationManager.instance.ownerName;
    return Material(
      color: const Color(0xFF1B8D4B),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              const Icon(
                Icons.supervisor_account,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vous gérez le compte de $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _exiting ? null : _exit,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: _exiting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Quitter', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
