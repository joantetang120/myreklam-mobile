import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/widgets/my_post_item.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  String _selectedTab = 'Présentation';
  final List<_DocumentSection> _documentSections = const [
    _DocumentSection(
      title: 'CV',
      documents: [
        _DocumentItem(
          title: 'Curriculum Vitae',
          date: '5 Janvier 2026',
        ),
      ],
    ),
    _DocumentSection(
      title: 'Lettre de motivation',
      documents: [
        _DocumentItem(
          title: 'Lettre de motivation',
          date: '5 Janvier 2026',
        ),
      ],
    ),
  ];

  int get _documentCount => _documentSections
      .fold<int>(0, (total, section) => total + section.documents.length);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 4,
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3AAE5E)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ParticulierMainScreen(
                  initialIndex: 4,
                ),
              ),
            );
          },
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 25,
                    top: 40,
                  ),
                  padding: const EdgeInsets.only(
                    top: 68,
                    left: 30,
                    right: 20,
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E9B5B),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ralph Edwards',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'SIRET: 81054649100039',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/profil_pro/profil-etiq.png',
                            width: 17,
                            height: 17,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Information et communication',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '5.0 (0 avis)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E9B5B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Particulier',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E9B5B), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage(
                          'assets/images/profil/Ellipse 41.png',
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 75,
                  left: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            FontAwesomeIcons.facebook,
                            color: Color(0xFF1877F2),
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1306C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            FontAwesomeIcons.instagram,
                            color: Color(0xFFE1306C),
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            FontAwesomeIcons.youtube,
                            color: Color(0xFFFF0000),
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
                child: Row(
                children: [
                  _buildTabButton('Présentation'),
                  _buildTabButton('Annonces(2)'),
                  _buildTabButton('Post'),
                  _buildTabButton('Documents'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 'Présentation') ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bannière',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/profil/Rectangle 238.png',
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Présentation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medias photos et vidéos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 40,
                              color: const Color(0xFFFF9800),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 40,
                              color: Colors.transparent,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/profil/Rectangle 195.png',
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/profil/Rectangle 196.png',
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/profil/Rectangle 197.png',
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedTab == 'Annonces(2)') ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Filtres',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Localisation',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ProPostCard(
                profileImage: 'assets/images/dashboard_particulier/Ellipse 10.png',
                username: 'Savannah Nguyen',
                userType: 'Particulier',
                postText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                postImage: 'assets/images/dashboard_particulier/Rectangle 12.png',
                reductionPercentage: '-50%',
                categoryIcon: Icons.restaurant,
                categoryName: 'Restaurant',
                merchantName: 'Chez Marcel',
                timeAgo: 'il y a 2h',
                price: '25€',
                likesCount: 125,
                commentsCount: 10,
                onTapCTA: () {},
              ),
              ProPostCard(
                profileImage: 'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                username: 'Savannah Nguyen',
                userType: 'Particulier',
                postText: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                postImage: 'assets/images/dashboard_particulier/Rectangle 12 (1).png',
                reductionPercentage: '-30%',
                categoryIcon: Icons.shopping_bag,
                categoryName: 'Shopping',
                merchantName: 'Fashion Store',
                timeAgo: 'il y a 5h',
                price: '45€',
                likesCount: 89,
                commentsCount: 15,
                onTapCTA: () {},
              ),
            ],
            if (_selectedTab == 'Post') ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    MyPostItem(
                      image: 'assets/images/posts/Rectangle 189.png',
                      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore...voir plus',
                      likeCount: 125,
                      commentCount: 10,
                      shareCount: 2,
                      onEdit: () {},
                      onDelete: () {},
                    ),
                    const SizedBox(height: 20),
                    MyPostItem(
                      image: 'assets/images/posts/Rectangle 189 (1).png',
                      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore...voir plus',
                      likeCount: 125,
                      commentCount: 10,
                      shareCount: 2,
                      onEdit: () {},
                      onDelete: () {},
                    ),
                    const SizedBox(height: 20),
                    MyPostItem(
                      image: 'assets/images/posts/Rectangle 189 (2).png',
                      content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore...voir plus',
                      likeCount: 125,
                      commentCount: 10,
                      shareCount: 2,
                      onEdit: () {},
                      onDelete: () {},
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedTab == 'Documents') ...[
              _buildDocumentsTab(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mes documents (${_documentCount})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF616161),
              fontFamily: 'Manjari',
            ),
          ),
          const SizedBox(height: 16),
          ..._documentSections
              .map((section) => _buildDocumentSection(section))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(_DocumentSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF616161),
              fontFamily: 'Manjari',
            ),
          ),
          const SizedBox(height: 12),
          ...section.documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDocumentTile(doc),
            ),
          ),
          if (section != _documentSections.last)
            const Divider(height: 24, thickness: 1, color: Color(0xFFEFEFEF)),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(_DocumentItem document) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF2E9B5B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2F2F2F),
                    fontFamily: 'Manjari',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Text(
                      document.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildDocumentAction(
            icon: Icons.remove_red_eye,
            color: const Color(0xFF1DA1F2),
          ),
          const SizedBox(width: 8),
          _buildDocumentAction(
            icon: Icons.download,
            color: const Color(0xFF2E9B5B),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentAction({required IconData icon, required Color color}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTabButton(String key, {String? displayLabel}) {
    final isSelected = _selectedTab == key;
    final text = displayLabel ?? key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF9800) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

}

class _DocumentSection {
  const _DocumentSection({
    required this.title,
    required this.documents,
  });

  final String title;
  final List<_DocumentItem> documents;
}

class _DocumentItem {
  const _DocumentItem({
    required this.title,
    required this.date,
  });

  final String title;
  final String date;
}
