import 'package:flutter/material.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String _selectedFilter = 'Annonces';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ParticulierMainScreen(
                  initialIndex: 3,
                ),
              ),
            );
          },
        ),
        title: const Text(
          'Résultat de la recherche',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un emploi, une entreprise, un...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('Annonces', true),
                const SizedBox(width: 8),
                _buildFilterChip('Rechercher un particulier (0)', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ProPostCard(
                    profileImage: 'assets/images/dashboard_particulier/Ellipse 10.png',
                    username: 'Jane Cooper',
                    userType: 'Particulier',
                    postText: 'Promo Appareil photo Hybride Sony A6400 Noir + Objectif E PZ 16-50 mm',
                    postImage: 'assets/images/dashboard_particulier/Rectangle 12 (1).png',
                    reductionPercentage: '-10%',
                    categoryIcon: Icons.camera_alt_outlined,
                    categoryName: 'High-tech - Matériel',
                    merchantName: 'Amazon',
                    timeAgo: 'il y a 1 semaine',
                    price: '849,00€',
                    likesCount: 675,
                    commentsCount: 2,
                  ),
                  ProPostCard(
                    profileImage: 'assets/images/dashboard_particulier/Ellipse 11.png',
                    username: 'Bessie Cooper',
                    userType: 'Particulier',
                    postText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem',
                    postImage: 'assets/images/dashboard_particulier/Rectangle 12 (2).png',
                    categoryIcon: Icons.laptop_mac_outlined,
                    categoryName: 'Informatique',
                    merchantName: 'Tech Store',
                    timeAgo: 'il y a 3 semaine',
                    price: '12,90€',
                    likesCount: 675,
                    commentsCount: 2,
                  ),
                  ProPostCard(
                    profileImage: 'assets/images/dashboard_particulier/Ellipse 12.png',
                    username: 'Arlene McCoy',
                    userType: 'Pro',
                    postText: 'Salut, BoursoBank, tu connais ? C\'est la banque qui rassemble déjà une communauté de',
                    postImage: 'assets/images/dashboard_particulier/Rectangle 12 (4).png',
                    reductionPercentage: '-10%',
                    categoryIcon: Icons.account_balance_outlined,
                    categoryName: 'Finances & Assurances',
                    merchantName: 'Go Pro',
                    timeAgo: 'il y a 1 semaine',
                    price: 'Gratuit',
                    likesCount: 125,
                    commentsCount: 10,
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

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
