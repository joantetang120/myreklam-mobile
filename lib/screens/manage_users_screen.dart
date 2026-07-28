import 'package:flutter/material.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/delegation_service.dart';
import 'package:myreklam/services/stripe_payment_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

const Color _kGreen = Color(0xFF1B8D4B);

/// Pro feature: add existing users to manage this account, with granular
/// permissions. First manager is free; each additional one costs €5.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final DelegationService _service = DelegationService();
  bool _loading = true;
  List<Delegation> _managers = [];
  bool _nextSeatIsPaid = false;
  double _seatPrice = 5.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _service.getMyManagers();
      if (!mounted) return;
      setState(() {
        _managers = res.managers;
        _nextSeatIsPaid = res.nextSeatIsPaid;
        _seatPrice = res.seatPrice;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddFlow() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddManagerScreen(
          isPaidSeat: _nextSeatIsPaid,
          seatPrice: _seatPrice,
        ),
      ),
    );
    if (added == true) _load();
  }

  Future<void> _editPermissions(Delegation d) async {
    final selected = Set<String>.from(d.permissions);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissions de ${d.user?.name ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...DelegationPermission.all.map(
                    (p) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: _kGreen,
                      value: selected.contains(p),
                      title: Text(
                        DelegationPermission.label(p),
                        style: const TextStyle(fontSize: 13),
                      ),
                      secondary: Icon(DelegationPermission.icon(p), size: 20),
                      onChanged: (v) => setSheet(() {
                        if (v == true) {
                          selected.add(p);
                        } else {
                          selected.remove(p);
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      try {
        await _service.updatePermissions(d.id, selected.toList());
        _load();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  Future<void> _remove(Delegation d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce gestionnaire ?'),
        content: Text(
          '${d.user?.name ?? "Cet utilisateur"} ne pourra plus gérer votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.removeManager(d.id);
      _load();
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
          'Ajouter utilisateurs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Donnez à un utilisateur existant l\'accès à votre compte, avec des permissions précises. Le 1er gestionnaire est gratuit, chaque suivant coûte 5€.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  if (_managers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 56,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun gestionnaire pour le moment',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._managers.map(_buildManagerTile),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _openAddFlow,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(
                        _nextSeatIsPaid
                            ? 'Ajouter un utilisateur (${_seatPrice.toStringAsFixed(0)}€)'
                            : 'Ajouter un utilisateur (gratuit)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildManagerTile(Delegation d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ReklamAvatar(
            avatarUrl: d.user?.avatar,
            displayName: d.user?.name,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.user?.name ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (d.isPaidSeat)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Payant',
                          style: TextStyle(fontSize: 10, color: _kGreen),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.permissions.length} permission(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _editPermissions(d),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _remove(d),
          ),
        ],
      ),
    );
  }
}

/// Add-manager flow: search a user by email, choose permissions, pay if needed.
class _AddManagerScreen extends StatefulWidget {
  final bool isPaidSeat;
  final double seatPrice;

  const _AddManagerScreen({required this.isPaidSeat, required this.seatPrice});

  @override
  State<_AddManagerScreen> createState() => _AddManagerScreenState();
}

class _AddManagerScreenState extends State<_AddManagerScreen> {
  final DelegationService _service = DelegationService();
  final TextEditingController _emailController = TextEditingController();
  bool _searching = false;
  bool _submitting = false;
  DelegationUser? _found;
  bool _alreadyAdded = false;
  String? _error;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _found = null;
    });
    try {
      final res = await _service.searchUser(email);
      if (!mounted) return;
      setState(() {
        _found = res.user;
        _alreadyAdded = res.alreadyAdded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    if (_found == null || _selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      String? paymentIntentId;
      if (widget.isPaidSeat) {
        paymentIntentId = await StripePaymentService().processSeatPayment(
          context: context,
        );
        if (!mounted) return;
        if (paymentIntentId == null) {
          // Cancelled or failed.
          setState(() => _submitting = false);
          return;
        }
      }
      await _service.addManager(
        managerId: _found!.id,
        permissions: _selected.toList(),
        paymentIntentId: paymentIntentId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Erreur: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _submitting = false);
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
          'Ajouter un utilisateur',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Email de l\'utilisateur',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'exemple@email.com',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onPressed: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Chercher'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          if (_found != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  ReklamAvatar(
                    avatarUrl: _found!.avatar,
                    displayName: _found!.name,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _found!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_found!.email != null)
                          Text(
                            _found!.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_alreadyAdded) ...[
              const SizedBox(height: 12),
              const Text(
                'Cet utilisateur gère déjà votre compte.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Text(
                'Que peut-il faire ?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...DelegationPermission.all.map(
                (p) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: _kGreen,
                  value: _selected.contains(p),
                  title: Text(
                    DelegationPermission.label(p),
                    style: const TextStyle(fontSize: 13),
                  ),
                  secondary: Icon(DelegationPermission.icon(p), size: 20),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(p);
                    } else {
                      _selected.remove(p);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (_selected.isEmpty || _submitting)
                      ? null
                      : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isPaidSeat
                              ? 'Payer ${widget.seatPrice.toStringAsFixed(0)}€ et ajouter'
                              : 'Ajouter (gratuit)',
                        ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
