import 'package:flutter/material.dart';
import 'package:myreklam/services/api_client.dart';

class FollowApprovalSettings extends StatefulWidget {
  const FollowApprovalSettings({super.key, this.load, this.save});
  final Future<bool> Function()? load;
  final Future<void> Function(bool)? save;
  @override
  State<FollowApprovalSettings> createState() => _FollowApprovalSettingsState();
}

class _FollowApprovalSettingsState extends State<FollowApprovalSettings> {
  bool? _automatic;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final value = widget.load != null
          ? await widget.load!()
          : (await ApiClient().authenticatedGet(
              '/profile/me/follow-settings',
            ))['auto_accept_follow_requests'];
      if (value is! bool) throw StateError('Invalid setting');
      if (mounted) setState(() => _automatic = value);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Impossible de charger les demandes de suivi.');
    }
  }

  Future<void> _change(bool value) async {
    final previous = _automatic;
    setState(() {
      _automatic = value;
      _saving = true;
      _error = null;
    });
    try {
      if (widget.save != null) {
        await widget.save!(value);
      } else {
        final result = await ApiClient().authenticatedPut(
          '/profile/me/follow-settings',
          body: {'auto_accept_follow_requests': value},
        );
        if (result['success'] == false) throw StateError('Save failed');
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _automatic = previous;
          _error = 'Le réglage n’a pas pu être enregistré.';
        });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        SwitchListTile(
          title: const Text('Demandes de suivi'),
          subtitle: Text(
            _automatic == false
                ? 'Acceptation manuelle depuis les notifications'
                : 'Accepter automatiquement les nouveaux abonnés',
          ),
          value: _automatic ?? false,
          onChanged: _automatic == null || _saving ? null : _change,
        ),
        if (_automatic == null && _error == null)
          const LinearProgressIndicator(),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
        if (_automatic == null && _error != null)
          TextButton(onPressed: _load, child: const Text('Réessayer')),
      ],
    ),
  );
}
