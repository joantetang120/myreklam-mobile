import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/services/space_dashboard_service.dart';
import 'package:myreklam/screens/profile_pro/pro_annonces_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_favoris_screen.dart';
import 'package:myreklam/screens/saved_searches_screen.dart';
import 'package:myreklam/screens/recompenses_screen.dart';
import 'package:myreklam/screens/parrainage_screen.dart';
import 'package:myreklam/screens/managed_accounts_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_subscribe_screen.dart';
import 'package:myreklam/screens/mon_profil_particulier_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_profileEntreprise_screen.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/delegation_manager.dart';

class SpaceDashboardScreen extends StatefulWidget {
  const SpaceDashboardScreen({super.key, this.service});
  final SpaceDashboardService? service;
  @override
  State<SpaceDashboardScreen> createState() => _SpaceDashboardScreenState();
}

class _SpaceDashboardScreenState extends State<SpaceDashboardScreen> {
  late Future<SpaceDashboardData> _request;
  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<SpaceDashboardData> _load() =>
      (widget.service ?? SpaceDashboardService()).load();
  Future<void> _refresh() async {
    final request = _load();
    setState(() => _request = request);
    try {
      await request;
    } catch (_) {
      /* Rendered by FutureBuilder. */
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tableau de bord')),
    body: FutureBuilder<SpaceDashboardData>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(
            child: TextButton(
              onPressed: _refresh,
              child: const Text('Chargement impossible. Réessayer'),
            ),
          );
        }
        final data = snapshot.data!;
        Widget stat(String label, Object? value, Widget destination) => Card(
          child: ListTile(
            title: Text(label),
            subtitle: Text(
              value is num
                  ? NumberFormat.decimalPattern('fr_FR').format(value)
                  : value?.toString() ?? 'Non disponible',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(destination),
          ),
        );
        final checks = data.completion;
        const labels = [
          'Vérifier votre adresse e-mail',
          'Ajouter une photo de profil',
          'Renseigner votre téléphone',
          'Écrire une présentation',
          'Publier une première annonce',
          'Enregistrer une recherche',
        ];
        final completed = checks.where((value) => value == true).length;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Mon espace',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              stat(
                'Mes annonces',
                data.totalAcross(false),
                const ProAnnoncesScreen(),
              ),
              stat(
                'Mes favoris',
                data.totalAcross(true),
                const ProFavorisScreen(),
              ),
              stat(
                'Recherches enregistrées',
                data.searches,
                const SavedSearchesScreen(),
              ),
              stat('Solde My’s', data.balance, const RecompensesScreen()),
              stat(
                'Parrainage · personnes parrainées',
                data.referred,
                const ParrainageScreen(),
              ),
              if (data.isPro) ...[
                stat(
                  'Comptes gérés',
                  SpaceDashboardData.listTotal(
                    data.responses['/delegations/received'],
                  ),
                  const ManagedAccountsScreen(),
                ),
                stat(
                  'Abonnement',
                  data.responses['/subscriptions/current'] == null
                      ? null
                      : ((data.responses['/subscriptions/current']!['subscription']
                                as Map?)?['status'] ??
                            'Aucun abonnement'),
                  const ProSubscribeScreen(),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Compléter mon profil · $completed / 6',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: completed / 6),
              for (var index = 0; index < labels.length; index++)
                ListTile(
                  leading: Icon(
                    checks[index] == null
                        ? Icons.help_outline
                        : checks[index]!
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: checks[index] == true
                        ? AdaptiveColors.foreground(
                            context,
                            const Color(0xFF006D4D),
                          )
                        : AdaptiveColors.foreground(context, Colors.grey),
                  ),
                  title: Text(labels[index]),
                  subtitle: checks[index] == null
                      ? const Text('Vérification temporairement indisponible')
                      : null,
                  onTap:
                      index > 0 &&
                          index < 4 &&
                          DelegationManager.instance.can(
                            DelegationPermission.editAccount,
                          )
                      ? () => _open(
                          data.isPro
                              ? const ProProfileEntrepriseScreen()
                              : const MonProfilParticulierScreen(),
                        )
                      : index == 4
                      ? () => _open(const PublierScreen())
                      : index == 5
                      ? () => _open(const SavedSearchesScreen())
                      : null,
                ),
              if (data.responses.values.any((value) => value == null))
                TextButton(
                  onPressed: _refresh,
                  child: const Text(
                    'Certaines données sont indisponibles. Réessayer',
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
