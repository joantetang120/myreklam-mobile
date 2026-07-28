import 'package:flutter/material.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/models/delegation.dart';

class PublierScreen extends StatelessWidget {
  const PublierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (DelegationManager.instance.can(
                        DelegationPermission.announcements,
                      ))
                        _buildOptionCard(
                          context,
                          image:
                              'assets/images/publier_bottom/Wavy_Bus-05_Single-03-[Converti] 1.png',
                          title: 'Publier une annonce',
                          description:
                              'Publiez du contenu à partager avec votre communauté : un bon plan, un événement...',
                        ),
                      if (DelegationManager.instance.can(
                        DelegationPermission.announcements,
                      ))
                        const SizedBox(height: 16),
                      if (DelegationManager.instance.can(
                        DelegationPermission.posts,
                      ))
                        _buildOptionCard(
                          context,
                          image:
                              'assets/images/publier_bottom/Wavy_Bus-05_Single-03-[Converti] 1 (1).png',
                          title: 'Créer un post',
                          description:
                              'Partagez avec votre communauté des actualités, des photos, des idées, etc',
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String image,
    required String title,
    required String description,
  }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Publier une annonce') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ParticulierMainScreen(
                initialIndex: 2,
                showPublishOptions: true,
              ),
            ),
          );
        } else if (title == 'Créer un post') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ParticulierMainScreen(
                initialIndex: 2,
                showCreatePost: true,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(image, width: 100, height: 100, fit: BoxFit.contain),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
