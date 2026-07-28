import 'package:flutter/material.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/screens/splash_screen.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/services/delegation_service.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

const Color _kGreen = Color(0xFF1B8D4B);

/// "Gérer compte" — accounts the current user has been assigned to manage.
/// Tapping "Se connecter" switches the session to that account (with the
/// granted permissions) and re-routes to its home via the splash screen.
class ManagedAccountsScreen extends StatefulWidget {
  const ManagedAccountsScreen({super.key});

  @override
  State<ManagedAccountsScreen> createState() => _ManagedAccountsScreenState();
}

class _ManagedAccountsScreenState extends State<ManagedAccountsScreen> {
  final DelegationService _service = DelegationService();
  bool _loading = true;
  bool _connecting = false;
  List<Delegation> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final accounts = await _service.getManagedAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect(Delegation d) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      final response = await _service.connect(d.id);
      await DelegationManager.instance.enter(response);
      if (!mounted) return;
      // Re-run session restore as the managed account.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connexion impossible: $e')));
        setState(() => _connecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Gérer compte',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: _accounts.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.supervisor_account_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Aucun compte à gérer.\nQuand quelqu\'un vous autorise, il apparaît ici.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Connectez-vous à un compte que vous gérez. Vous agirez en son nom, selon les permissions accordées.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ..._accounts.map(_buildAccountTile),
                      ],
                    ),
            ),
    );
  }

  Widget _buildAccountTile(Delegation d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReklamAvatar(
                avatarUrl: d.user?.avatar,
                displayName: d.user?.name,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  d.user?.name ?? 'Compte',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _connecting ? null : () => _connect(d),
                child: const Text('Se connecter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: d.permissions
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          DelegationPermission.icon(p),
                          size: 13,
                          color: _kGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DelegationPermission.label(p),
                          style: const TextStyle(fontSize: 11, color: _kGreen),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
