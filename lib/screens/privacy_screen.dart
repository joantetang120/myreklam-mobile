import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/privacy_service.dart';

Future<bool> confirmNewAccountTerms(BuildContext context) async {
  var accepted = false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Conditions de création du compte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: accepted,
                  onChanged: (value) =>
                      setDialogState(() => accepted = value == true),
                  title: const Text(
                    'J’accepte les conditions générales d’utilisation.',
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.myreklam.fr/conditions'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Lire les conditions'),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.myreklam.fr/confidentialite'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Lire la politique de confidentialité'),
                ),
                const Text(
                  'L’acceptation des conditions ne vaut pas consentement commercial.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: accepted ? () => Navigator.pop(context, true) : null,
                child: const Text('Créer mon compte'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

Future<String?> confirmAgeBand(BuildContext context) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: const Text('Confirmez votre âge'),
    content: const Text(
      'MyReklam est réservé aux personnes de 15 ans et plus. Nous enregistrons uniquement une tranche d’âge, pas votre date de naissance.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, '15_17'),
        child: const Text('15 à 17 ans'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, '18_plus'),
        child: const Text('18 ans et plus'),
      ),
    ],
  ),
);

Future<void> ensureAgeConfirmation(BuildContext context) async {
  try {
    final privacy = await ApiClient().authenticatedGet('/privacy/preferences');
    if (privacy['data']?['age_confirmation_required'] == true &&
        context.mounted) {
      final age = await confirmAgeBand(context);
      if (age != null) {
        await ApiClient().authenticatedPut(
          '/privacy/preferences',
          body: {'age_band': age, 'policy_version': '2026-10-10'},
        );
      }
    }
  } catch (_) {
    // Existing accounts remain accessible; unconfirmed age cannot receive marketing.
  }
}

class PrivacyScreen extends StatefulWidget {
  final PrivacyService? service;
  const PrivacyScreen({super.key, this.service});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final PrivacyService _service = widget.service ?? PrivacyService();
  Map<String, dynamic>? _preferences;
  String? _error;
  bool _busy = false;
  Map<String, dynamic>? _postMortem;
  String? _directivesError;
  List<Map<String, dynamic>> _requests = [];
  String? _requestsError;
  bool _requestsLoading = true;
  int _requestsPage = 1;
  int _requestsLastPage = 1;
  @override
  void initState() {
    super.initState();
    _load();
    _loadPostMortem();
    _loadRequests();
  }

