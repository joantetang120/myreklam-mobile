import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/location_data.dart';
import '../widgets/location_picker_field.dart';

class MatchAlertsScreen extends StatefulWidget {
  const MatchAlertsScreen({super.key});
  @override
  State<MatchAlertsScreen> createState() => _MatchAlertsScreenState();
}

class _MatchAlertsScreenState extends State<MatchAlertsScreen> {
  final _keywords = TextEditingController();
  final _radius = TextEditingController(text: '150');
  final _api = ApiClient();
  bool _jobs = false,
      _requests = false,
      _allFrance = false,
      _loading = true,
      _saving = false;
  bool _loaded = false;
  List<String> _education = [];
  List<String> _educationOptions = [];
  LocationData? _location;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywords.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await _api.authenticatedGet(
        '/announcement-match-preferences',
      );
      final data = Map<String, dynamic>.from(response['data'] as Map);
      if (!mounted) return;
      setState(() {
        _jobs = data['jobs_enabled'] == true;
        _requests = data['requests_enabled'] == true;
        _allFrance = data['all_france'] == true;
        _keywords.text = (data['keywords'] as List? ?? []).join(', ');
        _education = (data['education_levels'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        _educationOptions = (response['education_options'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        if (_keywords.text.isEmpty) {
          _keywords.text = (response['suggested_keywords'] as List? ?? []).join(
            ', ',
          );
        }
        _radius.text = '${data['radius_km'] ?? 150}';
        if (data['location_city'] != null) {
          _location = LocationData(
            address: '${data['location_city']}',
            city: '${data['location_city']}',
            latitude: double.tryParse('${data['location_lat']}'),
            longitude: double.tryParse('${data['location_lng']}'),
          );
        }
        _loaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Impossible de charger les alertes. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _api.authenticatedPut(
        '/announcement-match-preferences',
        body: {
          'jobs_enabled': _jobs,
          'requests_enabled': _requests,
          'keywords': _keywords.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'education_levels': _education,
          'radius_km': int.tryParse(_radius.text),
          'all_france': _allFrance,
          'location_city': _location?.city,
          'location_lat': _location?.latitude,
          'location_lng': _location?.longitude,
        },
      );
      if (mounted) {
        setState(
          () =>
              _message = 'Alertes enregistrées pour le site et l’application.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Impossible d’enregistrer les alertes.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alertes métier et zone')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Recevez les offres d’emploi et demandes correspondant à votre métier et votre rayon. Les canaux push et email restent réglables dans vos notifications.',
              ),
              SwitchListTile(
                title: const Text('Offres d’emploi'),
                value: _jobs,
                onChanged: _loaded && !_saving
                    ? (v) => setState(() => _jobs = v)
                    : null,
              ),
              SwitchListTile(
                title: const Text('Demandes de prestations'),
                value: _requests,
                onChanged: _loaded && !_saving
                    ? (v) => setState(() => _requests = v)
                    : null,
              ),
              TextField(
                controller: _keywords,
                enabled: _loaded && !_saving,
                decoration: const InputDecoration(
                  labelText: 'Métiers / domaines séparés par des virgules',
                  hintText: 'Plombier, plomberie, carreleur',
                ),
              ),
              if (_jobs) ...[
                const Text(
                  'Niveaux recherchés (facultatif ; aucun choix = tous les niveaux)',
                ),
                ..._educationOptions.map(
                  (level) => CheckboxListTile(
                    title: Text(level),
                    value: _education.contains(level),
                    onChanged: _saving
                        ? null
                        : (selected) => setState(() {
                            if (selected == true) {
                              _education.add(level);
                            } else {
                              _education.remove(level);
                            }
                          }),
                  ),
                ),
              ],
              SwitchListTile(
                title: const Text('Toute la France'),
                value: _allFrance,
                onChanged: _loaded && !_saving
                    ? (v) => setState(() => _allFrance = v)
                    : null,
              ),
              if (!_allFrance) ...[
                LocationPickerField(
                  key: ValueKey(_loaded),
                  initialLocation: _location,
                  label: 'Votre ville',
                  onLocationSelected: (v) {
                    if (!_saving) setState(() => _location = v);
                  },
                ),
                TextField(
                  controller: _radius,
                  enabled: _loaded && !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rayon en km (1 à 500)',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loaded && !_saving ? _save : null,
                child: Text(
                  _saving ? 'Enregistrement…' : 'Enregistrer mes alertes',
                ),
              ),
              if (!_loaded)
                TextButton(
                  onPressed: _load,
                  child: const Text('Réessayer le chargement'),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!),
                ),
            ],
          ),
  );
}
