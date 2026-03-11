import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';

class OffresEmploiScreen extends StatelessWidget {
  const OffresEmploiScreen({super.key});

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
                            left: 16, right: 16, bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Offres d'emploi",
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
                                  child: const Icon(Icons.arrow_back,
                                      color: Colors.white, size: 22),
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
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 22),
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
                        border:
                            Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.grey[400], size: 20),
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
                      border:
                          Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child:
                        Icon(Icons.tune, color: Colors.grey[500], size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Job cards
          SliverList(
            delegate: SliverChildListDelegate([
                  JobAnnouncementCard(
                    companyLogo:
                        'assets/images/dashboard_particulier/Rectangle 13.png',
                    companyName: 'The North Face Sarl',
                    jobTitle: 'Développeur Fullstack PHP',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                    tags: const [
                      JobDetailTag(
                        icon: Icons.description_outlined,
                        text: 'Contrat à durée indéterminée',
                      ),
                      JobDetailTag(
                        icon: Icons.location_on_outlined,
                        text: 'Luxembourg',
                      ),
                      JobDetailTag(
                        icon: Icons.school_outlined,
                        text: 'Bac+2 / autre diplôme equivalent',
                      ),
                      JobDetailTag(
                        icon: Icons.work_history_outlined,
                        text: "intermédiaire : 1 an d'expérience",
                      ),
                      JobDetailTag(
                        icon: Icons.access_time,
                        text: 'Temps plein',
                      ),
                      JobDetailTag(
                        icon: Icons.home_work_outlined,
                        text: 'Présentiel uniquement',
                      ),
                      JobDetailTag(
                        icon: Icons.monetization_on_outlined,
                        text: 'Selon le profil',
                        isSpecial: true,
                      ),
                    ],
                    advantages: const ['Primes', 'Heures supplementaires'],
                    timeAgo: 'il y a 2 jours',
                    onApply: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JobDetailScreen(
                            companyLogo:
                                'assets/images/dashboard_particulier/Rectangle 13.png',
                            companyName: 'The North Face Sarl',
                            jobTitle: 'Développeur Fullstack PHP',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                            tags: [
                              JobDetailTag(
                                icon: Icons.description_outlined,
                                text: 'Contrat à durée indéterminée',
                              ),
                              JobDetailTag(
                                icon: Icons.location_on_outlined,
                                text: 'Luxembourg',
                              ),
                              JobDetailTag(
                                icon: Icons.school_outlined,
                                text: 'Bac+2 / autre diplôme equivalent',
                              ),
                              JobDetailTag(
                                icon: Icons.work_history_outlined,
                                text: "intermédiaire : 1 an d'expérience",
                              ),
                              JobDetailTag(
                                icon: Icons.access_time,
                                text: 'Temps plein',
                              ),
                              JobDetailTag(
                                icon: Icons.home_work_outlined,
                                text: 'Présentiel uniquement',
                              ),
                              JobDetailTag(
                                icon: Icons.monetization_on_outlined,
                                text: 'Selon le profil',
                                isSpecial: true,
                              ),
                            ],
                            advantages: ['Primes', 'Heures supplementaires'],
                            timeAgo: 'il y a 2 jours',
                          ),
                        ),
                      );
                    },
                  ),
                  JobAnnouncementCard(
                    companyLogo:
                        'assets/images/dashboard_particulier/Rectangle 13.png',
                    companyName: 'Dyson Sarl',
                    jobTitle: 'Designer UI/UX Senior',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
                    tags: const [
                      JobDetailTag(
                        icon: Icons.description_outlined,
                        text: 'Contrat à durée déterminée',
                      ),
                      JobDetailTag(
                        icon: Icons.location_on_outlined,
                        text: 'Paris',
                      ),
                      JobDetailTag(
                        icon: Icons.school_outlined,
                        text: 'Bac+5 / Master',
                      ),
                      JobDetailTag(
                        icon: Icons.work_history_outlined,
                        text: "Senior : 3 ans d'expérience",
                      ),
                      JobDetailTag(
                        icon: Icons.access_time,
                        text: 'Temps plein',
                      ),
                      JobDetailTag(
                        icon: Icons.home_work_outlined,
                        text: 'Télétravail partiel',
                      ),
                      JobDetailTag(
                        icon: Icons.monetization_on_outlined,
                        text: '45 000€ - 55 000€',
                        isSpecial: true,
                      ),
                    ],
                    advantages: const ['Télétravail', 'Tickets restaurant', 'Mutuelle'],
                    timeAgo: 'il y a 1 semaine',
                    onApply: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JobDetailScreen(
                            companyLogo:
                                'assets/images/dashboard_particulier/Rectangle 13.png',
                            companyName: 'Dyson Sarl',
                            jobTitle: 'Designer UI/UX Senior',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
                            tags: [
                              JobDetailTag(
                                icon: Icons.description_outlined,
                                text: 'Contrat à durée déterminée',
                              ),
                              JobDetailTag(
                                icon: Icons.location_on_outlined,
                                text: 'Paris',
                              ),
                              JobDetailTag(
                                icon: Icons.school_outlined,
                                text: 'Bac+5 / Master',
                              ),
                              JobDetailTag(
                                icon: Icons.work_history_outlined,
                                text: "Senior : 3 ans d'expérience",
                              ),
                              JobDetailTag(
                                icon: Icons.access_time,
                                text: 'Temps plein',
                              ),
                              JobDetailTag(
                                icon: Icons.home_work_outlined,
                                text: 'Télétravail partiel',
                              ),
                              JobDetailTag(
                                icon: Icons.monetization_on_outlined,
                                text: '45 000€ - 55 000€',
                                isSpecial: true,
                              ),
                            ],
                            advantages: ['Télétravail', 'Tickets restaurant', 'Mutuelle'],
                            timeAgo: 'il y a 1 semaine',
                          ),
                        ),
                      );
                    },
                  ),
                  JobAnnouncementCard(
                    companyLogo:
                        'assets/images/dashboard_particulier/Rectangle 13.png',
                    companyName: 'Amazon France',
                    jobTitle: 'Chef de Projet Digital',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                    tags: const [
                      JobDetailTag(
                        icon: Icons.description_outlined,
                        text: 'Contrat à durée indéterminée',
                      ),
                      JobDetailTag(
                        icon: Icons.location_on_outlined,
                        text: 'Lyon',
                      ),
                      JobDetailTag(
                        icon: Icons.school_outlined,
                        text: 'Bac+3 / Licence',
                      ),
                      JobDetailTag(
                        icon: Icons.work_history_outlined,
                        text: "intermédiaire : 2 ans d'expérience",
                      ),
                      JobDetailTag(
                        icon: Icons.access_time,
                        text: 'Temps plein',
                      ),
                      JobDetailTag(
                        icon: Icons.home_work_outlined,
                        text: 'Présentiel uniquement',
                      ),
                      JobDetailTag(
                        icon: Icons.monetization_on_outlined,
                        text: '35 000€ - 42 000€',
                        isSpecial: true,
                      ),
                    ],
                    advantages: const ['Primes', 'Formation continue'],
                    timeAgo: 'il y a 3 jours',
                    onApply: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JobDetailScreen(
                            companyLogo:
                                'assets/images/dashboard_particulier/Rectangle 13.png',
                            companyName: 'Amazon France',
                            jobTitle: 'Chef de Projet Digital',
                            description:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                            tags: [
                              JobDetailTag(
                                icon: Icons.description_outlined,
                                text: 'Contrat à durée indéterminée',
                              ),
                              JobDetailTag(
                                icon: Icons.location_on_outlined,
                                text: 'Lyon',
                              ),
                              JobDetailTag(
                                icon: Icons.school_outlined,
                                text: 'Bac+3 / Licence',
                              ),
                              JobDetailTag(
                                icon: Icons.work_history_outlined,
                                text: "intermédiaire : 2 ans d'expérience",
                              ),
                              JobDetailTag(
                                icon: Icons.access_time,
                                text: 'Temps plein',
                              ),
                              JobDetailTag(
                                icon: Icons.home_work_outlined,
                                text: 'Présentiel uniquement',
                              ),
                              JobDetailTag(
                                icon: Icons.monetization_on_outlined,
                                text: '35 000€ - 42 000€',
                                isSpecial: true,
                              ),
                            ],
                            advantages: ['Primes', 'Formation continue'],
                            timeAgo: 'il y a 3 jours',
                          ),
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }
}
