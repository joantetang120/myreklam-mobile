import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myreklam/services/company_service.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

const Color _kGreen = Color(0xFF1B8D4B);

/// A tappable field that lets a user pick their company from existing pro
/// accounts (search by name) or invite a company that isn't on Myreklam yet.
///
/// Controlled: pass [companyId]/[companyName] and handle [onChanged].
class CompanyPickerField extends StatelessWidget {
  final int? companyId;
  final String? companyName;
  final void Function(int? companyId, String? companyName) onChanged;

  const CompanyPickerField({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_CompanyPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CompanyPickerSheet(),
    );
    if (result != null) {
      onChanged(result.id, result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = (companyName != null && companyName!.isNotEmpty);
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.business_outlined, size: 20, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? companyName! : 'Sélectionner une entreprise',
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? const Color(0xFF333333) : Colors.grey[500],
                ),
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: () => onChanged(null, null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CompanyPick {
  final int? id;
  final String? name;
  _CompanyPick({this.id, this.name});
}

class _CompanyPickerSheet extends StatefulWidget {
  const _CompanyPickerSheet();

  @override
  State<_CompanyPickerSheet> createState() => _CompanyPickerSheetState();
}

class _CompanyPickerSheetState extends State<_CompanyPickerSheet> {
  final CompanyService _service = CompanyService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<CompanyResult> _results = [];
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    if (_query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    try {
      final res = await _service.search(_query);
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inviter « $_query »'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Cette entreprise n'est pas encore sur Myreklam. Entrez son email pour l'inviter.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@entreprise.com',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Inviter'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;
    try {
      await _service.invite(companyName: _query, email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation envoyée à $email')),
      );
      // Use the invited name as the (unlinked) company.
      Navigator.pop(context, _CompanyPick(id: null, name: _query));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Échec de l\'invitation: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Entreprise',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: "Tapez le nom de l'entreprise…",
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }
    if (_query.length < 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Saisissez au moins 2 caractères.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        ..._results.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ReklamAvatar(
                  avatarUrl: c.avatar, displayName: c.name, radius: 18),
              title: Text(c.name, style: const TextStyle(fontSize: 14)),
              onTap: () =>
                  Navigator.pop(context, _CompanyPick(id: c.id, name: c.name)),
            )),
        // Invite option when nothing matches exactly.
        if (_results.every(
            (c) => c.name.toLowerCase() != _query.toLowerCase()))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE6F4EC),
              child: Icon(Icons.add_business_outlined, color: _kGreen),
            ),
            title: Text('Inviter « $_query »',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kGreen)),
            subtitle: const Text('Pas encore sur Myreklam',
                style: TextStyle(fontSize: 12)),
            onTap: _invite,
          ),
      ],
    );
  }
}