  Future<void> _loadRequests({int page = 1}) async {
    if (mounted) {
      setState(() {
        _requestsLoading = true;
        _requestsError = null;
      });
    }
    try {
      final result = await _service.requests(page: page);
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final items = (data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (mounted) {
        setState(() {
          _requests = items;
          _requestsPage = data['current_page'] as int;
          _requestsLastPage = data['last_page'] as int;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _requestsError =
              'Impossible de charger le suivi. Réessayez ou contactez support@myreklam.fr.',
        );
      }
    } finally {
      if (mounted) setState(() => _requestsLoading = false);
    }
  }

  String _requestLabel(String? value) =>
      const {
        'access': 'Accès',
        'rectification': 'Rectification',
        'erasure': 'Effacement',
        'restriction': 'Limitation',
        'objection': 'Opposition',
        'portability': 'Portabilité',
      }[value] ??
      'Demande RGPD';

  String _requestStatus(String? value) =>
      const {
        'received': 'Reçue',
        'processing': 'En cours',
        'external_pending': 'Vérifications auprès des systèmes liés en cours',
        'completed': 'Traitée — consulter la réponse du support',
      }[value] ??
      'En cours d’examen';

  String _requestDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null
        ? 'À confirmer'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _loadPostMortem() async {
    try {
      final result = await _service.postMortem();
      if (mounted) {
        setState(() {
          _postMortem = result['data'] is Map
              ? Map<String, dynamic>.from(result['data'])
              : null;
          _directivesError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _directivesError =
              'Impossible de charger vos directives. Réessayez.',
        );
      }
    }
  }

  Future<void> _editPostMortem() async {
    var choice = _postMortem?['choice']?.toString() ?? 'no_share';
    var consent = false;
    final instructions = TextEditingController(
      text: _postMortem?['instructions']?.toString(),
    );
    final contactName = TextEditingController(
      text: _postMortem?['contact_name']?.toString(),
    );
    final contactEmail = TextEditingController(
      text: _postMortem?['contact_email']?.toString(),
    );
    Map<String, dynamic>? changes;
    try {
      changes = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Directives après décès'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Vous pouvez définir des directives spécifiques sur vos données après votre décès. Elles sont facultatives, distinctes des conditions générales, modifiables et révocables. Aucune détection automatique du décès : notre équipe vérifie les demandes et les justificatifs.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: choice,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'no_share',
                        child: Text('Ne pas communiquer mes données'),
                      ),
                      DropdownMenuItem(
                        value: 'share_designated',
                        child: Text('Communiquer à une personne désignée'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => choice = value ?? 'no_share'),
                  ),
                  TextField(
                    controller: instructions,
                    maxLength: 2000,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Instructions complémentaires',
                    ),
                  ),
                  if (choice == 'share_designated') ...[
                    TextField(
                      controller: contactName,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la personne désignée',
                      ),
                    ),
                    TextField(
                      controller: contactEmail,
                      maxLength: 254,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de cette personne',
                      ),
                    ),
                  ],
                  CheckboxListTile(
                    value: consent,
                    onChanged: (value) =>
                        setDialogState(() => consent = value == true),
                    title: const Text(
                      'Je consens spécifiquement à l’enregistrement et à l’exécution de ces directives.',
                    ),
                  ),
                  const Text(
                    'Évitez toute donnée sensible dans vos instructions. Les obligations légales de conservation restent applicables.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: !consent
                    ? null
                    : () => Navigator.pop(context, {
                        'choice': choice,
                        'instructions': instructions.text.trim(),
                        if (choice == 'share_designated')
                          'contact_name': contactName.text.trim(),
                        if (choice == 'share_designated')
                          'contact_email': contactEmail.text.trim(),
                        'consent': true,
                        'policy_version': '2026-10-10',
                      }),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      );
    } finally {
      instructions.dispose();
      contactName.dispose();
      contactEmail.dispose();
    }
    if (changes == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.updatePostMortem(changes);
      await _loadPostMortem();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.firstError
                  : 'Impossible d’enregistrer vos directives.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revokePostMortem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Révoquer mes directives ?'),
        content: const Text(
          'Aucune directive spécifique ne restera active après cette révocation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.revokePostMortem();
      await _loadPostMortem();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de révoquer vos directives. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    try {
      final result = await _service.preferences();
      if (mounted) {
        setState(() {
          _preferences = Map<String, dynamic>.from(result['data'] as Map);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _save(Map<String, dynamic> changes) async {
    setState(() => _busy = true);
    try {
      await _service.updatePreferences({
        ...changes,
        'policy_version': '2026-10-10',
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final data = await _service.exportData();
      await _loadRequests();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exporter mes données'),
          content: const Text(
            'Cet export contient des données personnelles. Choisissez uniquement une destination de confiance ; une application choisie pour le partage pourra y accéder.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        final directory = Directory(
          '${(await getTemporaryDirectory()).path}/myreklam_private_documents',
        );
        await directory.create(recursive: true);
        final export = File(
          '${directory.path}/myreklam-donnees-${DateTime.now().microsecondsSinceEpoch}.json',
        );
        try {
          await export.writeAsString(
            const JsonEncoder.withIndent('  ').convert(data),
            flush: true,
          );
          if (!mounted) return;
          final renderBox = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(export.path, mimeType: 'application/json')],
            subject: 'Mes données MyReklam',
            sharePositionOrigin: renderBox == null
                ? null
                : renderBox.localToGlobal(Offset.zero) & renderBox.size,
          );
        } finally {
          if (await export.exists()) await export.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestRights() async {
    var type = 'access';
    final details = TextEditingController();
    Map<String, dynamic>? request;
    try {
      request = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Exercer mes droits'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'access',
                        child: Text('Accès complet'),
                      ),
                      DropdownMenuItem(
                        value: 'rectification',
                        child: Text('Rectification'),
                      ),
                      DropdownMenuItem(
                        value: 'erasure',
                        child: Text('Effacement'),
                      ),
                      DropdownMenuItem(
                        value: 'restriction',
                        child: Text('Limitation'),
                      ),
                      DropdownMenuItem(
                        value: 'objection',
                        child: Text('Opposition'),
                      ),
                      DropdownMenuItem(
                        value: 'portability',
                        child: Text('Portabilité'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? 'access'),
                  ),
                  TextField(
                    controller: details,
                    maxLength: 2000,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Précisions (facultatives)',
                      helperText:
                          'N’envoyez pas de pièce d’identité ni de données sensibles.',
                    ),
                  ),
                  const Text(
                    'Cette demande sera examinée par notre équipe. Pour fermer immédiatement votre accès, utilisez Supprimer mon compte dans les paramètres.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'type': type,
                  'details': details.text.trim().isEmpty
                      ? 'Demande de droit depuis les paramètres de l’application mobile.'
                      : details.text.trim(),
                }),
                child: const Text('Envoyer'),
              ),
            ],
          ),
        ),
      );
    } finally {
      details.dispose();
    }
    if (request == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await _service.requestRights(request);
      await _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande enregistrée n° ${result['data']?['id'] ?? ''}. Échéance : ${result['data']?['due_at'] ?? 'sous un mois'}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _preferences;
    final canConsent = p?['age_band'] == '18_plus';
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité et données')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MY REKLAM — 59 Rue des Platanes, 54300 Rehainviller — RCS Nancy 810 545 491. Pour exercer vos droits : support@myreklam.fr.',
          ),
          ListTile(
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse('https://www.myreklam.fr/confidentialite'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
          ListTile(
            title: const Text('Cookies et traceurs du site'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse('https://www.myreklam.fr/cookies'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (p == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (p?['age_confirmation_required'] == true)
            ListTile(
              title: const Text('Confirmer ma tranche d’âge'),
              onTap: _busy
                  ? null
                  : () async {
                      final age = await confirmAgeBand(context);
                      if (age != null) await _save({'age_band': age});
                    },
            ),
          if (p != null) ...[
            const Text(
              'Les communications de service restent indépendantes de ces choix. Le refus des offres commerciales ne limite pas l’accès à votre compte.',
            ),
            SwitchListTile(
              title: const Text('Personnaliser mon fil'),
              subtitle: const Text(
                'Selon mes interactions et abonnements. Désactivé : fil chronologique sur tous mes appareils, indépendamment du marketing.',
              ),
              value: p['feed_personalization_enabled'] != false,
              onChanged: _busy
                  ? null
                  : (value) => _save({'feed_personalization_enabled': value}),
            ),
            SwitchListTile(
              title: const Text('Offres commerciales par e-mail'),
              value: p['marketing_email'] == true,
              onChanged: _busy || !canConsent
                  ? null
                  : (value) => _save({'marketing_email': value}),
            ),
            SwitchListTile(
              title: const Text('Offres commerciales par notification push'),
              value: p['marketing_push'] == true,
              onChanged: _busy || !canConsent
                  ? null
                  : (value) => _save({'marketing_push': value}),
            ),
            SwitchListTile(
              title: const Text(
                'Mesure individuelle des ouvertures et clics des e-mails',
              ),
              value: p['email_tracking'] == true,
              onChanged: _busy || !canConsent
                  ? null
                  : (value) => _save({'email_tracking': value}),
            ),
            if (!canConsent)
              const Text(
                'Les options commerciales sont désactivées pour les mineurs et les comptes dont l’âge n’est pas confirmé.',
              ),
          ],
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exporter mes données'),
            onTap: _busy ? null : _export,
          ),
          const Text(
            'L’export automatique est partiel et ne clôture pas votre demande d’accès. Les pièces jointes et copies du support, d’Odoo ou des prestataires peuvent nécessiter un complément. Utilisez le bouton ci-dessous ou contactez support@myreklam.fr avec la référence de la demande.',
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_outlined),
            title: const Text('Exercer mes droits'),
            onTap: _busy ? null : _requestRights,
          ),
          const Text(
            'Suivre mes demandes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_requestsLoading) const Text('Chargement du suivi…'),
          if (_requestsError != null) Text(_requestsError!),
          TextButton(
            onPressed: _requestsLoading || _busy
                ? null
                : () => _loadRequests(page: _requestsPage),
            child: const Text('Actualiser le suivi'),
          ),
          if (!_requestsLoading && _requestsError == null && _requests.isEmpty)
            const Text('Aucune demande enregistrée.'),
          for (final request in _requests)
            ListTile(
              title: Text(
                '${_requestLabel(request['type'] as String?)} · ${_requestStatus(request['status'] as String?)}',
              ),
              subtitle: Text(
                'Référence : ${request['id']}\nÉchéance de réponse : ${_requestDate(request['due_at'])}',
              ),
            ),
          if (_requestsLastPage > 1)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _requestsLoading || _requestsPage <= 1
                      ? null
                      : () => _loadRequests(page: _requestsPage - 1),
                  child: const Text('Précédent'),
                ),
                Text('Page $_requestsPage sur $_requestsLastPage'),
                TextButton(
                  onPressed:
                      _requestsLoading || _requestsPage >= _requestsLastPage
                      ? null
                      : () => _loadRequests(page: _requestsPage + 1),
                  child: const Text('Suivant'),
                ),
              ],
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_ind_outlined),
            title: const Text('Directives relatives aux données après décès'),
            subtitle: Text(
              _postMortem == null
                  ? 'Aucune directive active'
                  : _postMortem?['choice'] == 'no_share'
                  ? 'Ne pas communiquer mes données'
                  : 'Personne désignée enregistrée',
            ),
            onTap: _busy ? null : _editPostMortem,
          ),
          if (_directivesError != null) ...[
            Text(_directivesError!),
            TextButton(
              onPressed: _loadPostMortem,
              child: const Text('Réessayer les directives'),
            ),
          ],
          if (_postMortem != null)
            TextButton(
              onPressed: _busy ? null : _revokePostMortem,
              child: const Text('Révoquer mes directives'),
            ),
          const Text(
            'Analyse IA : le texte, le lien ou l’image fourni est transmis à nos prestataires d’analyse pour préremplir l’annonce. N’envoyez pas de données sensibles ni de documents personnels. Vérifiez le résultat avant publication. Les demandes ne sont pas analysées automatiquement.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Localisation et notifications : vous pouvez retirer les permissions dans les réglages de votre téléphone. Les permissions techniques ne valent pas consentement publicitaire. Les cookies du site se gèrent dans le centre de préférences du site.',
          ),
        ],
      ),
    );
  }
}
