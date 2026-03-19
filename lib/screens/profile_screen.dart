import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/my_posts_screen.dart';
import 'package:myreklam/screens/followers_screen.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/screens/favorite_screen.dart';
import 'package:myreklam/screens/my_announces_screen.dart';
import 'package:myreklam/screens/login_screen.dart';
import 'package:myreklam/screens/saved_searches_screen.dart';
import 'package:myreklam/screens/settings_screen.dart';
import 'package:myreklam/screens/espace_candidat_screen.dart';
import 'package:myreklam/screens/recompenses_screen.dart';
import 'package:myreklam/screens/parrainage_screen.dart';
import 'package:myreklam/screens/mon_profil_particulier_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/utils/user_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoggingOut = false;
  bool _isLoading = true;
  String? _pseudo;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _profileService.getProfile();
      if (!mounted) return;

      setState(() {
        if (response['profile'] != null) {
          _pseudo = response['profile']['pseudo'];
          _avatarUrl = response['profile']['avatar_url'];
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _authService.logout();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ParticulierMainScreen(initialIndex: 0),
              ),
            );
          },
        ),
        title: Text(
          _pseudo ?? UserSession().email ?? 'Profil',
          style: const TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: const Icon(
                Icons.person_outline,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(
                                "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/${_avatarUrl!}",
                              )
                            : null,
                        child: _avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3AAE5E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _pseudo ?? 'Utilisateur',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF616161),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFFF9800),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '145',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'My/s',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          UserSession().email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3AAE5E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Particulier',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPostsScreen(),
                        ),
                      );
                    },
                    child: _buildStatColumn('0', 'Post(s)'),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FollowersScreen(),
                        ),
                      );
                    },
                    child: _buildStatColumn('0', 'Follower(s)'),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FollowersScreen(
                            initialShowFollowers: false,
                          ),
                        ),
                      );
                    },
                    child: _buildStatColumn('0', 'Suivi(s)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PublierScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF8A40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/profil_pro/post.png',
                            width: 20,
                            height: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Créer un post ou annonce',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PublicProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text(
                        'Voir mon profil public',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        side: const BorderSide(
                          color: Color(0xFFFF9800),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-1.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Mes annonces',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAnnouncesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-2.png',
                    backgroundColor: const Color(0xFFE6F7EF),
                    title: 'Mes posts',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPostsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-3.png',
                    backgroundColor: const Color(0xFFE6F7EF),
                    title: 'Mes recherches sauvegardées',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedSearchesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-4.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Favoris',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoriteScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-6.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Paramètres du compte',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-7.png',
                    backgroundColor: const Color(0xFFE6F7EF),
                    title: 'Espace candidat',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EspaceCandidatScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-7.png',
                    backgroundColor: const Color(0xFFE6F7EF),
                    title: 'Récompenses',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecompensesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-8.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Parrainage',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParrainageScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-1.png',
                    backgroundColor: const Color(0xFFE6F7EF),
                    title: 'Mon profil',
                    description:
                        'Gérez vos informations personnelles, votre présentation et vos réseaux sociaux',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MonProfilParticulierScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuOption(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF2E9B5B),
                    title: 'Aide',
                    onTap: () {},
                    useProStyle: true,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuOption(
                    icon: Icons.logout,
                    iconColor: const Color(0xFF2E9B5B),
                    title: _isLoggingOut ? 'Déconnexion...' : 'Deconnexion',
                    onTap: _isLoggingOut ? () {} : _handleLogout,
                    useProStyle: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String icon,
    required Color backgroundColor,
    required String title,
    required String description,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(icon, width: 60, height: 60),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF616161),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool useProStyle = false,
  }) {
    final bool showShadow = useProStyle;
    final Color containerColor = useProStyle ? Colors.white : Colors.grey[50]!;
    final Color effectiveIconColor = useProStyle
        ? const Color(0xFF2E9B5B)
        : iconColor;
    final Border? border = useProStyle
        ? null
        : Border.all(color: Colors.grey[200]!);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: useProStyle ? 50 : null,
              height: useProStyle ? 50 : null,
              padding: EdgeInsets.all(useProStyle ? 12 : 8),
              decoration: BoxDecoration(
                color: useProStyle
                    ? const Color(0xFF2E9B5B).withOpacity(0.1)
                    : iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: useProStyle ? 22 : 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ).copyWith(
                      color: useProStyle
                          ? Colors.black.withOpacity(0.5)
                          : const Color(0xFF616161),
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: useProStyle ? 18 : 16,
              color: useProStyle ? const Color(0xFF2E9B5B) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
