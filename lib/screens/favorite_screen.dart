import 'package:flutter/material.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final int _currentIndex = 0; // Defaulting to 0 for now
  String _selectedCategory = "Bons plans";

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: _currentIndex,
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mes Favoris',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF616161),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5), // light gray bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Faites une recherche...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none, // removes default border
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Filtre par categorie",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.orange),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.line_weight_sharp,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Plus récents",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_drop_down_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoriesIcon(
                      title: "Bons plans",
                      iconColor: const Color.fromARGB(255, 252, 116, 37),
                      bgColor: Color(0xFFFFE0B2).withOpacity(0.2),
                      icon: Icons.card_giftcard_outlined,
                      onTap: () =>
                          setState(() => _selectedCategory = "Bons plans"),
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Offre d'emploi",
                      iconColor: Colors.lightBlueAccent,
                      bgColor: Color(0xFFB3E5FC).withOpacity(0.2),
                      iconAsset: 'assets/images/offres.png',
                      onTap: () =>
                          setState(() => _selectedCategory = "Offre d'emploi"),
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Formations",
                      iconColor: Colors.purple,
                      bgColor: Color(0xFFE1BEE7).withOpacity(0.1),
                      iconAsset: 'assets/images/Formation.png',
                      onTap: () =>
                          setState(() => _selectedCategory = "Formations"),
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Evenements",
                      iconColor: Colors.green,
                      bgColor: Color(0xFFE6F7EF).withOpacity(0.5),
                      icon: Icons.event_outlined,
                      onTap: () =>
                          setState(() => _selectedCategory = "Evenements"),
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Demandes",
                      iconColor: const Color.fromARGB(255, 252, 231, 49),
                      bgColor: Color.fromARGB(255, 255, 250, 178).withOpacity(0.2),
                      icon: Icons.chat_outlined,
                      onTap: () =>
                          setState(() => _selectedCategory = "Demandes"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedCategory == "Bons plans")
              ProPostCard(
                profileImage:
                    'assets/images/dashboard_particulier/Ellipse 11.png',
                username: 'Arlene McCoy',
                userType: 'Pro',
                postText:
                    "Salut, BoursoBank, tu connais ? C'est la banque qui rassemble déjà une communauté de",
                postImage:
                    'assets/images/dashboard_particulier/Rectangle 12 (1).png',
                reductionPercentage: '-10%',
                categoryIcon: Icons.account_balance_outlined,
                categoryName: 'Finances & Assurances',
                merchantName: 'Go Pro',
                timeAgo: 'il y a 3 semaine',
                onTapCTA: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProPostDetailScreen(
                        avatar:
                            'assets/images/dashboard_particulier/Ellipse 11.png',
                        name: 'Arlene McCoy',
                        userType: 'Pro',
                        title: 'Bon plan favori',
                      ),
                    ),
                  );
                },
                price: 'Gratuit',
                likesCount: 125,
                commentsCount: 10,
              )
            else if (_selectedCategory == "Offre d’emploi")
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
                  JobDetailTag(icon: Icons.access_time, text: 'Temps plein'),
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
          ],
        ),
      ),
    );
  }
}
