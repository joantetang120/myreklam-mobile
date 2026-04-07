import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/particulier_dashboard_screen.dart';
import 'package:myreklam/screens/my_posts_screen.dart';
import 'package:myreklam/screens/followers_screen.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/screens/favorite_screen.dart';
import 'package:myreklam/screens/my_announces_screen.dart';
import 'package:myreklam/screens/login_screen.dart';
import 'package:myreklam/screens/saved_searches_screen.dart';
import 'package:myreklam/screens/settings_screen.dart';
import 'package:myreklam/screens/espace_candidat_screen.dart';
import 'package:myreklam/screens/recompenses_screen.dart';
import 'package:myreklam/screens/parrainage_screen.dart';
import 'package:myreklam/screens/mon_profil_particulier_screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';
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
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _unreadNotifCount = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiClient().authenticatedGet('/notifications/unread-count');
      if (mounted && response['success'] == true) {
        setState(() => _unreadNotifCount = response['unread_count'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _profileService.getProfile();
      if (!mounted) return;

      setState(() {
        if (response['user'] != null) {
          _userId = response['user']['id']?.toString();
          _followersCount = response['user']['followers_count'] ?? 0;
          _followingCount = response['user']['following_count'] ?? 0;
          _postsCount = response['user']['posts_count'] ?? 0;
        }
        if (response['profile'] != null) {
          _pseudo = response['profile']['pseudo'];
          _avatarUrl = response['profile']['avatar_url'];
        }
        _isLoading = false;
      });
      
      // Refresh bottom bar avatar
      CustomBottomBar.refreshAvatarNotifier.value = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    await Permission.photos.request();
    // We ignore denied for modern Android (Android 13+) which uses the photo picker

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 80,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Ajuster l\'Avatar',
              toolbarColor: const Color(0xFF3AAE5E),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Ajuster l\'Avatar'),
          ],
        );

        if (croppedFile != null) {
          setState(() => _isLoading = true);

          final file = File(croppedFile.path);
          final response = await _profileService.uploadAvatar(file);

          if (response['success'] == true && response['avatar_url'] != null) {
            setState(() {
              _avatarUrl = response['avatar_url'];
            });
            // Update bottom bar avatar immediately
            CustomBottomBar.avatarNotifier.value = response['avatar_url'];

            // Show My's reward modal if awarded
            final mysAwarded = response['mys_awarded'] ?? 0;
            if (mysAwarded > 0 && mounted) {
              // Trigger dashboard refresh
              ParticulierDashboardScreen.refreshMysNotifier.value = true;
              _showMysRewardModal(mysAwarded, response['new_mys_balance'] ?? 0);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Avatar mis à jour avec succès!'),
                  backgroundColor: Color(0xFF3AAE5E),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMysRewardModal(int mysAwarded, int newBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3AAE5E).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFF3AAE5E), size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Félicitations ! 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous avez gagné $mysAwarded My\'s en ajoutant votre photo de profil !',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Nouveau solde : $newBalance My\'s',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3AAE5E)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AAE5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Super !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                ).then((_) => _loadProfile());
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
                  if (_unreadNotifCount > 0)
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
                        child: Text(
                          '$_unreadNotifCount',
                          style: const TextStyle(
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
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFF3AAE5E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          backgroundImage:
                              _avatarUrl != null &&
                                  (_avatarUrl!.startsWith('https') ||
                                      _avatarUrl!.startsWith('http'))
                              ? NetworkImage(_avatarUrl!)
                              : (_avatarUrl != null
                                    ? NetworkImage(
                                        "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/${_avatarUrl!}",
                                      )
                                    : null),
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
                          child: GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3AAE5E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
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
                                    Text(
                                      UserSession().mys.toString(),
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
                      child: _buildStatColumn(
                        _postsCount.toString(),
                        'Post(s)',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FollowersScreen(userId: _userId),
                          ),
                        ).then((_) => _loadProfile());
                      },
                      child: _buildStatColumn(
                        _followersCount.toString(),
                        'Follower(s)',
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowersScreen(
                              userId: _userId,
                              initialShowFollowers: false,
                            ),
                          ),
                        ).then((_) => _loadProfile());
                      },
                      child: _buildStatColumn(
                        _followingCount.toString(),
                        'Suivi(s)',
                      ),
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
                          ).then((_) => _loadProfile());
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
                              builder: (context) => const ParticulierPublicViewScreen(),
                            ),
                          ).then((_) => _loadProfile());
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
                          'Gérez vos annonces actives, modifiez ou supprimez vos publications',
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
                          'Consultez et gérez vos publications sur le réseau social',
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
                          'Retrouvez vos critères de recherche',
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
                          'Vos contenus préférés et éléments sauvegardés',
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
                          'Configurez vos préférences et sécurité',
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
                      icon: 'assets/images/profil_pro/carbon_user.png',
                      backgroundColor: const Color(0xFFE6F7EF),
                      title: 'Espace candidat',
                      description:
                          'Suivez vos candidatures et documents professionnels',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EspaceCandidatScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-7.png',
                      backgroundColor: const Color(0xFFE6F7EF),
                      title: 'Récompenses',
                      description:
                          'Consultez vos points et avantages fidélité',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecompensesScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-8.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Parrainage',
                      description:
                          'Invitez vos amis et gagnez des récompenses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ParrainageScreen(),
                          ),
                        ).then((_) => _loadProfile());
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
                        ).then((_) => _loadProfile());
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
