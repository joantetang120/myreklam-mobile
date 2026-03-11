import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/bons_plans_screen.dart';
import 'package:myreklam/screens/offres_emploi_screen.dart';
import 'package:myreklam/screens/formation_screen.dart';
import 'package:myreklam/screens/evenements_screen.dart';
import 'package:myreklam/screens/demandes_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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
    final List<_CategoryItem> categories = [
      _CategoryItem(
        title: 'Bons Plans',
        description: 'consectetur adipiscing elit.altconsecteur adipiscing elit.',
        icon: Icons.card_giftcard_outlined,
        bgColor: const Color(0xFFFFE0B2).withOpacity(0.3),
        iconColor: const Color.fromARGB(255, 252, 116, 37),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BonsPlansScreen()),
          );
        },
      ),
      _CategoryItem(
        title: "Offre d'emploi",
        description: 'consectetur adipiscing elit.altconsecteur adipiscing elit.',
        icon: Icons.work_outline,
        bgColor: const Color(0xFFB3E5FC).withOpacity(0.3),
        iconColor: Colors.lightBlueAccent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OffresEmploiScreen()),
          );
        },
      ),
      _CategoryItem(
        title: 'Formation',
        description: 'consectetur adipiscing elit.altconsecteur adipiscing elit.',
        icon: Icons.school_outlined,
        bgColor: const Color(0xFFE1BEE7).withOpacity(0.2),
        iconColor: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormationScreen()),
          );
        },
      ),
      _CategoryItem(
        title: 'Evènement',
        description: 'consectetur adipiscing elit.altconsecteur adipiscing elit.',
        icon: Icons.event_outlined,
        bgColor: const Color(0xFFE6F7EF).withOpacity(0.5),
        iconColor: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EvenementsScreen()),
          );
        },
      ),
      _CategoryItem(
        title: 'Demandes',
        description: 'consectetur adipiscing elit.altconsecteur adipiscing elit.',
        icon: Icons.chat_outlined,
        bgColor: Color.fromARGB(255, 255, 250, 178).withOpacity(0.3),
        iconColor: const Color.fromARGB(255, 252, 231, 49),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DemandesScreen()),
          );
        },
      ),
    ];

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
                              'Catégories',
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                        'Rechercher une catégorie',
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
          ),

          // Categories grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  return GestureDetector(
                    onTap: cat.onTap,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cat.bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cat.iconColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cat.icon,
                              color: cat.iconColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cat.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.description,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String description;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  _CategoryItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });
}
