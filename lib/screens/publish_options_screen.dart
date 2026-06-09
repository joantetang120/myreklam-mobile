import 'package:flutter/material.dart';
import 'package:myreklam/screens/creer_demande_screen.dart';
import 'package:myreklam/screens/creer_evenement_screen.dart';
import 'package:myreklam/screens/creer_formation_screen.dart';
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/widgets/publish_option_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_bon_plan_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/utils/guest_access.dart';
import 'package:myreklam/utils/subscription_helper.dart';
import 'package:myreklam/screens/profile_pro/pro_reward_screen.dart';

class PublishOptionsScreen extends StatefulWidget {
  const PublishOptionsScreen({super.key});

  @override
  State<PublishOptionsScreen> createState() => _PublishOptionsScreenState();
}

class _PublishOptionsScreenState extends State<PublishOptionsScreen> {
  final UserSession _userSession = UserSession();

  void _navigateIfAllowed(BuildContext context, Widget screen) {
    if (_userSession.isPro &&
        !SubscriptionHelper.canAccessFeature(ProFeature.postAnnouncement)) {
      SubscriptionHelper.showPremiumRequiredDialog(
        context,
        featureName: 'Publication d\'annonces',
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildNotifBubble(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE6F7EF),
          border: Border.all(color: const Color(0xFF2A8143), width: 1.5),
        ),
        child: const Icon(
          Icons.notifications,
          color: Color(0xFF2A8143),
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: const Color(0xFF2A8143),
            automaticallyImplyLeading: false,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double appBarHeight = constraints.maxHeight;
                final double expandRatio =
                    ((appBarHeight - kToolbarHeight) / (120 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                final bool isCollapsed = expandRatio < 0.1;

                return FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A8143), Color(0xFF3AAE5E)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              "assets/images/LOGO VERT.png",
                              width: 130,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  titlePadding: EdgeInsets.zero,
                  title: isCollapsed
                      ? SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ParticulierMainScreen(
                                              initialIndex: 0,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                _buildNotifBubble(context),
                              ],
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  if (!GuestAccess.ensureAuthenticated(
                    context,
                    featureName: 'voir les récompenses',
                  )) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProRewardScreen(),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/profil_pro/reward.png',
                        width: 12,
                        height: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        UserSession().mys.toString(),
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'My\'s',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildNotifBubble(context),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'Que Souhaitez vous publier ?',
                    style: TextStyle(
                      color: Color(0xFF616161),
                      fontSize: 20,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PublishOptionCard(
                  backgroundColor: const Color(0xFFFFF3E0),
                  borderColor: const Color(0xFFFF9800),
                  titleColor: const Color(0xFFFF9800),
                  title: 'Publier un bon plan',
                  description:
                      'Partagez les meilleures offres, promotions et bons plans avec la communauté.',
                  icon: Icons.card_giftcard_outlined,
                  iconColor: const Color(0xFFFF9800),
                  onTap: () =>
                      _navigateIfAllowed(context, const CreerBonPlanScreen()),
                ),
                // Show Offre d'emploi and Formation only for professionals
                if (_userSession.isPro) ...[
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFE0F7FA),
                    borderColor: Colors.lightBlueAccent,
                    titleColor: Colors.lightBlueAccent,
                    title: "Publier une offre d'emploi",
                    description:
                        'Déposez vos offres de recrutement ou trouvez des opportunités professionnelles.',
                    icon: Icons.work_outline,
                    iconColor: Colors.lightBlueAccent,
                    onTap: () => _navigateIfAllowed(
                      context,
                      const CreerOffreEmploiScreen(),
                    ),
                  ),
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFE6F7EF),
                    borderColor: const Color(0xFF3AAE5E),
                    titleColor: const Color(0xFF3AAE5E),
                    title: 'Publier une Formation',
                    description:
                        'Proposez vos formations et partagez vos connaissances avec les membres.',
                    icon: Icons.school_outlined,
                    iconColor: const Color(0xFF3AAE5E),
                    onTap: () => _navigateIfAllowed(
                      context,
                      const CreerFormationScreen(),
                    ),
                  ),
                ],
                PublishOptionCard(
                  backgroundColor: const Color(0xFFE0F2F1),
                  borderColor: const Color(0xFF00897B),
                  titleColor: const Color(0xFF00897B),
                  title: 'Publier un Evènement',
                  description:
                      'Organisez et annoncez vos événements, rencontres et activités.',
                  icon: Icons.event_outlined,
                  iconColor: const Color(0xFF00897B),
                  onTap: () =>
                      _navigateIfAllowed(context, const CreerEvenementScreen()),
                ),
                PublishOptionCard(
                  backgroundColor: const Color(0xFFFFF9C4),
                  borderColor: const Color(0xFFFFA000),
                  titleColor: const Color(0xFFFFA000),
                  title: 'Publier une Demande',
                  description:
                      'Exprimez vos besoins et recevez des réponses de la communauté.',
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFFFFA000),
                  onTap: () =>
                      _navigateIfAllowed(context, CreerDemandeScreen()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
