import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ParticulierPublicViewScreen extends StatefulWidget {
  final String? userId; // null means viewing own profile

  const ParticulierPublicViewScreen({super.key, this.userId});

  @override
  State<ParticulierPublicViewScreen> createState() =>
      _ParticulierPublicViewScreenState();
}

class _ParticulierPublicViewScreenState
    extends State<ParticulierPublicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  final _conversationService = ConversationService();

  String _selectedAnnonceFilter = 'Tout';

  // Data lists
  List<Map<String, dynamic>> _bonPlans = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingAnnonces = true;
  String? _annoncesError;

  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  List<Map<String, dynamic>> _documents = [];
  bool _isLoadingDocuments = true;
  String? _documentsError;

  bool _isLoadingProfile = true;
  Map<String, dynamic>? _profileResponse;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // Check if viewing own profile
  bool get _isViewingOwnProfile {
    final currentUserId = UserSession().id?.toString();
    final viewingUserId = widget.userId;

    if (viewingUserId == null) return true;
    return viewingUserId == currentUserId;
  }

  int get _totalCount => _bonPlans.length + _events.length + _demandes.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return m <= 1 ? 'il y a 1 minute' : 'il y a $m minutes';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return h <= 1 ? 'il y a 1 heure' : 'il y a $h heures';
      }
      if (diff.inDays < 7) {
        final d = diff.inDays;
        return d <= 1 ? 'il y a 1 jour' : 'il y a $d jours';
      }
      final w = (diff.inDays / 7).floor();
      return w <= 1 ? 'il y a 1 semaine' : 'il y a $w semaines';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = widget.userId == null
          ? await _profileService.getProfile()
          : await _profileService.getUserProfile(widget.userId!);

      if (!mounted) return;

      setState(() {
        _profileResponse = response;
        _isFollowing = response['is_following'] ?? false;
        _isLoadingProfile = false;
      });

      _loadAnnonces();
      _loadPosts();
      _loadDocuments();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadAnnonces() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnnonces = true;
      _annoncesError = null;
    });

    try {
      final currentUserId = _profileResponse?['user']?['id']?.toString();

      final results = await Future.wait([
        ApiClient().authenticatedGet('/bonplans'),
        ApiClient().authenticatedGet('/events'),
        ApiClient().authenticatedGet('/demandes'),
      ]);

      List<Map<String, dynamic>> filterByUser(
        List<Map<String, dynamic>> items,
      ) {
        if (currentUserId == null || currentUserId.isEmpty) return items;
        return items.where((m) {
          final userId =
              m['user_id']?.toString() ?? m['user']?['id']?.toString();
          return userId == currentUserId;
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

  Future<void> _loadPosts({bool showLoader = true}) async {
    if (!mounted) return;
    if (showLoader) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final response = await ApiClient().authenticatedGet('/posts');
      final data = response['data'];
      List<Map<String, dynamic>> posts = [];
      if (data is List) {
        posts = List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        posts = List<Map<String, dynamic>>.from(data['data'] as List);
      }

      final currentUserId = _profileResponse?['user']?['id']?.toString();
      if (currentUserId != null && currentUserId.isNotEmpty) {
        posts = posts.where((p) {
          final userId =
              p['user_id']?.toString() ?? p['user']?['id']?.toString();
          return userId == currentUserId;
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _myPosts = posts;
        _isLoadingPosts = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.message;
        _isLoadingPosts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postsError = 'Impossible de charger les posts.';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDocuments = true;
      _documentsError = null;
    });

    try {
      final currentUserId = _profileResponse?['user']?['id']?.toString();
      if (currentUserId == null) {
        setState(() {
          _documents = [];
          _isLoadingDocuments = false;
        });
        return;
      }

      // Fetch documents for the user - only visible ones when viewing others
      final endpoint = _isViewingOwnProfile
          ? '/candidate-documents'
          : '/candidate-documents?user_id=$currentUserId';

      final response = await ApiClient().authenticatedGet(endpoint);

      if (!mounted) return;

      if (response['success'] == true && response['data'] is List) {
        final docs = List<Map<String, dynamic>>.from(response['data']);
        // Filter only visible documents when viewing other users
        final filteredDocs = _isViewingOwnProfile
            ? docs
            : docs.where((d) => d['is_visible'] == true).toList();

        setState(() {
          _documents = filteredDocs;
          _isLoadingDocuments = false;
        });
      } else {
        setState(() {
          _documents = [];
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _documentsError = 'Erreur de chargement des documents';
        _isLoadingDocuments = false;
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

  Future<void> _toggleFollow() async {
    if (_isViewingOwnProfile || _isLoadingFollow) return;

    final targetId = widget.userId;
    if (targetId == null) return;

    setState(() => _isLoadingFollow = true);

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
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
    if (_isViewingOwnProfile) return;

    final targetIdStr = widget.userId;
    if (targetIdStr == null) return;

    final targetId = int.tryParse(targetIdStr);
    if (targetId == null) return;

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
      Navigator.pop(context);

      final profile = _profileResponse?['profile'];
      final pseudo = profile is Map ? profile['pseudo']?.toString() : null;
      final displayName = pseudo ?? 'Utilisateur';

      String? avatarUrl;
      if (profile is Map) {
        avatarUrl = profile['avatar_url']?.toString();
      }
      final resolvedAvatar = avatarUrl != null && avatarUrl.isNotEmpty
          ? (avatarUrl.startsWith('http')
                ? avatarUrl
                : ApiConfig.resolveMediaUrl(avatarUrl))
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar:
                resolvedAvatar ??
                'assets/images/dashboard_particulier/Ellipse 10.png',
            status: 'En ligne',
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer la conversation: $e')),
        );
      }
    }
  }

  Future<void> _refreshPosts() => _loadPosts(showLoader: false);

  String? _extractPostImageUrl(Map<String, dynamic> post) {
    final media = post['media_files'] as List? ?? post['media'] as List? ?? [];
    if (media.isEmpty) return null;
    final first = media.first;
    if (first is Map) {
      final url = first['url']?.toString();
      if (url != null && url.isNotEmpty) {
        if (url.startsWith('http') || url.startsWith('https')) {
          return url;
        } else {
          return '${ApiConfig.baseUrl.replaceFirst('/api', '')}$url';
        }
      }
    }
    return null;
  }

  String _buildTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final created = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return "à l'instant";
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
      final weeks = (diff.inDays / 7).floor();
      if (weeks < 4) return 'il y a $weeks sem';
      final months = (diff.inDays / 30).floor();
      return 'il y a $months mois';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profileResponse?['profile'];
    final pseudo = profile is Map ? profile['pseudo']?.toString() : null;
    final displayName = pseudo ?? 'Utilisateur';
    final avatarUrl = profile is Map ? profile['avatar_url']?.toString() : null;
    final bio = profile is Map ? profile['bio']?.toString() : null;

    // Get social links
    final socialLinks = profile is Map
        ? (profile['social_links'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    final facebookUrl = socialLinks['facebook']?.toString();
    final instagramUrl = socialLinks['instagram']?.toString();
    final youtubeUrl = socialLinks['youtube']?.toString();
    final linkedinUrl = socialLinks['linkedin']?.toString();
    final snapchatUrl = socialLinks['snapchat']?.toString();

    // Get counts from user data
    final userData = _profileResponse?['user'];
    final followersCount = userData is Map
        ? (userData['followers_count'] ?? 0)
        : 0;
    final followingCount = userData is Map
        ? (userData['following_count'] ?? 0)
        : 0;
    final postsCount = userData is Map ? (userData['posts_count'] ?? 0) : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3AAE5E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Card
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
                            color: const Color(0xFF3AAE5E),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStat('Abonnés', followersCount),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                _buildStat('Abonnements', followingCount),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                _buildStat('Posts', postsCount),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3AAE5E),
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3AAE5E),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: avatarUrl != null
                                  ? (avatarUrl.startsWith('http')
                                        ? NetworkImage(avatarUrl)
                                        : NetworkImage(
                                            ApiConfig.resolveMediaUrl(
                                                  avatarUrl,
                                                ) ??
                                                '',
                                          ))
                                  : const AssetImage(
                                      'assets/images/dashboard_particulier/Ellipse 10.png',
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Social links on the left
                      Positioned(
                        top: 75,
                        left: 30,
                        child: Column(
                          children: [
                            if (facebookUrl != null && facebookUrl.isNotEmpty)
                              _buildSocialIcon(
                                FontAwesomeIcons.facebook,
                                const Color(0xFF1877F2),
                                facebookUrl,
                              ),
                            if (instagramUrl != null && instagramUrl.isNotEmpty)
                              _buildSocialIcon(
                                FontAwesomeIcons.instagram,
                                const Color(0xFFE1306C),
                                instagramUrl,
                              ),
                            if (youtubeUrl != null && youtubeUrl.isNotEmpty)
                              _buildSocialIcon(
                                FontAwesomeIcons.youtube,
                                const Color(0xFFFF0000),
                                youtubeUrl,
                              ),
                            if (linkedinUrl != null && linkedinUrl.isNotEmpty)
                              _buildSocialIcon(
                                FontAwesomeIcons.linkedin,
                                const Color(0xFF0A66C2),
                                linkedinUrl,
                              ),
                            if (snapchatUrl != null && snapchatUrl.isNotEmpty)
                              _buildSocialIcon(
                                FontAwesomeIcons.snapchat,
                                const Color(0xFFFEE101),
                                snapchatUrl,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Message and Suivre buttons - only show when viewing other users' profiles
                  if (!_isViewingOwnProfile)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
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
                    ),
                  // TabBar
                  Container(
                    margin: const EdgeInsets.only(
                      left: 14,
                      right: 14,
                      bottom: 4,
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF8A40).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF666666),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      labelPadding: EdgeInsets.zero,
                      indicator: BoxDecoration(
                        color: const Color(0xFFEF8A40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      tabs: [
                        const Tab(
                          height: 32,
                          child: Text(
                            'Présentation',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Annonce($_totalCount)',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Post(${_myPosts.length})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Tab(
                          height: 32,
                          child: Text('Documents', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPresentationTab(),
                        _buildAnnonceTab(),
                        _buildPostTab(),
                        _buildDocumentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint('Could not launch $url: $e');
          }
        },
        icon: Icon(icon, color: color, size: 20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPresentationTab() {
    final profile = _profileResponse?['profile'];
    final bio = profile is Map ? profile['bio']?.toString() : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(-2, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Présentation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  bio?.trim().isNotEmpty == true ? bio! : 'Aucune présentation',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnonceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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

  Widget _buildPostTab() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
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
              child: Text(
                "Aucun post publié.",
                style: TextStyle(color: Colors.grey),
              ),
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

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingDocuments)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_documentsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    _documentsError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadDocuments(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          else if (_documents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                "Aucun document visible.",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: _documents
                  .map((doc) => _buildDocumentCard(doc))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final type = doc['type']?.toString() ?? 'document';
    final name = doc['original_name']?.toString() ?? 'Document';
    final isVisible = doc['is_visible'] == true;

    IconData iconData;
    Color iconColor;
    switch (type) {
      case 'cv':
        iconData = Icons.description;
        iconColor = const Color(0xFF3AAE5E);
        break;
      case 'lettre':
        iconData = Icons.mail;
        iconColor = const Color(0xFFEF8A40);
        break;
      case 'portfolio':
        iconData = Icons.folder;
        iconColor = const Color(0xFF2196F3);
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  type.toUpperCase(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (_isViewingOwnProfile)
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: isVisible ? const Color(0xFF3AAE5E) : Colors.grey,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildBonPlansList() {
    final items = _bonPlans;
    if (items.isEmpty) {
      return const Text(
        'Aucun bon plan',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((bp) => _buildBonPlanCard(bp)).toList());
  }

  Widget _buildEventsList() {
    final items = _events;
    if (items.isEmpty) {
      return const Text(
        'Aucun événement',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((ev) => _buildEventCard(ev)).toList());
  }

  Widget _buildDemandesList() {
    final items = _demandes;
    if (items.isEmpty) {
      return const Text(
        'Aucune demande',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((d) => _buildDemandeCard(d)).toList());
  }

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final title = (bp['title'] ?? '').toString();
    final category = (bp['category'] ?? '').toString();
    final subCategory = (bp['sub_category'] ?? '').toString();
    final type = (bp['type'] ?? '').toString();
    final merchantName = (bp['available_at_name'] ?? '').toString();
    final locationType = (bp['available_location_type'] ?? '').toString();
    final createdAt = bp['created_at']?.toString();
    final mediaFiles = bp['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? (mediaFiles.first is Map ? mediaFiles.first['url']?.toString() : null)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            (bp['description'] ?? '').toString(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (category.isNotEmpty)
                _buildTag(category, Icons.local_offer_outlined),
              if (subCategory.isNotEmpty)
                _buildTag(subCategory, Icons.subdirectory_arrow_right),
              if (type.isNotEmpty) _buildTag(type, Icons.label_outline),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (merchantName.isNotEmpty) ...[
                Icon(Icons.store_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$locationType chez $merchantName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (createdAt != null) ...[
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _timeAgo(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> ev) {
    final title = ev['title']?.toString() ?? '';
    final createdAt = ev['created_at']?.toString();
    final priceType = ev['price_type']?.toString() ?? 'gratuit';
    final priceAmount = ev['price_amount'];
    final coverageArea = ev['coverage_area']?.toString() ?? '';
    final eventDate = ev['event_date']?.toString();
    final startDate = ev['start_date']?.toString();
    final durationType = ev['duration_type']?.toString() ?? '';

    final mediaFiles = ev['media_files'] as List? ?? [];
    final eventImageUrl = mediaFiles.isNotEmpty
        ? (mediaFiles.first is Map ? mediaFiles.first['url'] : null)?.toString()
        : null;
    final eventImage = (eventImageUrl != null && eventImageUrl.isNotEmpty)
        ? eventImageUrl
        : 'assets/images/default_event.png';

    final categories = <String>[];
    final categoryCode = ev['category_code']?.toString() ?? '';
    final subCategoryCode = ev['sub_category_code']?.toString() ?? '';
    final formatType = ev['format_type']?.toString() ?? '';
    if (categoryCode.isNotEmpty) categories.add(categoryCode);
    if (subCategoryCode.isNotEmpty) categories.add(subCategoryCode);
    if (formatType.isNotEmpty) categories.add(formatType);

    String displayDate = '';
    if (durationType == 'one_day' && eventDate != null) {
      try {
        final date = DateTime.parse(eventDate);
        displayDate = '${date.day}/${date.month}/${date.year}';
      } catch (_) {
        displayDate = eventDate;
      }
    } else if (durationType == 'multi_day' && startDate != null) {
      try {
        final date = DateTime.parse(startDate);
        displayDate = 'À partir du ${date.day}/${date.month}/${date.year}';
      } catch (_) {
        displayDate = startDate;
      }
    } else if (durationType == 'permanent') {
      displayDate = 'Permanent';
    }

    String displayPrice = 'Gratuit';
    if (priceType == 'payant' && priceAmount != null) {
      displayPrice = '$priceAmount €';
    }

    return EvenementCard(
      profileImage: 'assets/images/profil/Rectangle 238.png',
      username: 'Mon événement',
      userType: 'Organisateur',
      eventTitle: title,
      eventImage: eventImage,
      badge: null,
      categories: categories,
      eventDate: displayDate,
      location: coverageArea.isNotEmpty ? coverageArea : 'Non spécifié',
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      price: displayPrice,
      likesCount: 0,
      commentsCount: 0,
      onTapCTA: null,
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> d) {
    final title = d['title']?.toString() ?? '';
    final description = d['description']?.toString() ?? '';
    final nature = d['nature']?.toString() ?? '';
    final location = d['location']?.toString() ?? '';
    final nationwide = d['nationwide'] == true;
    final createdAt = d['created_at']?.toString();

    final mediaFiles = d['media_files'] as List? ?? [];
    final imageUrlRaw = mediaFiles.isNotEmpty
        ? (mediaFiles.first is Map ? mediaFiles.first['url'] : null)?.toString()
        : null;

    final displayLocation = nationwide
        ? 'Toute la France'
        : (location.isNotEmpty ? location : 'Non spécifié');

    return DemandeCard(
      profileImage: 'assets/images/profil/Rectangle 238.png',
      username: 'Ma demande',
      categoryLabel: nature,
      categoryColor: const Color(0xFFEF8A40),
      title: title,
      description: description.length > 200
          ? '${description.substring(0, 200)}...'
          : description,
      location: displayLocation,
      postImage: imageUrlRaw,
      likesCount: 0,
      commentsCount: 0,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onTapCTA: null,
    );
  }

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final postText = rawPost['content']?.toString() ?? '';
    final createdAt = rawPost['created_at']?.toString();
    final imageUrl = _extractPostImageUrl(rawPost);

    final tags = <PostTag>[
      PostTag(
        title: 'Particulier',
        icon: Icons.person,
        color: const Color(0xFF3AAE5E),
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

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAnnonceFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A8143) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A8143) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
