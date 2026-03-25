import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_reward_screen.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_post_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_follow_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/profile_pro/pro_annonces_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_searchSave_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_favoris_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_spacepro_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_settings_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_affiliate_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_subscribe_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_profileEntreprise_screen.dart';
import 'package:myreklam/screens/login_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/utils/user_session.dart';

class ProfileProScreen extends StatefulWidget {
  const ProfileProScreen({super.key});

  @override
  State<ProfileProScreen> createState() => _ProfileProScreenState();
}

class _ProfileProScreenState extends State<ProfileProScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoggingOut = false;
  bool _isLoading = true;
  String? _companyName;
  String? _siret;
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
          _companyName = response['profile']['company_name'];
          _siret = response['profile']['siret'];
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mon espace',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3AAE5E),
                      border: Border.all(color: Color(0xFF3AAE5E), width: 1.5),
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
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Text(
                        '10',
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
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              image: _avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/${_avatarUrl!}",
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _avatarUrl == null
                                ? const Icon(
                                    Icons.business,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF8A40),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
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
                            Text(
                              _companyName ?? 'Entreprise',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              UserSession().email ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _siret != null ? 'SIRET: $_siret' : '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
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
                                    'Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF8A40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    UserSession().subscriptionPlan
                                            ?.toUpperCase() ??
                                        'FREE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/profil_pro/reward.png',
                                  width: 12,
                                  height: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '145',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'My\'s',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 50),

                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "5.0",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(0 avis)",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('0', 'Post(s)', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProPostScreen(),
                          ),
                        );
                      }),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildStatColumn('0', 'Follower(s)', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProFollowScreen(initialTab: 0),
                          ),
                        );
                      }),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildStatColumn('0', 'Suivie(s)', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProFollowScreen(initialTab: 1),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const PublierScreen();
                              },
                            ),
                          ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProPublicViewScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEF8A40,
                            ).withOpacity(0.2),
                            foregroundColor: const Color(0xFFEF8A40),
                            side: const BorderSide(color: Color(0xFFEF8A40)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/profil_pro/eye.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Voir mon profil public',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
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
                          builder: (context) => const ProAnnoncesScreen(),
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
                          builder: (context) => const ProPostScreen(),
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
                          builder: (context) => const ProSearchSaveScreen(),
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
                          builder: (context) => const ProFavorisScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-5.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Espace professionnel',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProSpaceProScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-6.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Paramètre du compte',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-7.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Recompenses ambassadeurs',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProRewardScreen(),
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
                          builder: (context) => const ProAffiliateScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-9.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Gérer Abonnement',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProSubscribeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: 'assets/images/profil_pro/opt-10.png',
                    backgroundColor: const Color(0xFFFFE0B2),
                    title: 'Profil Entreprise',
                    description:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor',
                    color: const Color(0xFF04BC7B).withOpacity(0.15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProProfileEntrepriseScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey[200]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E9B5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.help_outline,
                                color: Color(0xFF2E9B5B),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Aide',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF2E9B5B),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _isLoggingOut ? null : _handleLogout,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E9B5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isLoggingOut
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF2E9B5B),
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.logout,
                                      color: Color(0xFF2E9B5B),
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _isLoggingOut
                                    ? 'Déconnexion...'
                                    : 'Deconnexion',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF2E9B5B),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
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
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
