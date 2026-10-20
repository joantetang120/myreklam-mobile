import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:myreklam/screens/space_dashboard_screen.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/my_stories_screen.dart';
import 'package:myreklam/screens/managed_accounts_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_annonces_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_post_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_favoris_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_profileEntreprise_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_subscribe_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_spacepro_screen.dart';
import 'package:myreklam/screens/mon_profil_particulier_screen.dart';
import 'package:myreklam/screens/settings_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_settings_screen.dart';
import 'package:myreklam/screens/saved_searches_screen.dart';
import 'package:myreklam/screens/recompenses_screen.dart';
import 'package:myreklam/screens/parrainage_screen.dart';
import 'package:myreklam/screens/espace_candidat_screen.dart';

/// Same labels and grouping as the web sidebar; no extra rights are granted.
class MySpaceMenu extends StatelessWidget {
  const MySpaceMenu({super.key, required this.isPro, this.onReturn});
  final bool isPro;
  final VoidCallback? onReturn;

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    onReturn?.call();
  }

  Future<void> _stories(BuildContext context) async {
    try {
      final response = await ApiClient().authenticatedGet('/stories/mine');
      if (response['success'] != true || response['data'] is! List)
        throw StateError('Invalid stories');
      final stories = (response['data'] as List)
          .map((row) => StoryModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      if (!context.mounted) return;
      await _open(
        context,
        MyStoriesScreen(
          stories: stories,
          userName: 'Mes stories',
          userAvatar: '',
        ),
      );
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger vos stories. Réessayez.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, IconData icon, VoidCallback onTap) => ListTile(
      leading: Icon(
        icon,
        color: AdaptiveColors.foreground(context, const Color(0xFF006D4D)),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AdaptiveColors.foreground(context, Colors.grey),
        ),
      ),
    );
    final canEdit = DelegationManager.instance.can(
      DelegationPermission.editAccount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('PILOTAGE'),
        tile(
          'Tableau de bord',
          Icons.dashboard_outlined,
          () => _open(context, const SpaceDashboardScreen()),
        ),
        tile(
          'Mes annonces',
          Icons.campaign_outlined,
          () => _open(context, const ProAnnoncesScreen()),
        ),
        tile(
          'Mes publications',
          Icons.edit_outlined,
          () => _open(context, const ProPostScreen()),
        ),
        tile('Mes stories', Icons.play_circle_outline, () => _stories(context)),
        tile(
          'Mes favoris',
          Icons.favorite_border,
          () => _open(context, const ProFavorisScreen()),
        ),
        tile(
          'Recherches enregistrées',
          Icons.search,
          () => _open(context, const SavedSearchesScreen()),
        ),
        heading('AVANTAGES'),
        tile(
          "Mes My’s",
          Icons.stars_outlined,
          () => _open(context, const RecompensesScreen()),
        ),
        tile(
          'Parrainage',
          Icons.person_add_outlined,
          () => _open(context, const ParrainageScreen()),
        ),
        heading('COMPTE'),
        if (canEdit) ...[
          tile(
            'Mon profil',
            Icons.person_outline,
            () => _open(
              context,
              isPro
                  ? const ProProfileEntrepriseScreen()
                  : const MonProfilParticulierScreen(),
            ),
          ),
          tile(
            'Paramètres',
            Icons.settings_outlined,
            () => _open(
              context,
              isPro ? const ProSettingsScreen() : const SettingsScreen(),
            ),
          ),
        ],
        tile(
          'Comptes gérés',
          Icons.manage_accounts_outlined,
          () => _open(context, const ManagedAccountsScreen()),
        ),
        if (!isPro)
          tile(
            'Espace candidat',
            Icons.work_outline,
            () => _open(context, const EspaceCandidatScreen()),
          ),
        if (isPro) ...[
          tile(
            'Espace professionnel',
            Icons.business_outlined,
            () => _open(context, const ProSpaceProScreen()),
          ),
          if (canEdit)
            tile(
              'Abonnement',
              Icons.workspace_premium_outlined,
              () => _open(context, const ProSubscribeScreen()),
            ),
        ],
      ],
    );
  }
}
