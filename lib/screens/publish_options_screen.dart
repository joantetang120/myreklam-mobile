import 'package:flutter/material.dart';
import 'package:myreklam/screens/creer_demande_screen.dart';
import 'package:myreklam/screens/creer_evenement_screen.dart';
import 'package:myreklam/screens/creer_formation_screen.dart';
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';
import 'package:myreklam/widgets/publish_option_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_bon_plan_screen.dart';

class PublishOptionsScreen extends StatelessWidget {
  const PublishOptionsScreen({super.key});

  Widget _buildNotifBubble() {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
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
                  top: 10,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            size: 24,
                          ),
                        ),
                        _buildNotifBubble(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Que Souhaitez vous publier ?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFFFF3E0),
                    borderColor: const Color(0xFFFF9800),
                    titleColor: const Color(0xFFFF9800),
                    title: 'Publier un bon plan',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                    icon: Icons.card_giftcard_outlined,
                    iconColor: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreerBonPlanScreen(),
                        ),
                      );
                    },
                  ),
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFE0F7FA),
                    borderColor: Colors.lightBlueAccent,
                    titleColor: Colors.lightBlueAccent,
                    title: "Publier une offre d'emploi",
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                    icon: Icons.work_outline,
                    iconColor: Colors.lightBlueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreerOffreEmploiScreen(),
                        ),
                      );
                    },
                  ),
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFE6F7EF),
                    borderColor: const Color(0xFF3AAE5E),
                    titleColor: const Color(0xFF3AAE5E),
                    title: 'Publier une Formation',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                    icon: Icons.school_outlined,
                    iconColor: const Color(0xFF3AAE5E),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreerFormationScreen(),
                        ),
                      );
                    },
                  ),
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFE0F2F1),
                    borderColor: const Color(0xFF00897B),
                    titleColor: const Color(0xFF00897B),
                    title: 'Publier un Evènement',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                    icon: Icons.event_outlined,
                    iconColor: const Color(0xFF00897B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreerEvenementScreen(),
                        ),
                      );
                    },
                  ),
                  PublishOptionCard(
                    backgroundColor: const Color(0xFFFFF9C4),
                    borderColor: const Color(0xFFFFA000),
                    titleColor: const Color(0xFFFFA000),
                    title: 'Publier une Demande',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore',
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFFFFA000),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreerDemandeScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
