import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class EvenementsScreen extends StatelessWidget {
  const EvenementsScreen({super.key});

  Widget _buildNotifBubble() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
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
    return AppLayout(
      backgroundColor: const Color(0xFFF9F9FB),
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
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
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evènements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'Manjari',
                                fontWeight: FontWeight.bold,
                              ),
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
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                _buildNotifBubble(),
                              ],
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildNotifBubble(),
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rechercher un emploi, une entreprise, un lieu...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[500], size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Event cards
          SliverList(
            delegate: SliverChildListDelegate([
              EvenementCard(
                profileImage:
                    'assets/images/dashboard_particulier/Ellipse 12.png',
                username: 'Marvin McKinney',
                userType: 'Pro',
                eventTitle:
                    'LE MUSÉE ÉPHÉMÈRE® DES DINOSAURES À NANCY - TOUR 2025',
                eventImage:
                    'assets/images/dashboard_particulier/Rectangle 12 (4).png',
                badge: 'A venir',
                categories: const [
                  'Culture et divertissement',
                  'Spectacle et Billeterie',
                ],
                eventDate: '08 Novembre 2025',
                location: '67100, Strasbourg France',
                timeAgo: 'il y a 1 semaine',
                price: '50€',
                likesCount: 125,
                commentsCount: 10,
                onTapCTA: () {},
              ),
              EvenementCard(
                profileImage:
                    'assets/images/dashboard_particulier/Ellipse 10.png',
                username: 'Esther Howard',
                userType: 'Pro',
                eventTitle: 'Festival de Jazz de Paris - Edition 2025',
                eventImage:
                    'assets/images/dashboard_particulier/Rectangle 12 (1).png',
                badge: 'A venir',
                categories: const ['Musique', 'Festival'],
                eventDate: '15 Décembre 2025',
                location: '75001, Paris France',
                timeAgo: 'il y a 3 jours',
                price: '35€',
                likesCount: 340,
                commentsCount: 25,
                onTapCTA: () {},
              ),
              EvenementCard(
                profileImage:
                    'assets/images/dashboard_particulier/Ellipse 11.png',
                username: 'Jenny Wilson',
                userType: 'Pro',
                eventTitle: 'Salon de la Tech & Innovation - Luxembourg 2025',
                eventImage:
                    'assets/images/dashboard_particulier/Rectangle 12.png',
                badge: 'A venir',
                categories: const ['Technologie', 'Innovation'],
                eventDate: '20 Janvier 2026',
                location: 'Luxembourg Ville',
                timeAgo: 'il y a 5 jours',
                price: 'Gratuit',
                likesCount: 560,
                commentsCount: 42,
                onTapCTA: () {},
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}
