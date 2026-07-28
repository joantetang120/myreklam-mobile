import 'package:flutter/material.dart';
import 'package:myreklam/widgets/avatars_story.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/post_card.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/widgets/news_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/screens/favorite_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A8143), Color(0xFF3AAE5E)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(0, -1),
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: greenGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 20,
                    child: Image.asset(
                      'assets/images/logo blanc 2.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    right: 20,
                    child: Row(
                      spacing: 8,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoriteScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red, // Added light green background
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.red, // Added light green background
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),

                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // rest of the page
            const SizedBox(height: 16),

            //story
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      spacing: 5,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE6F7EF),
                            border: Border.all(color: Color(0xFF3AAE5E)),
                          ),
                          child: Center(
                            child: Icon(Icons.add, color: Color(0xFF3AAE5E)),
                          ),
                        ),
                        const Text(
                          "Votre story",
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),

                    // avatars
                    AvatarsStory(
                      name: "Selena",
                      imageName:
                          'assets/images/dashboard_particulier/Ellipse 10.png',
                    ),
                    AvatarsStory(
                      name: "Slime",
                      imageName:
                          'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                    ),
                    AvatarsStory(
                      name: "Joe",
                      imageName:
                          'assets/images/dashboard_particulier/Ellipse 10 (2).png',
                    ),
                    AvatarsStory(
                      name: "Joe",
                      imageName:
                          'assets/images/dashboard_particulier/Ellipse 10 (3).png',
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ), // space on sides
              child: Container(
                height: 1, // thin line
                color: Colors.grey[300], // light gray
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text("Catégories"), const Text("voir tout")],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CategoriesIcon(
                    title: "Bons plans",
                    iconColor: Colors.deepOrange,
                    bgColor: Color(0xFFFFE0B2),
                    icon: Icons.card_giftcard_outlined,
                  ),
                  CategoriesIcon(
                    title: "Offre d’emploi",
                    iconColor: Colors.lightBlueAccent,
                    bgColor: Color(0xFFB3E5FC),
                    icon: Icons.card_giftcard_outlined,
                  ),
                  CategoriesIcon(
                    title: "Formations",
                    iconColor: Colors.green,
                    bgColor: Color(0xFFE6F7EF),
                    icon: Icons.calendar_month_outlined,
                  ),
                  CategoriesIcon(
                    title: "Demandes",
                    iconColor: Colors.deepOrange,
                    bgColor: Color(0xFFFFE0B2),
                    icon: Icons.chat_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            PostCard(
              profileImage:
                  'assets/images/dashboard_particulier/Ellipse 10.png',
              username: 'Bessie Cooper',
              userType: 'Particulier',
              postText:
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
              postImage: 'assets/images/dashboard_particulier/Rectangle 12.png',
              likesCount: 675,
              commentsCount: 2,
              timeAgo: 'il y a 3 semaine',
            ),

            const SizedBox(height: 16),

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
                          'assets/images/dashboard_particulier/Ellipse 10.png',
                      name: 'Floyd Miles',
                      userType: 'Particulier',
                      title: 'Bon plan à découvrir',
                    ),
                  ),
                );
              },
              price: 'Gratuit',
              likesCount: 125,
              commentsCount: 10,
            ),

            const SizedBox(height: 24),

            // News Feed Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Fil d’actualités",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF616161),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "voir tout",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 310,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 4),
                children: const [
                  NewsCard(
                    image:
                        'assets/images/dashboard_particulier/Rectangle 12.png',
                    title:
                        'Coupe du Monde 2026 : enjeux, nouveautés et préparatifs pour un',
                    summary:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                  ),
                  NewsCard(
                    image:
                        'assets/images/dashboard_particulier/Rectangle 12 (4).png',
                    title:
                        'France : entre transitions économiques, enjeux sociaux',
                    summary:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                  ),
                  NewsCard(
                    image:
                        'assets/images/dashboard_particulier/Rectangle 12 (5).png',
                    title:
                        'Innovation Technologique : Les tendances à suivre en 2026',
                    summary:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

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
                      companyName: 'Dyson Sarl',
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

            const SizedBox(height: 40),

            ProPostCard(
              profileImage:
                  'assets/images/dashboard_particulier/Ellipse 12.png',
              username: 'Marvin McKinney',
              userType: 'Pro',
              postText:
                  "Porsche : légendaire, luxueuse, sportive. Performances brutes et design iconique. Un rêve de vitesse....plus",
              postImage:
                  'assets/images/dashboard_particulier/Rectangle 12 (4).png',
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
                          'assets/images/dashboard_particulier/Ellipse 10.png',
                      name: 'Floyd Miles',
                      userType: 'Particulier',
                      title: 'Offre exceptionnelle',
                    ),
                  ),
                );
              },
              price: '50.000€',
              likesCount: 125,
              commentsCount: 10,
            ),
          ],
        ),
      ),
    );
  }
}
