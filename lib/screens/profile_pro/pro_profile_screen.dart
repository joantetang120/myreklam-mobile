import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/particulier_dashboard_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_reward_screen.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_post_screen.dart';
import 'package:myreklam/screens/followers_screen.dart';
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
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';

class ProfileProScreen extends StatefulWidget {
  final String? userId; // null means viewing own profile

  const ProfileProScreen({super.key, this.userId});

  @override
  State<ProfileProScreen> createState() => _ProfileProScreenState();
}

class _ProfileProScreenState extends State<ProfileProScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _conversationService = ConversationService();
  bool _isLoggingOut = false;
  bool _isLoading = true;
  String? _companyName;
  String? _siret;
  String? _avatarUrl;
  String? _email;
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _unreadNotifCount = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  String? _userId;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  bool get _isViewingOwnProfile =>
      widget.userId == null || widget.userId == UserSession().id?.toString();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await ApiClient().authenticatedGet(
        '/notifications/unread-count',
      );
      if (mounted && response['success'] == true) {
        setState(() => _unreadNotifCount = response['unread_count'] ?? 0);
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final response = widget.userId == null
          ? await _profileService.getProfile()
          : await _profileService.getUserProfile(widget.userId!);

      if (!mounted) return;

      setState(() {
        if (response['user'] != null) {
          _userId = response['user']['id']?.toString();
          _followersCount = response['user']['followers_count'] ?? 0;
          _followingCount = response['user']['following_count'] ?? 0;
          _postsCount = response['user']['posts_count'] ?? 0;
          _email = response['user']['email'];
          _isFollowing = response['is_following'] ?? false;
          _averageRating = (response['user']['average_rating'] ?? 0.0).toDouble();
          _totalReviews = response['user']['total_reviews'] ?? 0;
        }
        if (response['profile'] != null) {
          _companyName = response['profile']['company_name'];
          _siret = response['profile']['siret'];
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

  Future<void> _toggleFollow() async {
    if (_userId == null || _isLoadingFollow) return;

    setState(() => _isLoadingFollow = true);

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(_userId!);
      } else {
        await _profileService.followUser(_userId!);
      }
      setState(() {
        _isFollowing = !_isFollowing;
        _isLoadingFollow = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'Vous suivez maintenant cet utilisateur'
                  : 'Vous ne suivez plus cet utilisateur',
            ),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startConversation() async {
    if (_userId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final targetId = int.tryParse(_userId!);
      if (targetId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final conversation = await _conversationService.getOrCreateConversation(
        targetId,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final displayName = _companyName ?? 'Entreprise';
      final avatar =
          _avatarUrl ?? 'assets/images/dashboard_particulier/Ellipse 10.png';
      final avatarUrl = avatar.startsWith('http')
          ? avatar
          : ApiConfig.resolveMediaUrl(avatar) ?? avatar;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar: avatarUrl,
            status: 'En ligne',
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer la conversation: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    await Permission.photos.request();

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
              toolbarColor: const Color(0xFFEF8A40),
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
                  backgroundColor: Color(0xFF2E9B5B),
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
                  color: const Color(0xFF2E9B5B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFF2E9B5B),
                  size: 50,
                ),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E9B5B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E9B5B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Super !',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
        color: const Color(0xFFEF8A40),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                                        image: _avatarUrl!.startsWith('http')
                                            ? NetworkImage(_avatarUrl!)
                                            : NetworkImage(
                                                ApiConfig.resolveMediaUrl(
                                                      _avatarUrl!,
                                                    ) ??
                                                    '',
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
                              child: _isViewingOwnProfile
                                  ? GestureDetector(
                                      onTap: _pickAndUploadAvatar,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF8A40),
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
                                    )
                                  : const SizedBox.shrink(),
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
                                _email ?? '',
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
                                    UserSession().mys.toString(),
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
                                  _averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "($_totalReviews avis)",
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
                        _buildStatColumn(_postsCount.toString(), 'Post(s)', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProPostScreen(),
                            ),
                          ).then((_) => _loadProfile());
                        }),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _buildStatColumn(
                          _followersCount.toString(),
                          'Follower(s)',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersScreen(
                                  userId: _userId,
                                  initialShowFollowers: true,
                                ),
                              ),
                            ).then((_) => _loadProfile());
                          },
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _buildStatColumn(
                          _followingCount.toString(),
                          'Suivie(s)',
                          () {
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 10),
                    if (_isViewingOwnProfile) ...[
                      // Own profile: show create post and view public profile buttons
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
                              ).then((_) => _loadProfile()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF8A40),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                ).then((_) => _loadProfile());
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFEF8A40,
                                ).withOpacity(0.2),
                                foregroundColor: const Color(0xFFEF8A40),
                                side: const BorderSide(
                                  color: Color(0xFFEF8A40),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                    ] else ...[
                      // Other user's profile: show Message and Suivre buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startConversation,
                              icon: const Icon(
                                Icons.message_outlined,
                                size: 18,
                              ),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3AAE5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingFollow
                                  ? null
                                  : _toggleFollow,
                              icon: _isLoadingFollow
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF3AAE5E),
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isFollowing
                                          ? Icons.check
                                          : Icons.person_add_outlined,
                                      size: 18,
                                    ),
                              label: Text(_isFollowing ? 'Suivi' : 'Suivre'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3AAE5E),
                                side: const BorderSide(
                                  color: Color(0xFF3AAE5E),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          'Gérez vos annonces actives et suivez les performances',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProAnnoncesScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-2.png',
                      backgroundColor: const Color(0xFFE6F7EF),
                      title: 'Mes posts',
                      description:
                          'Consultez et gérez vos publications professionnelles',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProPostScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-3.png',
                      backgroundColor: const Color(0xFFE6F7EF),
                      title: 'Mes recherches sauvegardées',
                      description:
                          'Retrouvez vos recherches et filtres enregistrés',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProSearchSaveScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-4.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Favoris',
                      description:
                          'Vos contenus préférés et opportunités sauvegardées',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProFavorisScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-5.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Espace professionnel',
                      description:
                          'Accédez à vos outils et services dédiés entreprise',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProSpaceProScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-6.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Paramètre du compte',
                      description:
                          'Configurez vos préférences et sécurité du compte',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProSettingsScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-7.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Recompenses ambassadeurs',
                      description:
                          'Consultez vos points et avantages fidélité pro',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProRewardScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-8.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Parrainage',
                      description:
                          'Invitez des entreprises et gagnez des récompenses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProAffiliateScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-9.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Gérer Abonnement',
                      description:
                          'Gérez votre forfait et les options de facturation',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProSubscribeScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                    _buildMenuCard(
                      icon: 'assets/images/profil_pro/opt-10.png',
                      backgroundColor: const Color(0xFFFFE0B2),
                      title: 'Profil Entreprise',
                      description:
                          'Modifiez les informations et la présentation de votre société',
                      color: const Color(0xFF04BC7B).withOpacity(0.15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProProfileEntrepriseScreen(),
                          ),
                        ).then((_) => _loadProfile());
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
                                  color: const Color(
                                    0xFF2E9B5B,
                                  ).withOpacity(0.1),
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
                                  color: const Color(
                                    0xFF2E9B5B,
                                  ).withOpacity(0.1),
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
