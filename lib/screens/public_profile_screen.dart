import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/screens/followers_screen.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicProfileScreen extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initialData;

  const PublicProfileScreen({super.key, this.userId, this.initialData});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction;

  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userReaction,
  });
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _profileService = ProfileService();
  final _conversationService = ConversationService();

  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _selectedTab = 'Présentation';
  bool _isFollowing = false;

  // Annonces state
  String _selectedAnnonceFilter = 'Tout';
  List<Map<String, dynamic>> _bonPlans = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingAnnonces = true;
  String? _annoncesError;

  // Posts state
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  // Reactions cache
  final Map<String, _ReactionData> _reactions = {};

  bool get _isOwnProfile {
    final profileId = _userData?['id']?.toString();
    final currentId = UserSession().id;
    return profileId != null && currentId != null && profileId == currentId;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final String? targetId =
          widget.userId ?? widget.initialData?['id']?.toString();

      if (targetId == null) {
        // Fallback to current user if no ID provided
        final response = await _profileService.getProfile();
        setState(() {
          _userData = response['user'] ?? response;
          _isLoading = false;
        });
      } else {
        final response = await _profileService.getUserProfile(targetId);
        setState(() {
          _userData = response['user'] ?? response;
          _isFollowing = response['is_following'] ?? false;
          _isLoading = false;
        });
      }
      // Load annonces and posts after profile is loaded
      await _loadAnnonces();
      await _loadPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du profil: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final targetId = _userData?['id']?.toString();
    if (targetId == null) return;

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _startConversation() async {
    final targetIdStr = _userData?['id']?.toString();
    final targetId = int.tryParse(targetIdStr ?? '');

    if (targetId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _conversationService.getOrCreateConversation(
        targetId,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final displayName = _extractDisplayName(_userData);
      final avatar = _extractAvatar(_userData);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar: avatar,
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

  void _showReportConfirmation() {
    final displayName = _extractDisplayName(_userData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler le compte'),
        content: Text('Voulez-vous vraiment signaler $displayName ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement envoyé'),
                  backgroundColor: Color(0xFF3AAE5E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Signaler',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportReasonDialog() async {
    final targetId = _userData?['id']?.toString();
    if (targetId == null || targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'identifier ce compte.')),
      );
      return;
    }

    final displayName = _extractDisplayName(_userData);
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        String? reasonError;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Signaler le compte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pourquoi voulez-vous signaler $displayName ?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Expliquez la raison du signalement...',
                    errorText: reasonError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final reason = reasonController.text.trim();
                        if (reason.length < 10) {
                          setDialogState(() {
                            reasonError =
                                'Veuillez saisir au moins 10 caracteres.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          reasonError = null;
                        });

                        try {
                          await _profileService.reportUser(targetId, reason);
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Signalement envoye'),
                              backgroundColor: Color(0xFF3AAE5E),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            reasonError = e is ApiException
                                ? e.firstError
                                : 'Impossible d\'envoyer le signalement.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Signaler',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        );
      },
    );
    reasonController.dispose();
  }

  String _extractDisplayName(Map<String, dynamic>? data) {
    if (data == null) return 'Utilisateur';
    final pro = data['pro_profile'] as Map?;
    final part = data['particulier_profile'] as Map?;

    if (part != null) return part['pseudo']?.toString() ?? 'Utilisateur';
    if (pro != null)
      return pro['company_name']?.toString() ??
          '${pro['first_name'] ?? ''} ${pro['last_name'] ?? ''}'.trim();

    return data['name']?.toString() ?? 'Utilisateur';
  }

  String _extractAvatar(Map<String, dynamic>? data) {
    if (data == null)
      return 'assets/images/dashboard_particulier/Ellipse 10.png';

    final pro = data['pro_profile'] as Map?;
    final part = data['particulier_profile'] as Map?;

    String? url =
        part?['avatar_url']?.toString() ??
        pro?['logo_url']?.toString() ??
        pro?['avatar_url']?.toString() ??
        data['avatar']?.toString();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return url;
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      return '$serverBase/storage/$url';
    }

    return 'assets/images/dashboard_particulier/Ellipse 10.png';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = _extractDisplayName(_userData);
    final avatar = _extractAvatar(_userData);
    final accountType = _userData?['pro_profile'] != null
        ? 'Professionnel'
        : 'Particulier';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3AAE5E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            color: Color(0xFF616161),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: (widget.userId == null && widget.initialData?['id'] == null) ||
                _isOwnProfile
            ? null
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF616161)),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportReasonDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Signaler le compte',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2E9B5B),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountType,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // Stats Row: Posts, Followers, Following
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                (_userData?['posts_count'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Posts',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: () {
                              final String? uid = _userData?['id']?.toString();
                              if (uid != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersScreen(
                                      userId: uid,
                                      initialShowFollowers: true,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  (_userData?['followers_count'] ?? 0)
                                      .toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Followers',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: () {
                              final String? uid = _userData?['id']?.toString();
                              if (uid != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersScreen(
                                      userId: uid,
                                      initialShowFollowers: false,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  (_userData?['following_count'] ?? 0)
                                      .toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Suivi(s)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons (hidden for own profile)
                      if (!_isOwnProfile)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    vertical: 10,
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
                                onPressed: _toggleFollow,
                                icon: Icon(
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
                                    vertical: 10,
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
                  ),
                ),

                // Avatar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E9B5B),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        backgroundImage: avatar.startsWith('http')
                            ? NetworkImage(avatar) as ImageProvider
                            : avatar.startsWith('assets/')
                            ? AssetImage(avatar)
                            : NetworkImage(
                                    ApiConfig.resolveMediaUrl(avatar) ?? '',
                                  )
                                  as ImageProvider,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton('Présentation'),
                  _buildTabButton('Annonces'),
                  _buildTabButton('Post'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            _buildTabContent(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEF8A40) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'Annonces':
        return _buildAnnonceTab();
      case 'Post':
        return _buildPostTab();
      default:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Présentation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                _userData?['bio'] ?? 'Aucune présentation disponible.',
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
            ],
          ),
        );
    }
  }

  // ==================== ANNONCES TAB ====================

  Widget _buildAnnonceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Tout', _selectedAnnonceFilter == 'Tout'),
                    _buildFilterChip(
                      'Bons plans',
                      _selectedAnnonceFilter == 'Bons plans',
                    ),
                    _buildFilterChip(
                      'Événements',
                      _selectedAnnonceFilter == 'Événements',
                    ),
                    _buildFilterChip(
                      'Demandes',
                      _selectedAnnonceFilter == 'Demandes',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoadingAnnonces)
            const Center(child: CircularProgressIndicator())
          else if (_annoncesError != null)
            Text(_annoncesError!, style: const TextStyle(color: Colors.red))
          else if (_selectedAnnonceFilter == 'Tout')
            Column(
              children: [
                if (_bonPlans.isNotEmpty) _buildBonPlansList(),
                if (_events.isNotEmpty) _buildEventsList(),
                if (_demandes.isNotEmpty) _buildDemandesList(),
                if (_bonPlans.isEmpty && _events.isEmpty && _demandes.isEmpty)
                  const Text(
                    'Aucune annonce',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
              ],
            )
          else if (_selectedAnnonceFilter == 'Bons plans')
            _buildBonPlansList()
          else if (_selectedAnnonceFilter == 'Événements')
            _buildEventsList()
          else if (_selectedAnnonceFilter == 'Demandes')
            _buildDemandesList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedAnnonceFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ==================== POSTS TAB ====================

  Widget _buildPostTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_postsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(_postsError!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadPosts(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_myPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Pas de post', style: TextStyle(color: Colors.grey))),
            )
          else
            for (final post in _myPosts) ...[
              _buildPostCard(post),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final user = rawPost['user'] as Map<String, dynamic>?;
    final userType = user?['account_type']?.toString() ?? 'Particulier';
    final postText = rawPost['content']?.toString() ?? '';
    final createdAt = rawPost['created_at']?.toString();
    final imageUrl = _extractPostImageUrl(rawPost);

    final tags = <PostTag>[
      PostTag(
        title: userType,
        icon: userType.toUpperCase() == 'PRO' ? Icons.business : Icons.person,
        color: userType.toUpperCase() == 'PRO'
            ? const Color(0xFF2E9B5B)
            : const Color(0xFF3AAE5E),
      ),
    ];

    return PostContentCard(
      tags: tags,
      title: postText.isNotEmpty ? postText : 'Post sans contenu',
      time: _buildTimeAgo(createdAt),
      imageUrl: imageUrl,
      onLike: () {},
      onShare: () {},
    );
  }

  String? _extractPostImageUrl(Map<String, dynamic> post) {
    final media = post['media'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return ApiConfig.resolveMediaUrl(url);
        }
      }
    }
    return null;
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadAnnonces() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnnonces = true;
      _annoncesError = null;
    });

    try {
      final targetUserId = widget.userId ?? _userData?['id']?.toString();

      final results = await Future.wait([
        ApiClient().authenticatedGet('/bonplans'),
        ApiClient().authenticatedGet('/events'),
        ApiClient().authenticatedGet('/demandes'),
      ]);

      List<Map<String, dynamic>> filterByUser(
        List<Map<String, dynamic>> items,
      ) {
        if (targetUserId == null || targetUserId.isEmpty) return items;
        return items.where((m) {
          final userId =
              m['user_id']?.toString() ?? m['user']?['id']?.toString();
          return userId == targetUserId;
        }).toList();
      }

      final bonPlans = filterByUser(_extractList(results[0]));
      final events = filterByUser(_extractList(results[1]));
      final demandes = filterByUser(_extractList(results[2]));

      if (!mounted) return;
      setState(() {
        _bonPlans = bonPlans;
        _events = events;
        _demandes = demandes;
        _isLoadingAnnonces = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _annoncesError = e.message;
        _isLoadingAnnonces = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _annoncesError = 'Erreur de chargement';
        _isLoadingAnnonces = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoadingPosts = true);
    try {
      final targetUserId = widget.userId ?? _userData?['id']?.toString();
      if (targetUserId == null) {
        setState(() {
          _myPosts = [];
          _isLoadingPosts = false;
        });
        return;
      }
      final response = await ApiClient().authenticatedGet(
        '/users/$targetUserId/posts',
      );
      final data = response is Map ? response['data'] : null;
      final posts = data is List
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _myPosts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
      if (!mounted) return;
      setState(() {
        _postsError = 'Erreur lors du chargement des posts: $e';
        _isLoadingPosts = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return const <Map<String, dynamic>>[];
  }

  // ==================== LIST BUILDERS ====================

  Widget _buildBonPlansList() {
    final items = _bonPlans;
    if (items.isEmpty) {
      return const Text(
        'Aucune annonce',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((bp) => _buildBonPlanCard(bp)).toList());
  }

  Widget _buildEventsList() {
    final items = _events;
    if (items.isEmpty) {
      return const Text(
        'Aucune annonce',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((ev) => _buildEventCard(ev)).toList());
  }

  Widget _buildDemandesList() {
    final items = _demandes;
    if (items.isEmpty) {
      return const Text(
        'Aucune annonce',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((d) => _buildDemandeCard(d)).toList());
  }

  // ==================== CARD BUILDERS ====================

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final bpId = bp['id']?.toString() ?? '';
    final title = bp['title']?.toString() ?? '';
    final category = bp['category']?.toString() ?? '';
    final description = _stripHtml(bp['description']?.toString() ?? '');
    final discount = bp['discount']?.toString();
    final createdAt = bp['created_at']?.toString();
    final imageUrl = _extractMediaUrl(bp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3AAE5E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF3AAE5E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (discount != null && discount.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: Colors.orange[700],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Réduction: $discount',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _buildTimeAgo(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (bpId.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          _seedReactionFromResource('bon-plans', bpId, bp);
                          return _buildReactionBar('bon-plans', bpId);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventId = event['id']?.toString() ?? '';
    final title = event['title']?.toString() ?? '';
    final description = _stripHtml(event['description']?.toString() ?? '');
    final location =
        event['location']?.toString() ?? event['city']?.toString() ?? '';
    final eventDate =
        event['event_date']?.toString() ?? event['start_date']?.toString();
    final createdAt = event['created_at']?.toString();
    final price =
        event['price']?.toString() ?? event['ticket_price']?.toString();
    final isPaid = event['is_paid'] == true || event['is_paid'] == 1;
    final imageUrl = _extractMediaUrl(event);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 4),
                    Text(
                      isPaid && price != null ? '${price}€' : 'Gratuit',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _buildTimeAgo(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (eventId.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          _seedReactionFromResource('events', eventId, event);
                          return _buildReactionBar(
                            'events',
                            eventId,
                            acceptedMessages: event['accept_messages'] == true,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final demandeId = demande['id']?.toString() ?? '';
    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');
    final nature = demande['nature']?.toString() ?? 'Demande';
    final createdAt = demande['created_at']?.toString();
    final location =
        demande['location']?.toString() ?? demande['city']?.toString() ?? '';
    final postImage = _extractMediaUrl(demande);

    final categoryLabel = _getNatureLabel(nature);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (postImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                postImage,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor(nature).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoryLabel,
                    style: TextStyle(
                      color: _categoryColor(nature),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (location.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _buildTimeAgo(createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (demandeId.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          _seedReactionFromResource(
                            'demandes',
                            demandeId,
                            demande,
                          );
                          return _buildReactionBar(
                            'demandes',
                            demandeId,
                            acceptedMessages:
                                demande['accept_messages'] == true,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REACTIONS ====================

  String _reactionKey(String apiSlug, String entityId) =>
      '${apiSlug}_$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromResource(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource,
  ) {
    final key = _reactionKey(apiSlug, entityId);
    // Always update from resource data to ensure fresh counts
    _reactions[key] = _ReactionData(
      likesCount: _asInt(resource['likes_count']),
      commentsCount: _asInt(resource['comments_count']),
      userReaction: resource['user_reaction']?.toString(),
    );
  }

  Future<void> _refreshReactionFromApi(String apiSlug, String entityId) async {
    try {
      final response = await ApiClient().authenticatedGet(
        '/$apiSlug/$entityId',
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          final key = _reactionKey(apiSlug, entityId);
          _reactions[key] = _ReactionData(
            likesCount: _asInt(data['likes_count']),
            commentsCount: _asInt(data['comments_count']),
            userReaction: data['user_reaction']?.toString(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error refreshing reaction: $e');
    }
  }

  Future<void> _toggleReaction(
    String apiSlug,
    String entityId,
    String type,
  ) async {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';

    setState(() {
      if (isLiked) {
        data.userReaction = null;
        data.likesCount = (data.likesCount > 0) ? data.likesCount - 1 : 0;
      } else {
        data.userReaction = 'like';
        data.likesCount = data.likesCount + 1;
      }
    });

    try {
      await ApiClient().authenticatedPost(
        '/$apiSlug/$entityId/reactions',
        body: {'type': type},
      );
      // Refresh to ensure counts are accurate
      await _refreshReactionFromApi(apiSlug, entityId);
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          data.userReaction = 'like';
          data.likesCount = data.likesCount + 1;
        } else {
          data.userReaction = null;
          data.likesCount = (data.likesCount > 0) ? data.likesCount - 1 : 0;
        }
      });
    }
  }

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';

    return Row(
      children: [
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                size: 18,
                color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.likesCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[600],
                  fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.commentsCount.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return ApiConfig.resolveMediaUrl(url);
        }
      }
    }
    return null;
  }

  String _buildTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} ans';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mois';
      if (diff.inDays > 0) return '${diff.inDays} jours';
      if (diff.inHours > 0) return '${diff.inHours} h';
      if (diff.inMinutes > 0) return '${diff.inMinutes} min';
      return 'Maintenant';
    } catch (_) {
      return dateStr;
    }
  }

  String _getNatureLabel(String nature) {
    const natureLabels = {
      'emploi': 'Recherche d\'emploi',
      'service': 'Recherche de service',
      'logement': 'Recherche de logement',
      'produit': 'Recherche de produit',
      'formation': 'Recherche de formation',
      'collaboration': 'Collaboration',
      'autre': 'Autre demande',
    };
    return natureLabels[nature.toLowerCase()] ?? nature;
  }

  Color _categoryColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('urgent')) return Colors.redAccent;
    if (lower.contains('emploi')) return const Color(0xFF3AAE5E);
    if (lower.contains('stage')) return const Color(0xFF2196F3);
    if (lower.contains('formation')) return const Color(0xFF9C27B0);
    if (lower.contains('immobilier')) return const Color(0xFFFF5722);
    if (lower.contains('service')) return const Color(0xFFFF9800);
    return const Color(0xFF3AAE5E);
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
