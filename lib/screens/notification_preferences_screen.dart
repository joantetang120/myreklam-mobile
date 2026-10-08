import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'match_alerts_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/push_notification_service.dart';

/// Préférences de notifications partagées avec le site Web.
///
/// Aucune valeur n'est conservée localement : l'API est la source de vérité,
/// ce qui garantit qu'un changement effectué ici est immédiatement visible sur
/// le Web (et inversement).
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic> _settings = const {};
  List<Map<String, dynamic>> _categories = const [];
  Map<String, Map<String, dynamic>> _preferences = const {};
  bool _loading = true;
  String? _saving;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _api.authenticatedGet(
        '/notifications/preferences',
      );
      final preferenceItems = List<dynamic>.from(
        response['preferences'] as List? ?? const [],
      );
      if (!mounted) return;
      setState(() {
        _settings = Map<String, dynamic>.from(
          response['settings'] as Map? ?? const {},
        );
        _categories = List<dynamic>.from(
          response['categories'] as List? ?? const [],
        ).map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _preferences = {
          for (final item in preferenceItems)
            item['event_key'].toString(): Map<String, dynamic>.from(
              item as Map,
            ),
        };
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger vos préférences de notification.';
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_saving != null) return;
    final previous = Map<String, dynamic>.from(_settings);
    setState(() {
      _settings = {..._settings, key: value};
      _saving = key;
      _error = null;
    });
    try {
      final response = await _api.authenticatedPut(
        '/notifications/settings',
        body: {key: value},
      );
      if (!mounted) return;
      setState(() {
        _settings = Map<String, dynamic>.from(
          response['settings'] as Map? ?? _settings,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _error = 'Ce réglage n’a pas pu être enregistré.';
      });
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _updateChannel(
    String eventKey,
    String channel,
    bool value,
  ) async {
    if (_saving != null) return;
    final current = _preferences[eventKey];
    if (current == null || current['required_$channel'] == true) return;
    final next = Map<String, dynamic>.from(current)
      ..['${channel}_enabled'] = value;
    setState(() {
      _preferences = {..._preferences, eventKey: next};
      _saving = '$eventKey:$channel';
      _error = null;
    });
    try {
      await _api.authenticatedPut(
        '/notifications/preferences/$eventKey',
        body: {
          'push_enabled': next['push_enabled'] == true,
          'email_enabled': next['email_enabled'] == true,
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferences = {..._preferences, eventKey: current};
        _error = 'Cette préférence n’a pas pu être enregistrée.';
      });
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _authorizePush() async {
    setState(() => _saving = 'permission');
    try {
      final permission = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        await PushNotificationService.instance.registerToken();
      }
      if (!mounted) return;
      final allowed =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allowed
                ? 'Notifications Push autorisées sur cet appareil.'
                : 'Activez les notifications dans les réglages du téléphone.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _chooseTime(String key) async {
    final raw = (_settings[key] ?? (key.endsWith('start') ? '22:00' : '07:00'))
        .toString();
    final parts = raw.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    await _updateSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Choisissez comment MyReklam vous prévient. Ces réglages sont synchronisés avec le site Web.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    MaterialBanner(
                      content: Text(_error!),
                      actions: [
                        TextButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _settingsCard(),
                  const SizedBox(height: 16),
                  ..._categories.map(_categoryCard),
                ],
              ),
            ),
    );
  }

  Widget _settingsCard() {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          _settingSwitch(
            'Tout mettre en pause',
            'Coupe uniquement les notifications optionnelles.',
            'pause_optional',
          ),
          _settingSwitch(
            'Canal global Push',
            'Conserve les choix individuels.',
            'push_global_enabled',
          ),
          _settingSwitch(
            'Canal global E-mail',
            'Les alertes obligatoires restent envoyées.',
            'email_global_enabled',
          ),
          _settingSwitch(
            'Heures silencieuses',
            'Suspend les Push optionnels pendant cette plage.',
            'quiet_hours_enabled',
          ),
          if (_settings['quiet_hours_enabled'] == true)
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text('Plage silencieuse'),
              subtitle: Text(
                '${_shortTime('quiet_hours_start')} – ${_shortTime('quiet_hours_end')}',
              ),
              onTap: _saving == null
                  ? () async {
                      await _chooseTime('quiet_hours_start');
                      if (mounted) await _chooseTime('quiet_hours_end');
                    }
                  : null,
            ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Autoriser les notifications Push'),
            subtitle: const Text('Permission de cet appareil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _saving == null ? _authorizePush : null,
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('Alertes métier et zone'),
            subtitle: const Text('Offres d’emploi et demandes près de vous'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MatchAlertsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _settingSwitch(String title, String subtitle, String key) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      activeThumbColor: const Color(0xFF12A05C),
      value: _settings[key] == true,
      onChanged: _saving == null ? (value) => _updateSetting(key, value) : null,
    );
  }

  Widget _categoryCard(Map<String, dynamic> category) {
    final events = List<dynamic>.from(category['events'] as List? ?? const []);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          category['label']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: events.map((raw) {
          final event = Map<String, dynamic>.from(raw as Map);
          final key = event['event_key'].toString();
          final preference = _preferences[key];
          if (preference == null) return const SizedBox.shrink();
          return _eventRow(event, preference);
        }).toList(),
      ),
    );
  }

  Widget _eventRow(
    Map<String, dynamic> event,
    Map<String, dynamic> preference,
  ) {
    final key = event['event_key'].toString();
    final requiredPush = preference['required_push'] == true;
    final requiredEmail = preference['required_email'] == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['label']?.toString() ?? key),
                if (requiredPush || requiredEmail)
                  const Text(
                    'Alerte obligatoire',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0D8A4F)),
                  ),
              ],
            ),
          ),
          _channelSwitch(
            'Push',
            preference['push_enabled'] == true || requiredPush,
            requiredPush,
            (value) => _updateChannel(key, 'push', value),
          ),
          _channelSwitch(
            'E-mail',
            preference['email_enabled'] == true || requiredEmail,
            requiredEmail,
            (value) => _updateChannel(key, 'email', value),
          ),
        ],
      ),
    );
  }

  Widget _channelSwitch(
    String label,
    bool value,
    bool required,
    ValueChanged<bool> onChanged,
  ) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeThumbColor: const Color(0xFF12A05C),
              onChanged: _saving == null && !required ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String key) {
    final value = (_settings[key] ?? '').toString();
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}
