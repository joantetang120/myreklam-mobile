import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/avatars_story.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/widgets/welcome_bonus_popup.dart';
import 'package:myreklam/screens/favorite_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';
import 'package:myreklam/screens/bons_plans_screen.dart';
import 'package:myreklam/screens/offres_emploi_screen.dart';
import 'package:myreklam/screens/formation_screen.dart';
import 'package:myreklam/screens/evenements_screen.dart';
import 'package:myreklam/screens/demandes_screen.dart';
import 'package:myreklam/screens/categories_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/add_story_screen.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/my_stories_screen.dart';
import 'package:myreklam/services/story_store.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/post_detail_full_screen.dart';
import 'package:myreklam/screens/image_preview_screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/screens/suggested_users_screen.dart';
import 'package:myreklam/screens/search_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/mys_earning_service.dart';

class ParticulierDashboardScreen extends StatefulWidget {
  const ParticulierDashboardScreen({super.key});

  @override
  State<ParticulierDashboardScreen> createState() =>
      _ParticulierDashboardScreenState();
}

class _PostAuthorInfo {
  const _PostAuthorInfo({
    required this.id,
    required this.displayName,
    required this.accountType,
    required this.avatar,
  });

  final String? id;
  final String displayName;
  final String accountType;
  final String avatar;
}

class _PostCardWidget extends StatefulWidget {
  final String postId;
  final bool isRepost;
  final _PostAuthorInfo reposter;
  final _PostAuthorInfo author;
  final String content;
  final String timeAgo;
  final List<String> mediaUrls;
  final Function(String) onToggleReaction;
  final Widget Function() buildReactionBar;
  final Widget Function(String, Color, IconData) buildTypeTag;

  const _PostCardWidget({
    required this.postId,
    required this.isRepost,
    required this.reposter,
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.mediaUrls,
    required this.onToggleReaction,
    required this.buildReactionBar,
    required this.buildTypeTag,
  });

  @override
  State<_PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<_PostCardWidget> {
  bool _isExpanded = false;
  static const int _collapsedMaxLength = 150;

  @override
  Widget build(BuildContext context) {
    final needsCollapse = widget.content.length > _collapsedMaxLength;
    final displayContent = !_isExpanded && needsCollapse
        ? '${widget.content.substring(0, _collapsedMaxLength)}...'
        : widget.content;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailFullScreen(
              author: {
                'displayName': widget.author.displayName,
                'accountType': widget.author.accountType,
                'avatar': widget.author.avatar,
              },
              content: widget.content,
              timeAgo: widget.timeAgo,
              mediaUrls: widget.mediaUrls,
              reactionBar: widget.buildReactionBar(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with author info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Repost header if applicable
                      if (widget.isRepost) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${widget.reposter.displayName} a republié ceci',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Author row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.author.id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => widget.author.accountType.toLowerCase() == 'pro'
                                        ? ProPublicViewScreen(userId: widget.author.id)
                                        : PublicProfileScreen(userId: widget.author.id),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: widget.author.avatar.startsWith('http')
                                  ? NetworkImage(widget.author.avatar)
                                        as ImageProvider
                                  : widget.author.avatar.startsWith('assets/')
                                      ? AssetImage(widget.author.avatar)
                                      : NetworkImage(ApiConfig.resolveMediaUrl(widget.author.avatar) ?? '') as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (widget.author.id != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => widget.author.accountType.toLowerCase() == 'pro'
                                              ? ProPublicViewScreen(userId: widget.author.id)
                                              : PublicProfileScreen(userId: widget.author.id),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    widget.author.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${widget.author.accountType} • ${widget.timeAgo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content text
                if (widget.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayContent,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            height: 1.4,
                          ),
                        ),
                        if (needsCollapse)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isExpanded ? '...moins' : '...more',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                // Media images
                if (widget.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMediaSection(widget.mediaUrls),
                ],
                // Reaction bar
                if (widget.postId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: widget.buildReactionBar(),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _openImagePreview(context, urls, 0),
        child: Image.network(
          urls[0],
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    // Multiple images - show grid
    return SizedBox(height: 300, child: _buildMediaGrid(urls));
  }

  void _openImagePreview(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ImagePreviewScreen(imageUrls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImagePreview(context, urls, 0),
              child: Image.network(
                urls[0],
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImagePreview(context, urls, 1),
              child: Image.network(
                urls[1],
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      );
    }

    if (urls.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImagePreview(context, urls, 0),
              child: Image.network(
                urls[0],
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImagePreview(context, urls, 1),
                    child: Image.network(
                      urls[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImagePreview(context, urls, 2),
                    child: Image.network(
                      urls[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4+ images: 2x2 grid with overflow counter
    final int remaining = urls.length - 4;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, urls, 0),
                  child: Image.network(
                    urls[0],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, urls, 1),
                  child: Image.network(
                    urls[1],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, urls, 2),
                  child: Image.network(
                    urls[2],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openImagePreview(context, urls, 3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        urls[3],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      if (remaining > 0)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionData {
  int likesCount;
  String? userReaction; // 'like' or null

  _ReactionData({this.likesCount = 0, this.userReaction});
}

class _ParticulierDashboardScreenState
    extends State<ParticulierDashboardScreen> {
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A8143), Color(0xFF3AAE5E)],
  );

  final StoryStore _storyStore = StoryStore();
  final ScrollController _scrollController = ScrollController();
  static const _defaultAvatar =
      'assets/images/dashboard_particulier/Ellipse 10.png';

  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  bool _feedHasMore = true;
  String? _feedError;
  int _feedPage = 1;
  final int _feedLimit = 50;
  final Set<String> _loadedItemIds = {}; // Track loaded items to prevent duplicates
  String? _currentUserId;

  // Reaction state per entity: key = "entityType:entityId"
  final Map<String, _ReactionData> _reactions = {};

  static const Map<String, String> _feedTypeToApiSlug = {
    'post': 'posts',
    'bon_plan': 'bon-plans',
    'job_offer': 'job-offers',
    'training': 'trainings',
    'event': 'events',
    'demande': 'demandes',
  };

  void _openStory(BuildContext context, StoryUserGroup group) {
    final storyMaps = group.stories.map((s) {
      final resolvedImage = ApiConfig.resolveMediaUrl(s.mediaUrl);
      final diff = DateTime.now().difference(s.timestamp);
      String time;
      if (diff.inMinutes < 1) {
        time = "À l'instant";
      } else if (diff.inMinutes < 60) {
        time = "il y a ${diff.inMinutes} min";
      } else if (diff.inHours < 24) {
        time = "il y a ${diff.inHours}h";
      } else {
        time = "il y a ${diff.inDays}j";
      }
      return {
        'image': resolvedImage ?? '',
        'text': s.caption,
        'time': time,
        'id': s.id,
        'views_count': s.viewsCount,
      };
    }).toList();

    final avatarUrl = ApiConfig.resolveMediaUrl(group.userAvatar);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          name: group.userName,
          avatar: avatarUrl ?? _defaultAvatar,
          stories: storyMaps,
          isOwnStory: group.isOwn,
          ownerId: group.userId,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onFeedScroll);
    _prefetchCurrentUser();
    _loadUnifiedFeed(reset: true);
    _storyStore.loadFeed();
    _loadSuggestions();
    _checkAndShowWelcomeBonus();
  }

  Future<void> _checkAndShowWelcomeBonus() async {
    // Wait for user data to be fetched first
    await _getCurrentUserId();
    
    if (!mounted) return;
    
    // Check if user has 2 My's (new user bonus)
    final mys = UserSession().mys;
    debugPrint('Checking welcome bonus - mys: $mys');
    
    if (mys >= 2) {
      // Check if popup was already shown
      final prefs = await SharedPreferences.getInstance();
      final userId = UserSession().id ?? 'unknown';
      final shownKey = 'welcome_bonus_shown_$userId';
      final alreadyShown = prefs.getBool(shownKey) ?? false;
      
      debugPrint('Welcome bonus check - alreadyShown: $alreadyShown, key: $shownKey');
      
      if (!alreadyShown && mounted) {
        // Mark as shown
        await prefs.setBool(shownKey, true);
        
        // Show popup
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WelcomeBonusPopup(
            mysAmount: 2,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      }
    }
  }

  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = false;
  final ProfileService _profileService = ProfileService();

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);
    try {
      final suggestions = await _profileService.getSuggestions();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  Future<void> _toggleFollowSuggestion(int index) async {
    final user = _suggestions[index];
    final userId = user['id'].toString();
    try {
      await _profileService.followUser(userId);
      if (mounted) {
        setState(() {
          _suggestions.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vous suivez maintenant ${user['particulier_profile']?['pseudo'] ?? user['pro_profile']?['company_name'] ?? 'cet utilisateur'}',
            ),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Widget _buildSuggestedProfiles() {
    if (_isLoadingSuggestions && _suggestions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Des profils qui pourraient t'intéresser",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuggestedUsersScreen(),
                    ),
                  ).then((_) => _loadSuggestions());
                },
                child: const Text(
                  "Voir tout",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 10),
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final user = _suggestions[index];
              final isPro = user['account_type'] == 'pro';
              final profile = isPro
                  ? user['pro_profile']
                  : user['particulier_profile'];
              final name = isPro
                  ? (profile?['company_name'] ?? 'Pro')
                  : (profile?['pseudo'] ?? 'Utilisateur');
              final avatar = profile?['avatar_url'] ?? profile?['logo_url'];
              final avatarUrl = _buildStorageUrl(avatar) ?? _defaultAvatar;

              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 10, bottom: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isPro
                                ? ProPublicViewScreen(userId: user['id'].toString())
                                : PublicProfileScreen(userId: user['id'].toString()),
                          ),
                        ).then((_) => _loadSuggestions());
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: avatarUrl.startsWith('http')
                                ? NetworkImage(avatarUrl)
                                : avatarUrl.startsWith('assets/')
                                    ? AssetImage(avatarUrl) as ImageProvider
                                    : NetworkImage(ApiConfig.resolveMediaUrl(avatarUrl) ?? '') as ImageProvider,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              isPro ? 'Pro' : 'Particulier',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () => _toggleFollowSuggestion(index),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3AAE5E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Suivre',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3AAE5E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onFeedScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleStoryEntryTap() async {
    if (_storyStore.stories.isEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddStoryScreen()),
      );
      if (result is StoryModel) {
        _storyStore.addStory(result);
      }
    } else {
      final ownGroups = _storyStore.feedNotifier.value
          .where((g) => g.isOwn)
          .toList();
      final myAvatar = ownGroups.isNotEmpty ? ownGroups.first.userAvatar : null;
      final resolvedAvatar = ApiConfig.resolveMediaUrl(myAvatar);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyStoriesScreen(
            stories: _storyStore.stories,
            userName: 'Vous',
            userAvatar: resolvedAvatar ?? _defaultAvatar,
          ),
        ),
      );
      // Refresh stories after returning from MyStoriesScreen
      _storyStore.loadMyStories();
    }
  }

  void _prefetchCurrentUser() {
    _getCurrentUserId();
  }

  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserId != null) {
      return _currentUserId;
    }
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final data = response['user'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();
      
      // Sync mys and parrainage_code to UserSession
      if (data != null) {
        final mys = data['mys'];
        final parrainageCode = data['parrainage_code'];
        if (mys != null) {
          UserSession().updateMys(mys);
        }
        if (parrainageCode != null) {
          UserSession().updateParrainageCode(parrainageCode);
        }
      }
      
      if (mounted) {
        setState(() => _currentUserId = id);
      } else {
        _currentUserId = id;
      }
      return id;
    } catch (e) {
      debugPrint('Error fetching current user ID: $e');
      return _currentUserId;
    }
  }

  Future<void> _loadUnifiedFeed({bool reset = false}) async {
    if (_isLoadingMoreFeed || (!_feedHasMore && !reset)) return;

    if (reset) {
      _feedPage = 1;
      _feedHasMore = true;
      _loadedItemIds.clear();
      setState(() {
        _isLoadingFeed = true;
        _feedError = null;
      });
    } else {
      setState(() {
        _isLoadingMoreFeed = true;
        _feedError = null;
      });
    }

    try {
      final params =
          '?page=$_feedPage&limit=$_feedLimit';
      final response = await ApiClient().get('/feed/latest$params');
      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['items'] as List);
      }

      // Deduplicate items based on feed_type and id
      final newItems = <Map<String, dynamic>>[];
      for (final item in fetched) {
        final itemId = '${item['feed_type']}_${item['id']}';
        if (!_loadedItemIds.contains(itemId)) {
          _loadedItemIds.add(itemId);
          newItems.add(item);
        }
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _feedItems = newItems;
          } else {
            _feedItems.addAll(newItems);
          }
          // Use has_more from backend response if available, otherwise fallback to length check
          final meta = data is Map<String, dynamic> ? data['meta'] as Map? : null;
          _feedHasMore = meta != null && meta['has_more'] is bool 
              ? meta['has_more'] as bool 
              : newItems.length >= _feedLimit;
          if (_feedHasMore) {
            _feedPage += 1;
          }
          if (newItems.isEmpty) {
            _feedHasMore = false;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _feedError = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedError = 'Impossible de charger le flux.');
      }
    } finally {
      if (mounted) {
        setState(() {
          if (reset) {
            _isLoadingFeed = false;
          } else {
            _isLoadingMoreFeed = false;
          }
        });
      }
    }
  }

  void _onFeedScroll() {
    if (!_scrollController.hasClients || _isLoadingMoreFeed || !_feedHasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels + 200 >= position.maxScrollExtent) {
      _loadUnifiedFeed();
    }
  }

  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Fil d'actualités"),
        const SizedBox(height: 12),
        if (_isLoadingFeed)
          _buildStatusPlaceholder(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_feedError != null)
          _buildStatusPlaceholder(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildErrorState(
                _feedError!,
                onRetry: () => _loadUnifiedFeed(reset: true),
              ),
            ),
          )
        else ...[
          ..._feedItems.map(_buildFeedItemCard),
          if (_isLoadingMoreFeed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  Widget _buildFeedItemCard(Map<String, dynamic> item) {
    final feedType = item['feed_type']?.toString() ?? '';
    final resource = item['resource'];
    if (resource is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final apiSlug = _feedTypeToApiSlug[feedType];
    final entityId = resource['id']?.toString() ?? '';
    if (apiSlug != null && entityId.isNotEmpty) {
      _seedReactionFromFeed(apiSlug, entityId, resource);
    }

    switch (feedType) {
      case 'post':
        return _buildPostCard(resource);
      case 'bon_plan':
        return _buildBonPlanFeedCard(resource);
      case 'job_offer':
        return _buildJobOfferFeedCard(resource);
      case 'training':
        return _buildTrainingFeedCard(resource);
      case 'event':
        return _buildEventFeedCard(resource);
      case 'demande':
        return _buildDemandeFeedCard(resource);
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildUnknownFeedCard(feedType),
        );
    }
  }

  Widget _buildBonPlanFeedCard(Map<String, dynamic> bp) {
    final bpId = bp['id']?.toString() ?? '';
    final title = bp['title']?.toString() ?? '';
    final category = bp['category']?.toString() ?? '';
    final subCategory = bp['sub_category']?.toString() ?? '';
    final type = bp['type']?.toString() ?? '';
    final merchantName = bp['available_at_name']?.toString() ?? '';
    final locationType = bp['available_location_type']?.toString() ?? '';
    final createdAt = bp['created_at']?.toString();
    // Support both media_files (from BonPlanController) and media (from FeedController)
    final mediaFiles = (bp['media_files'] as List? ?? [])
      ..addAll(bp['media'] as List? ?? []);
    final imageUrls = mediaFiles
        .where((m) => m['type'] == 'image' || m['type'] == null)
        .map((m) {
          final url = m['url']?.toString() ?? '';
          if (url.isEmpty) return '';
          // If URL is already complete (http/https), use it as-is
          if (url.startsWith('http')) return url;
          // Otherwise use the storage URL builder
          return _buildStorageUrl(url) ?? '';
        })
        .where((url) => url.isNotEmpty)
        .toList();
    // Check if already favorited from API data
    final bool isFavorited = bp['is_favorited'] == true || bp['is_saved'] == true || bp['user_has_favorited'] == true;

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isFavorited = isFavorited;
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || bpId.isEmpty) return;
          
          setState(() => _isLoading = true);
          
          try {
            if (_isFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete('/bon-plans/$bpId/favorite');
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/bon-plans/$bpId/favorite', body: {});
            }
            
            setState(() {
              _isFavorited = !_isFavorited;
              _isLoading = false;
            });
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            setState(() => _isLoading = false);
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour des favoris'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel at top
              if (imageUrls.isNotEmpty)
                _buildBonPlanImageCarousel(imageUrls)
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(
                      Icons.card_giftcard,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                  ),
                ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 100, 0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBonPlanDescription(bp),
              ),
              const SizedBox(height: 12),

              // Price instead of tags
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      bp['price'] != null && bp['price'].toString().isNotEmpty
                          ? '${bp['price']}€'
                          : 'Gratuit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E9B5B),
                      ),
                    ),
                    if (bp['original_price'] != null && bp['original_price'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${bp['original_price']}€',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Merchant + time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (merchantName.isNotEmpty) ...[
                      Icon(
                        Icons.store_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$locationType chez $merchantName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    if (createdAt != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _buildTimeAgo(createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 10),
              if (bpId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildReactionBar(
                    'bon-plans',
                    bpId,
                    acceptedMessages: bp['accept_messages'] == true,
                    authorData: bp['user'] as Map<String, dynamic>?,
                  ),
                ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 12),
              // CTA Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToBonPlanDetail(bp),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('VOIR LE BON PLAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Favorite button at top-left
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: _isLoading ? null : _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[600],
                        ),
                      )
                    : Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorited ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
              ),
            ),
          ),
          // Bon Plan tag at top-right
          Positioned(
            top: 12,
            right: 12,
            child: _buildTypeTag(
              'Bon Plan',
              const Color(0xFFFF9800),
              Icons.local_offer,
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildBonPlanImageCarousel(List<String> urls) {
    if (urls.length == 1) {
      return _buildBonPlanImage(urls.first);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final controller = PageController();
        int currentPage = 0;

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: controller,
                itemCount: urls.length,
                onPageChanged: (index) => setState(() => currentPage = index),
                itemBuilder: (context, index) {
                  return _buildBonPlanImage(urls[index]);
                },
              ),
            ),
            // Page indicator
            if (urls.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentPage
                          ? const Color(0xFFFF9800)
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBonPlanImage(String url) {
    return Image.network(
      url,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 220,
          color: Colors.grey[100],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, error, ___) {
        debugPrint('Image load error: $error');
        return Container(
          height: 220,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 48,
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobOfferFeedCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final companyName = job['company_name']?.toString() ?? 'Entreprise';
    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location =
        job['location']?.toString() ??
        job['city']?.toString() ??
        'Non spécifié';
    final contract = job['contract_type']?.toString() ?? '';
    final experience = job['experience_level']?.toString() ?? '';
    final salary = job['salary_label']?.toString() ?? 
        _buildJobSalaryDisplay(job) ?? 
        job['salary']?.toString();

    // Check initial favorite status
    final bool isFavorited = job['is_favorited'] == true ||
        job['is_saved'] == true ||
        job['user_has_favorited'] == true;

    final tags = <JobDetailTag>[
      // 1st: Place (location)
      if (location.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: location),
      // 2nd: Contract duration
      if (contract.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contract),
      // 3rd: Salary (depending on type)
      if (salary != null && salary.isNotEmpty)
        JobDetailTag(icon: Icons.euro, text: salary, isSpecial: true),
    ];

    final user = job['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ??
        'assets/images/dashboard_particulier/Rectangle 13.png';

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isFavorited = isFavorited;
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || jobId.isEmpty) return;

          setState(() => _isLoading = true);

          try {
            if (_isFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete('/job-offers/$jobId/favorite');
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/job-offers/$jobId/favorite', body: {});
            }

            setState(() {
              _isFavorited = !_isFavorited;
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            setState(() => _isLoading = false);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour des favoris'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return JobAnnouncementCard(
          companyLogo: companyLogoUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isFavorited: _isFavorited,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToJobDetail(job),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser = user?['account_type']?.toString().toLowerCase() == 'pro';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isProUser
                      ? ProPublicViewScreen(userId: user!['id'].toString())
                      : PublicProfileScreen(userId: user!['id'].toString()),
                ),
              );
            }
          },
          reactionBar: jobId.isNotEmpty
              ? _buildReactionBar('job-offers', jobId)
              : null,
        );
      },
    );
  }

  Widget _buildTrainingFeedCard(Map<String, dynamic> training) {
    final trainingId = training['id']?.toString() ?? '';
    final title = training['title']?.toString() ?? 'Formation';
    final description = _stripHtml(training['description']?.toString() ?? '');
    final provider = training['provider_name']?.toString() ?? 'Organisme';
    final duration = training['duration_in_h'];
    final durationUnit = training['duration_unit']?.toString();
    final price = training['price'];
    final category = training['training_category']?.toString() ?? '';
    final subCategory = training['training_sub_category']?.toString() ?? '';
    final trainingType = training['training_type']?.toString() ?? '';

    final addressCity = training['address_city']?.toString() ?? '';
    
    // Helper to extract array values
    String _extractArrayValues(dynamic field) {
      if (field is List) {
        return field.map((item) {
          if (item is Map) return item['value']?.toString() ?? item['name']?.toString() ?? '';
          return item.toString();
        }).where((s) => s.isNotEmpty).join(' · ');
      }
      return field?.toString() ?? '';
    }
    
    // Translation for training_style
    String _translateTrainingStyle(String value) {
      switch (value.trim()) {
        case 'Remote':
          return 'En ligne';
        case 'OnSite':
          return 'Présentiel';
        case 'Hybrid':
          return 'Hybride';
        default:
          return value;
      }
    }
    
    // Extract and translate training_style values
    String trainingStyleText = '';
    final trainingStyleRaw = training['training_style'];
    if (trainingStyleRaw is List) {
      final translated = trainingStyleRaw.map((item) {
        final value = item is Map ? (item['value']?.toString() ?? item.toString()) : item.toString();
        return _translateTrainingStyle(value);
      }).where((s) => s.isNotEmpty).join(' · ');
      trainingStyleText = translated;
    } else if (trainingStyleRaw != null) {
      trainingStyleText = _translateTrainingStyle(trainingStyleRaw.toString());
    }
    
    // Translation for training_public
    String _translateTrainingPublic(String value) {
      switch (value.trim()) {
        case 'AllPublic':
          return 'Tout public';
        case 'Employed':
          return 'Salarié en poste';
        case 'JobSeeker':
          return 'Demandeurs d\'emploi';
        case 'Company':
          return 'Entreprise';
        case 'Student':
          return 'Étudiant';
        default:
          return value;
      }
    }
    
    // Extract and translate training_public values
    String trainingPublicText = '';
    final trainingPublicRaw = training['training_public'];
    if (trainingPublicRaw is List) {
      final translated = trainingPublicRaw.map((item) {
        final value = item is Map ? (item['value']?.toString() ?? item.toString()) : item.toString();
        return _translateTrainingPublic(value);
      }).where((s) => s.isNotEmpty).join(' · ');
      trainingPublicText = translated;
    } else if (trainingPublicRaw != null) {
      trainingPublicText = _translateTrainingPublic(trainingPublicRaw.toString());
    }
    
    final certification = _extractArrayValues(training['certification']);
    
    // Check if CPF is in training_funding array
    final trainingFunding = training['training_funding'];
    bool hasCpf = false;
    if (trainingFunding is List) {
      hasCpf = trainingFunding.any((funding) => 
        funding.toString().toUpperCase() == 'CPF' ||
        (funding is Map && funding['type']?.toString().toUpperCase() == 'CPF')
      );
    }

    final tags = <FormationTag>[
      // 1st: Address city (location)
      if (addressCity.isNotEmpty)
        FormationTag(icon: Icons.location_on_outlined, text: addressCity),
      // 2nd: Training public (translated)
      if (trainingPublicText.isNotEmpty)
        FormationTag(icon: Icons.people_outline, text: trainingPublicText),
      // 3rd: Training style (translated)
      if (trainingStyleText.isNotEmpty)
        FormationTag(icon: Icons.style_outlined, text: trainingStyleText),
      // 4th: Certification
      if (certification.isNotEmpty)
        FormationTag(icon: Icons.verified_outlined, text: certification),
      // 5th: CPF eligibility
      if (hasCpf)
        FormationTag(icon: Icons.account_balance_wallet_outlined, text: 'Eligible CPF'),
      // 6th: Training type
      if (trainingType.isNotEmpty)
        FormationTag(icon: Icons.school_outlined, text: trainingType),
      // 7th: Duration
      if (duration != null)
        FormationTag(
          icon: Icons.timer_outlined,
          text: '$duration h${durationUnit != null ? ' / $durationUnit' : ''}',
        ),
      // 8th: Price (special/green) - LAST
      if (price != null) ...[
        () {
          final publicType = training['public_type']?.toString() ?? '';
          String priceText = '$price €';
          if (publicType == 'personne') {
            priceText += ' - Par personne';
          } else if (publicType == 'groupe') {
            priceText += ' - Par groupe';
          }
          return FormationTag(icon: Icons.euro, text: priceText, isSpecial: true);
        }(),
      ],
    ];

    final user = training['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ?? 'assets/images/Formation.png';

    // Extract owner name from profiles
    final ownerName = proProfile?['company_name']?.toString() ??
                      proProfile?['first_name']?.toString() ??
                      particulierProfile?['pseudo']?.toString() ??
                      particulierProfile?['first_name']?.toString() ??
                      training['provider_name']?.toString() ??
                      'Organisme';

    // Check initial favorite status
    final bool isFavorited = training['is_favorited'] == true ||
        training['is_saved'] == true ||
        training['user_has_favorited'] == true;

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isFavorited = isFavorited;
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || trainingId.isEmpty) return;

          setState(() => _isLoading = true);

          try {
            if (_isFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete('/trainings/$trainingId/favorite');
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/trainings/$trainingId/favorite', body: {});
            }

            setState(() {
              _isFavorited = !_isFavorited;
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            setState(() => _isLoading = false);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erreur lors de la mise à jour des favoris'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return FormationCard(
          companyLogo: companyLogoUrl,
          companyName: ownerName,
          formationTitle: title,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(training['created_at']?.toString()),
          isFavorited: _isFavorited,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToTrainingDetail(training),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser = user?['account_type']?.toString().toLowerCase() == 'pro';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isProUser
                      ? ProPublicViewScreen(userId: user!['id'].toString())
                      : PublicProfileScreen(userId: user!['id'].toString()),
                ),
              );
            }
          },
          reactionBar: trainingId.isNotEmpty
              ? _buildReactionBar('trainings', trainingId)
              : null,
        );
      },
    );
  }

  Widget _buildEventFeedCard(Map<String, dynamic> event) {
    final user = event['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;

    // Extract owner name from profiles
    final ownerName = proProfile?['company_name']?.toString() ??
                      proProfile?['first_name']?.toString() ??
                      particulierProfile?['pseudo']?.toString() ??
                      particulierProfile?['first_name']?.toString() ??
                      user?['name']?.toString() ??
                      'Organisateur';
    final eventTitle = event['title']?.toString() ?? 'Évènement';
    final eventImage =
        _extractMediaUrl(event) ?? 'assets/images/default_event.png';
    final categories = <String>[
      if (event['category_label']?.toString().isNotEmpty ?? false)
        event['category_label'].toString(),
      if (event['sub_category_label']?.toString().isNotEmpty ?? false)
        event['sub_category_label'].toString(),
    ];
    final price = _formatPrice(event['price_amount'] ?? event['price_label']);
    final coverageArea =
        event['coverage_area']?.toString() ??
        event['location']?.toString() ??
        'Non spécifié';

    final eventId = event['id']?.toString() ?? '';

    // Build tags for display
    final tags = <String>[];
    
    // Add sub_category_code if available
    final subCategoryCode = event['sub_category_code']?.toString();
    if (subCategoryCode != null && subCategoryCode.isNotEmpty) {
      tags.add(subCategoryCode);
    }
    
    // Add format_type if available
    final formatType = event['format_type']?.toString();
    if (formatType != null && formatType.isNotEmpty) {
      const formatTranslations = {
        'Présentiel': 'Présentiel',
        'En ligne': 'En ligne',
        'Hybride': 'Hybride',
      };
      tags.add(formatTranslations[formatType] ?? formatType);
    }

    return EvenementCard(
      profileImage: profileImage,
      username: ownerName,
      userType: user?['account_type']?.toString() ?? 'particulier',
      eventTitle: eventTitle,
      eventImage: eventImage,
      badge: event['status']?.toString(),
      categories: categories.isNotEmpty ? categories : ['Général'],
      eventDate: _formatEventDate(event),
      location: coverageArea,
      timeAgo: _buildTimeAgo(event['created_at']?.toString()),
      price: price,
      likesCount: _asInt(event['likes_count']),
      commentsCount: _asInt(event['comments_count']),
      onTapCTA: () => _navigateToEventDetail(event),
      tags: tags.isNotEmpty ? tags : null,
      onAvatarTap: () {
        if (user?['id'] != null) {
          final isProUser = user?['account_type']?.toString().toLowerCase() == 'pro';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isProUser
                  ? ProPublicViewScreen(userId: user!['id'].toString())
                  : PublicProfileScreen(userId: user!['id'].toString()),
            ),
          );
        }
      },
      reactionBar: eventId.isNotEmpty
          ? _buildReactionBar('events', eventId)
          : null,
    );
  }

  Widget _buildDemandeFeedCard(Map<String, dynamic> demande) {
    final user = demande['user'] as Map<String, dynamic>?;

    // Extraire le profil particulier
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;

    // Avatar : particulier_profile.avatar_url ou pro_profile.logo_url
    final avatarUrl =
        particulierProfile?['avatar_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        proProfile?['logo_url']?.toString();
    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;

    // Username : particulier_profile.pseudo ou pro_profile.company_name
    final username =
        particulierProfile?['pseudo']?.toString() ??
        proProfile?['company_name']?.toString() ??
        user?['email']?.toString() ??
        'Utilisateur';

    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');

    // Nature de la demande (Internship, SearchJob, Training, RealEstate, etc.)
    final nature = demande['nature']?.toString() ?? 'Demande';
    final categoryLabel = _getNatureLabel(nature);

    // Location
    final nationwideRaw = demande['nationwide'];
    final nationwide = nationwideRaw == true ||
        nationwideRaw == 1 ||
        nationwideRaw?.toString() == '1' ||
        nationwideRaw?.toString().toLowerCase() == 'true';
    final locationRaw = demande['location']?.toString() ?? demande['city']?.toString() ?? '';
    final location = nationwide
        ? 'Toute la France'
        : (locationRaw.isNotEmpty ? locationRaw : 'Non spécifié');

    // Media
    final postImage = _extractMediaUrl(demande);

    final demandeId = demande['id']?.toString() ?? '';

    return DemandeCard(
      profileImage: profileImage,
      username: username,
      categoryLabel: categoryLabel,
      categoryColor: _categoryColor(categoryLabel),
      title: title,
      description: description.isNotEmpty
          ? description
          : 'Description non disponible.',
      location: location,
      postImage: postImage,
      likesCount: _asInt(demande['likes_count']),
      commentsCount: _asInt(demande['comments_count']),
      timeAgo: _buildTimeAgo(demande['created_at']?.toString()),
      onTapCTA: () => _navigateToDemandeDetail(demande),
      onAvatarTap: () {
        if (user?['id'] != null) {
          final isProUser = user?['account_type']?.toString().toLowerCase() == 'pro';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isProUser
                  ? ProPublicViewScreen(userId: user!['id'].toString())
                  : PublicProfileScreen(userId: user!['id'].toString()),
            ),
          );
        }
      },
      reactionBar: demandeId.isNotEmpty
          ? _buildReactionBar(
              'demandes',
              demandeId,
              acceptedMessages: demande['accept_messages'] == true,
              authorData: demande['user'],
            )
          : null,
    );
  }

  Widget _buildUnknownFeedCard(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text('Type de contenu "$type" non supporté'),
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Gratuit';
    final text = value.toString();
    if (text.isEmpty) return 'Gratuit';
    if (text.contains('€')) return text;
    return '$text €';
  }

  String? _buildJobSalaryDisplay(Map<String, dynamic> job) {
    final min = job['salary_min'];
    final max = job['salary_max'];
    final exact = job['salary_exact'];
    final paymentType = job['salary_payment_type']?.toString(); // brut/net
    final period = job['salary_period']?.toString(); // horaire/mensuel/annuel
    
    // Build period label
    String periodLabel = '';
    if (period == 'horaire') periodLabel = '/h';
    else if (period == 'mensuel') periodLabel = '/mois';
    else if (period == 'annuel') periodLabel = '/an';
    
    // Build payment label (brut/net)
    String paymentLabel = paymentType == 'brut' ? ' brut' : (paymentType == 'net' ? ' net' : '');
    
    // If we have both min and max, show range
    if (min != null && max != null) {
      return '${min}€ - ${max}€$periodLabel$paymentLabel';
    }
    
    // If we have exact salary
    if (exact != null) {
      return '${exact}€$periodLabel$paymentLabel';
    }
    
    // If we have only min
    if (min != null) {
      return 'À partir de ${min}€$periodLabel$paymentLabel';
    }
    
    // If we have only max
    if (max != null) {
      return 'Jusqu\'à ${max}€$periodLabel$paymentLabel';
    }
    
    // Check for salary_type = selon_profil
    final salaryType = job['salary_type']?.toString();
    if (salaryType == 'selon_profil') {
      return 'Selon profil';
    }
    
    return null; // No salary info available
  }

  String _formatEventDate(Map<String, dynamic> event) {
    final durationType = event['duration_type']?.toString();
    final eventDate = event['event_date']?.toString();
    final startDate = event['start_date']?.toString();

    String formatDate(String? iso) {
      if (iso == null) return '';
      try {
        final date = DateTime.parse(iso);
        const months = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (_) {
        return iso;
      }
    }

    if (durationType == 'permanent') return 'Permanent';
    if (durationType == 'multi_day') {
      final formatted = formatDate(startDate);
      return formatted.isNotEmpty
          ? 'À partir du $formatted'
          : 'À partir de bientôt';
    }
    final formatted = formatDate(eventDate);
    return formatted.isNotEmpty ? formatted : 'Date annoncée prochainement';
  }

  String _getNatureLabel(String nature) {
    switch (nature.toLowerCase()) {
      case 'searchjob':
      case 'emploi':
        return 'Recherche d\'emploi';
      case 'internship':
      case 'stage':
        return 'Stage';
      case 'training':
      case 'formation':
        return 'Recherche de formation';
      case 'realestate':
      case 'logement':
        return 'Immobilier';
      case 'service':
      case 'servicehelp':
        return 'Service/Aide';
      case 'product':
      case 'produit':
        return 'Recherche de produit';
      case 'collaboration':
        return 'Collaboration';
      default:
        return nature;
    }
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
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _stripHtml(String text) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return text.replaceAll(exp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          // If URL is already complete (http/https), return it as-is
          if (url.startsWith('http')) return url;
          // Otherwise prepend the server base URL
          return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$url";
        }
      }
    }
    final cover = resource['cover_url']?.toString();
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('http')) return cover;
      return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$cover";
    }
    return null;
  }

  List<String> _extractAllMediaUrls(Map<String, dynamic> resource) {
    final urls = <String>[];
    final media = resource['media'] ?? resource['media_files'];
    if (media is List) {
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) {
            // If URL is already complete (http/https), use it as-is
            if (url.startsWith('http')) {
              urls.add(url);
            } else {
              // Otherwise prepend the server base URL
              urls.add("${ApiConfig.baseUrl.replaceFirst('/api', '')}$url");
            }
          }
        }
      }
    }
    if (urls.isEmpty) {
      final cover = resource['cover_url']?.toString();
      if (cover != null && cover.isNotEmpty) {
        if (cover.startsWith('http')) {
          urls.add(cover);
        } else {
          urls.add("${ApiConfig.baseUrl.replaceFirst('/api', '')}$cover");
        }
      }
    }
    return urls;
  }

  Widget _buildCarouselMediaGrid(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) {
      return Image.network(
        urls[0],
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (urls.length == 2) {
      return SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(
              child: Image.network(
                urls[0],
                fit: BoxFit.cover,
                height: 100,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Image.network(
                urls[1],
                fit: BoxFit.cover,
                height: 100,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      );
    }
    if (urls.length == 3) {
      return SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Image.network(
                urls[0],
                fit: BoxFit.cover,
                height: 100,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Image.network(
                      urls[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Image.network(
                      urls[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 4+ images: 2x2 grid with overflow counter
    final int remaining = urls.length - 4;
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Image.network(
                    urls[0],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Image.network(
                    urls[1],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Image.network(
                    urls[2],
                    fit: BoxFit.cover,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        urls[3],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      if (remaining > 0)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPlaceholder(Widget child) {
    return child;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {VoidCallback? onRetry}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Text(message, style: const TextStyle(color: Color(0xFF9E9E9E)));
  }

  Widget _buildTypeTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reaction helpers ──────────────────────────────────────────────

  String _reactionKey(String apiSlug, String entityId) => '$apiSlug:$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromFeed(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource,
  ) {
    final key = _reactionKey(apiSlug, entityId);
    if (_reactions.containsKey(key)) return;
    _reactions[key] = _ReactionData(
      likesCount: _asInt(resource['likes_count']),
      userReaction: resource['user_reaction']?.toString(),
    );
  }

  Future<void> _toggleReaction(
    String apiSlug,
    String entityId,
    String type,
  ) async {
    final data = _getReaction(apiSlug, entityId);

    // Optimistic update
    final oldReaction = data.userReaction;
    final oldLikes = data.likesCount;

    setState(() {
      if (oldReaction == type) {
        data.userReaction = null;
        if (type == 'like') data.likesCount--;
      } else {
        if (oldReaction == 'like') data.likesCount--;
        data.userReaction = type;
        if (type == 'like') data.likesCount++;
      }
    });

    try {
      final response = await ApiClient().authenticatedPost(
        '/$apiSlug/$entityId/reactions',
        body: {'type': type},
      );
      final respData = response['data'] as Map<String, dynamic>?;
      if (respData != null && mounted) {
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = respData['user_reaction']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
      if (mounted) {
        setState(() {
          data.likesCount = oldLikes;
          data.userReaction = oldReaction;
        });
      }
    }
  }

  Future<void> _repostPost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Republier cette publication'),
        content: const Text(
          'Voulez-vous partager cette publication sur votre profil ?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Republier',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient().authenticatedPost('/posts/$postId/repost', body: {});

      // Recharger le feed pour afficher le repost
      await _loadUnifiedFeed(reset: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publication republiée avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Repost error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la republication: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';

    return Row(
      children: [
        // Like
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
        // Comments
        GestureDetector(
          onTap: () => _showEntityCommentsSheet(apiSlug, entityId),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                'Commenter',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (isPost) ...[
          const SizedBox(width: 10),
          // Repost
          GestureDetector(
            onTap: () => _repostPost(entityId),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Republier',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Real comments sheet ─────────────────────────────────────────

  void _showEntityCommentsSheet(String apiSlug, String entityId) {
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    String? error;
    final commentCtrl = TextEditingController();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            // Load on first build
            if (isLoading && comments.isEmpty && error == null) {
              ApiClient()
                  .authenticatedGet('/$apiSlug/$entityId/comments?per_page=50')
                  .then((response) {
                    final data = response['data'];
                    List<Map<String, dynamic>> fetched = [];
                    if (data is Map && data['data'] is List) {
                      fetched = List<Map<String, dynamic>>.from(
                        data['data'] as List,
                      );
                    } else if (data is List) {
                      fetched = List<Map<String, dynamic>>.from(data);
                    }
                    modalSetState(() {
                      comments = fetched;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    modalSetState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  });
            }

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments',
                    body: {'body': text},
                  );
                }
                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = comments.firstWhere(
                        (c) => c['id'] == replyingToId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (parent.isNotEmpty) {
                        final replies = List<Map<String, dynamic>>.from(
                          (parent['replies'] as List?) ?? [],
                        );
                        replies.add(newComment);
                        parent['replies'] = replies;
                        parent['replies_count'] =
                            (parent['replies_count'] as int? ?? 0) + 1;
                      }
                    } else {
                      comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                }
                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();
                
                // Award 1 My for posting a comment (silently, no modal)
                try {
                  final mysResponse = await MysEarningService().awardMys(
                    actionType: 'comment',
                    referenceId: newComment?['id']?.toString(),
                  );
                  if (mysResponse['success'] == true) {
                    final newBalance = mysResponse['earning']?['new_balance'];
                    if (newBalance != null) {
                      UserSession().updateMys(newBalance);
                    }
                  }
                } catch (e) {
                  debugPrint("Error awarding My's for comment: $e");
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            }

            Future<void> toggleCommentReaction(
              Map<String, dynamic> comment,
              String type,
            ) async {
              final commentId = comment['id'];
              try {
                final response = await ApiClient().authenticatedPost(
                  '/comments/$commentId/reactions',
                  body: {'type': type},
                );
                final respData = response['data'] as Map<String, dynamic>?;
                if (respData != null) {
                  modalSetState(() {
                    comment['likes_count'] = respData['likes_count'];
                    comment['user_reaction'] = respData['user_reaction'];
                  });
                }
              } catch (e) {
                debugPrint('Comment reaction error: $e');
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);

              final newText = await showDialog<String>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (newText == null ||
                  newText.trim().isEmpty ||
                  newText == currentBody)
                return;

              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment =
                    response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  modalSetState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });

                  // Recharger le feed pour actualiser les commentaires
                  await _loadUnifiedFeed(reset: true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la modification: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(
              Map<String, dynamic> comment,
              bool isReply,
            ) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');

                // Recharger le feed pour actualiser les commentaires
                await _loadUnifiedFeed(reset: true);

                modalSetState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    comments.removeWhere((c) => c['id'] == commentId);
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Widget buildCommentItem(
              Map<String, dynamic> comment, {
              bool isReply = false,
            }) {
              final user = comment['user'] as Map<String, dynamic>? ?? {};
              final userId = user['id']?.toString(); // Convertir en String
              final email = user['email']?.toString() ?? '';
              final displayName = (userId != null && userId == _currentUserId)
                  ? 'Vous'
                  : (user['display_name']?.toString() ??
                        user['name']?.toString() ??
                        email.split('@').first);
              final body = comment['body']?.toString() ?? '';
              final createdAt = comment['created_at']?.toString();
              final likes = _asInt(comment['likes_count']);
              final userReaction = comment['user_reaction']?.toString();
              final isOwner = userId != null && userId == _currentUserId;
              print("UserId: $userId");
              print("_currentUserId: $_currentUserId");
              print("isOwner: $isOwner");
              final replies =
                  (comment['replies'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [];

              return Padding(
                padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isReply ? 14 : 18,
                          backgroundColor: const Color(0xFFE6F7EF),
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: isReply ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A8143),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: isReply ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _buildTimeAgo(createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                        showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                          ),
                                          items: [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Modifier'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Supprimer',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ).then((value) {
                                          if (value == 'edit') {
                                            editComment(comment);
                                          } else if (value == 'delete') {
                                            deleteComment(comment, isReply);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4F4F4F),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        toggleCommentReaction(comment, 'like'),
                                    child: Row(
                                      children: [
                                        Icon(
                                          userReaction == 'like'
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          size: 14,
                                          color: userReaction == 'like'
                                              ? const Color(0xFF3AAE5E)
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$likes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: userReaction == 'like'
                                                ? const Color(0xFF3AAE5E)
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isReply) ...[
                                    const SizedBox(width: 14),
                                    GestureDetector(
                                      onTap: () {
                                        modalSetState(() {
                                          replyingToId = comment['id'] as int?;
                                          replyingToName = displayName;
                                        });
                                        FocusScope.of(
                                          ctx,
                                        ).requestFocus(FocusNode());
                                      },
                                      child: Text(
                                        'Répondre',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E9B5B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Nested replies
                    if (!isReply && replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...replies.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: buildCommentItem(r, isReply: true),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Commentaires',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Comment list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? Center(
                              child: Text(
                                'Erreur: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, i) =>
                                  buildCommentItem(comments[i]),
                            ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Reply indicator
                    if (replyingToId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            Text(
                              'Répondre à $replyingToName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Écrire un commentaire...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => submitComment(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: submitComment,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3AAE5E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostsCarousel() {
    final posts = _feedItems
        .where(
          (item) =>
              item['feed_type'] == 'post' &&
              item['resource'] is Map<String, dynamic>,
        )
        .map((item) => item['resource'] as Map<String, dynamic>)
        .toList();

    if (posts.isEmpty || _isLoadingFeed) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final raw = posts[index];
              final postId = raw['id']?.toString() ?? '';
              _seedReactionFromFeed('posts', postId, raw);

              // Détecter si c'est un repost
              final isRepost = raw['original_post_id'] != null;

              // Si c'est un repost, utiliser les données du post original
              final originalPost = isRepost
                  ? (raw['original_post'] as Map<String, dynamic>? ?? {})
                  : raw;

              // L'auteur du repost (celui qui a republié)
              final reposter = _extractPostAuthorInfo(raw);

              // L'auteur du post original
              final author = isRepost
                  ? _extractPostAuthorInfo(originalPost)
                  : reposter;

              final content = originalPost['content']?.toString() ?? '';
              final createdAt = originalPost['created_at']?.toString();
              final timeAgo = _buildTimeAgo(createdAt);
              final allMediaUrls = _extractAllMediaUrls(originalPost);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de republication si c'est un repost
                    if (isRepost) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: reposter.avatar.startsWith('http')
                                ? NetworkImage(reposter.avatar) as ImageProvider
                                : AssetImage(reposter.avatar),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                children: [
                                  TextSpan(
                                    text: reposter.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: ' a republié ceci'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: author.avatar.startsWith('http')
                              ? NetworkImage(author.avatar) as ImageProvider
                              : AssetImage(author.avatar),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author.accountType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (allMediaUrls.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildCarouselMediaGrid(allMediaUrls),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: Text(
                        content.isNotEmpty ? content : 'Post sans contenu',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                          height: 1.4,
                        ),
                        maxLines: allMediaUrls.isNotEmpty ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (postId.isNotEmpty) _buildReactionBar('posts', postId),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> raw) {
    final postId = raw['id']?.toString() ?? '';

    // Détecter si c'est un repost
    final isRepost = raw['original_post_id'] != null;

    // Si c'est un repost, utiliser les données du post original
    final originalPost = isRepost
        ? (raw['original_post'] as Map<String, dynamic>? ?? {})
        : raw;

    // L'auteur du repost (celui qui a republié)
    final reposter = _extractPostAuthorInfo(raw);

    // L'auteur du post original
    final author = isRepost ? _extractPostAuthorInfo(originalPost) : reposter;

    final content = originalPost['content']?.toString() ?? '';
    final createdAt = originalPost['created_at']?.toString();
    final timeAgo = _buildTimeAgo(createdAt);
    final allMediaUrls = _extractAllMediaUrls(originalPost);

    if (postId.isNotEmpty) {
      _seedReactionFromFeed('posts', postId, raw);
    }

    return _PostCardWidget(
      postId: postId,
      isRepost: isRepost,
      reposter: reposter,
      author: author,
      content: content,
      timeAgo: timeAgo,
      mediaUrls: allMediaUrls,
      onToggleReaction: (type) => _toggleReaction('posts', postId, type),
      buildReactionBar: () => _buildReactionBar('posts', postId),
      buildTypeTag: _buildTypeTag,
    );
  }

  _PostAuthorInfo _extractPostAuthorInfo(Map<String, dynamic> raw) {
    final authorMap = (raw['author'] ?? raw['user']) as Map<String, dynamic>?;
    final authorId =
        authorMap?['id']?.toString() ??
        raw['author_id']?.toString() ??
        raw['user_id']?.toString();

    final nameCandidates = [
      authorMap?['display_name'],
      raw['display_name'],
      raw['author_display_name'],
      authorMap?['pseudo'],
      authorMap?['nomsociete'],
      _joinNames(authorMap?['first_name'], authorMap?['last_name']),
      authorMap?['name'],
      raw['author_name'],
      raw['authorName'],
    ];

    String resolvedName = 'Utilisateur';
    for (final candidate in nameCandidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        resolvedName = value;
        break;
      }
    }

    if (_currentUserId != null &&
        authorId != null &&
        authorId == _currentUserId) {
      resolvedName = 'Vous';
    }

    final rawType =
        (authorMap?['account_type'] ??
                authorMap?['profiletype'] ??
                raw['author_account_type'])
            ?.toString()
            .toLowerCase() ??
        '';
    final accountType =
        rawType.contains('pro') || rawType.contains('professionnel')
        ? 'Professionnel'
        : 'Particulier';

    final particulierProfile =
        authorMap?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = authorMap?['pro_profile'] as Map<String, dynamic>?;

    final avatarCandidates = [
      particulierProfile?['avatar_url'],
      proProfile?['avatar_url'],
      proProfile?['logo_url'],
      authorMap?['avatar_url'],
      authorMap?['avatar'],
      authorMap?['photo'],
      authorMap?['photoprofilurl'],
      raw['author_avatar'],
      raw['authorAvatar'],
    ];
    String avatar = _defaultAvatar;
    for (final candidate in avatarCandidates) {
      if (candidate == null) continue;
      final resolved = _buildStorageUrl(candidate.toString());
      if (resolved != null && resolved.isNotEmpty) {
        avatar = resolved;
        break;
      }
    }

    return _PostAuthorInfo(
      id: authorId,
      displayName: resolvedName,
      accountType: accountType,
      avatar: avatar,
    );
  }

  String? _joinNames(dynamic first, dynamic last) {
    final firstName = first?.toString().trim();
    final lastName = last?.toString().trim();
    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) {
      return null;
    }
    if (firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName?.isNotEmpty == true ? firstName : lastName;
  }

  Future<void> _navigateToBonPlanDetail(Map<String, dynamic> bp) async {
    final bonPlanId = bp['id']?.toString();
    if (bonPlanId == null || bonPlanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce bon plan')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/bonplans/$bonPlanId',
      );
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      // Use the enhanced user data with proper display name and avatar
      final profileImage =
          user?['avatar_url']?.toString() ??
          _buildStorageUrl(user?['avatar']?.toString()) ??
          _defaultAvatar;
      // Use display_name which contains company_name for pro or pseudo for particulier
      final username =
          user?['display_name']?.toString() ??
          user?['name']?.toString() ??
          'Utilisateur';
      final userType = user?['account_type']?.toString() ?? 'Particulier';
      final title = data['title']?.toString() ?? 'Bon plan';

      // Check if current user is the owner by comparing user_id from feed data
      final bonPlanUserId =
          bp['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          bonPlanUserId != null &&
          currentUserId != null &&
          bonPlanUserId == currentUserId;
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final category = data['category']?.toString() ?? '';
      final subCategory = data['sub_category']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';
      final availableAt =
          data['available_at_name']?.toString() ?? 'Non spécifié';
      final validityType = data['validity_type']?.toString() ?? 'permanent';
      final validFrom = data['valid_from']?.toString();
      final validUntil = data['valid_until']?.toString();
      final link = data['link']?.toString();
      final pickupMethods = data['pickup_methods'] as Map<String, dynamic>?;
      final deliveryInfo = _buildDeliveryInfo(pickupMethods);
      final location = data['location_search']?.toString();
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImages(mediaFiles);
      final reductionLabel = data['reduction_label']?.toString();

      final tags = <PostTag>[
        if (category.isNotEmpty)
          PostTag(
            title: category,
            icon: Icons.local_offer_outlined,
            color: Colors.orange,
          ),
        if (subCategory.isNotEmpty)
          PostTag(
            title: subCategory,
            icon: Icons.grid_view_outlined,
            color: Colors.grey,
          ),
        if (type.isNotEmpty)
          PostTag(
            title: type,
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
      ];

      if (!mounted) return;
      final acceptMessages = data['accept_messages'] == true;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProPostDetailScreen(
            images: images,
            discount: reductionLabel,
            avatar: profileImage,
            name: username,
            userType: userType,
            title: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            time: _buildTimeAgo(data['created_at']?.toString()),
            availability: availableAt,
            validityType: validityType,
            validFrom: validFrom,
            validUntil: validUntil,
            deliveryInfo: deliveryInfo,
            location: location,
            link: link,
            isOwner: isOwner,
            bonPlanId: bonPlanId,
            bonPlanData: data,
            acceptMessages: acceptMessages,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      debugPrint('Error fetching bon plan detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  String _buildDeliveryInfo(Map<String, dynamic>? pickupMethods) {
    if (pickupMethods == null) return 'Non spécifié';
    final inStore = pickupMethods['in_store'] == true;
    final delivery = pickupMethods['delivery'] == true;
    if (inStore && delivery) return 'En magasin et livraison';
    if (inStore) return 'En magasin uniquement';
    if (delivery) return 'Livraison disponible';
    return 'Non spécifié';
  }

  Future<void> _navigateToJobDetail(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir cette offre d\'emploi'),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/job-offers/$jobId');
      Navigator.pop(context); // Dismiss loading

      final data = response['data'] as Map<String, dynamic>? ?? response;

      debugPrint('JOB DETAIL API response keys: ${data.keys.toList()}');
      debugPrint(
        'JOB DETAIL description type: ${data['description']?.runtimeType}',
      );
      debugPrint('JOB DETAIL description value: ${data['description']}');
      debugPrint('JOB DETAIL description_delta: ${data['description_delta']}');
      // Check all keys that contain 'desc'
      data.forEach((key, value) {
        if (key.toLowerCase().contains('desc') ||
            key.toLowerCase().contains('delta')) {
          debugPrint(
            'JOB DETAIL key=$key type=${value?.runtimeType} value=$value',
          );
        }
      });

      // Extract job offer details
      final title = data['title']?.toString() ?? '';
      final descriptionRaw = data['description'];
      final description = descriptionRaw?.toString() ?? '';
      final descriptionDelta =
          data['description_delta'] ??
          (descriptionRaw is List ? descriptionRaw : null);
      final profileDescription = data['profile_description']?.toString();
      final companyName = data['company_name']?.toString() ?? 'Entreprise';
      final companyWebsite = data['company_website']?.toString() ?? '';
      final contractTypeRaw = data['contract_type'];
      final contractType = contractTypeRaw is Map
          ? (contractTypeRaw['name'] ?? contractTypeRaw.toString())
          : (contractTypeRaw?.toString() ?? '');
      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map
          ? (workTimeRaw['name'] ?? workTimeRaw.toString())
          : (workTimeRaw?.toString() ?? '');
      final locationRaw = data['location'];
      final location = locationRaw is Map
          ? (locationRaw['city'] ??
                locationRaw['name'] ??
                locationRaw.toString())
          : (locationRaw?.toString() ?? '');
      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString())
          : (categoryRaw?.toString() ?? '');
      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final advantagesRaw = data['advantages'];
      final advantages = advantagesRaw is List
          ? advantagesRaw
                .map(
                  (a) => a is Map ? (a['name'] ?? a.toString()) : a.toString(),
                )
                .toList()
          : <String>[];
      final createdAt = data['created_at']?.toString();
      final mediaRaw =
          data['media'] as List? ?? data['media_files'] as List? ?? [];
      final remoteWork = data['remote_work'] == true;
      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
          : educationLevelRaw?.toString();
      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
          : experienceLevelRaw?.toString();

      // Build images list
      final images = mediaRaw
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString() ?? '') ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      if (images.isEmpty) {
        images.add('assets/images/dashboard_particulier/Rectangle 13.png');
      }

      // Build tags
      final tags = <JobDetailTag>[
        if (contractType.isNotEmpty)
          JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime.isNotEmpty)
          JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (educationLevel != null && educationLevel.isNotEmpty)
          JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatJobSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      // Build advantages list
      final advantagesList = advantages
          .take(3)
          .map((a) => a.toString())
          .toList();

      // Check ownership
      final jobUserId =
          job['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          jobUserId != null &&
          currentUserId != null &&
          jobUserId == currentUserId;

      // Get user data and accept_messages
      final user = data['user'] as Map<String, dynamic>?;
      final acceptMessages = data['accept_messages'] == true;

      String companyLogo = '';
      if (user != null) {
        final particulierProfile =
            user['particulier_profile'] is Map<String, dynamic>
            ? user['particulier_profile'] as Map<String, dynamic>
            : null;
        final proProfile = user['pro_profile'] is Map<String, dynamic>
            ? user['pro_profile'] as Map<String, dynamic>
            : null;
        companyLogo =
            (particulierProfile?['avatar_url'] ??
                    proProfile?['avatar_url'] ??
                    proProfile?['logo_url'])
                ?.toString() ??
            '';
      }

      final resolvedCompanyLogo =
          _buildStorageUrl(companyLogo) ??
          'assets/images/dashboard_particulier/Rectangle 13.png';

      // Navigate to detail screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo: companyLogo,
            companyName: companyName,
            companyWebsite: companyWebsite,
            jobTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            profileDescription: profileDescription,
            tags: tags,
            postTags: <PostTag>[
              if (workTime.isNotEmpty)
                PostTag(
                  title: workTime,
                  icon: Icons.access_time,
                  color: Colors.grey,
                ),
            ],
            subtags: contractType.isNotEmpty
                ? PostTag(
                    title: contractType,
                    icon: Icons.description_outlined,
                    color: const Color(0xFF27A5FF),
                  )
                : null,
            advantages: advantagesList,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            location: location,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobId,
            jobOfferData: data,
            acceptMessages: acceptMessages,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToTrainingDetail(Map<String, dynamic> tr) async {
    final trainingId = tr['id']?.toString();
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette formation')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/trainings/$trainingId',
      );
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final companyName =
          data['company_name']?.toString() ??
          data['provider_name']?.toString() ??
          'Organisme';
      final website = data['website']?.toString();
      final trainingType = data['training_type']?.toString();
      final trainingCategory = data['training_category']?.toString();
      final trainingSubCategory = data['training_sub_category']?.toString();
      final trainingStyleRaw = data['training_style'];
      final trainingStyle = trainingStyleRaw is List
          ? trainingStyleRaw.map((e) => e.toString()).toList()
          : <String>[];
      final trainingPublicRaw = data['training_public'];
      final trainingPublic = trainingPublicRaw is List
          ? trainingPublicRaw.map((e) => e.toString()).toList()
          : <String>[];
      final requiredLevelsRaw = data['required_levels'];
      final requiredLevels = requiredLevelsRaw is List
          ? requiredLevelsRaw.map((e) => e.toString()).toList()
          : <String>[];
      final price = data['price']?.toString();
      final priceType = data['price_type']?.toString();
      final publicType = data['public_type']?.toString();
      final tempo = data['tempo']?.toString();
      final trainingFundingRaw = data['training_funding'];
      final trainingFunding = trainingFundingRaw is List
          ? trainingFundingRaw.map((e) => e.toString()).toList()
          : <String>[];
      final durationInH = data['duration_in_h'] is int
          ? data['duration_in_h'] as int
          : int.tryParse(data['duration_in_h']?.toString() ?? '');
      final durationUnit = data['duration_unit']?.toString();
      final startDate = data['start_date']?.toString();
      final endDate = data['end_date']?.toString();
      final dateToDefine = data['date_to_define'] == true;
      final addressCity = data['address_city']?.toString();
      final addressZipcode = data['address_zipcode']?.toString();
      final addressLine1 = data['address_line1']?.toString();
      final showLocation = data['show_location'] == true;
      final certificationRaw = data['certification'];
      final certification = certificationRaw is List
          ? certificationRaw.map((e) => e.toString()).toList()
          : <String>[];
      final documentFilesRaw = data['document_files'] as List? ?? [];
      final documents = documentFilesRaw
          .where((d) => d is Map)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final tags = <FormationTag>[
        if (trainingCategory != null && trainingCategory.isNotEmpty)
          FormationTag(icon: Icons.category_outlined, text: trainingCategory),
        if (trainingSubCategory != null && trainingSubCategory.isNotEmpty)
          FormationTag(
            icon: Icons.subdirectory_arrow_right,
            text: trainingSubCategory,
          ),
        if (trainingType != null && trainingType.isNotEmpty)
          FormationTag(icon: Icons.school_outlined, text: trainingType),
        if (durationInH != null)
          FormationTag(icon: Icons.timer_outlined, text: '$durationInH h'),
        if (price != null)
          FormationTag(icon: Icons.euro, text: '$price €', isSpecial: true),
      ];

      // Check ownership
      final trainingUserId =
          tr['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          trainingUserId != null &&
          currentUserId != null &&
          trainingUserId == currentUserId;

      // Extract user data for owner card
      final userData = data['user'] as Map<String, dynamic>?;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingDetailScreen(
            images: images,
            companyLogo: 'assets/images/Formation.png',
            companyName: companyName,
            trainingTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            website: website,
            trainingType: trainingType,
            trainingCategory: trainingCategory,
            trainingSubCategory: trainingSubCategory,
            trainingStyle: trainingStyle,
            trainingPublic: trainingPublic,
            requiredLevels: requiredLevels,
            price: price,
            priceType: priceType,
            publicType: publicType,
            tempo: tempo,
            trainingFunding: trainingFunding,
            durationInH: durationInH,
            durationUnit: durationUnit,
            startDate: startDate,
            endDate: endDate,
            dateToDefine: dateToDefine,
            addressCity: addressCity,
            addressZipcode: addressZipcode,
            addressLine1: addressLine1,
            showLocation: showLocation,
            certification: certification,
            documents: documents,
            isOwner: isOwner,
            trainingId: trainingId,
            trainingData: data,
            returnToListingOnEdit: false,
            authorData: userData,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToEventDetail(Map<String, dynamic> ev) async {
    final eventId = ev['id']?.toString();
    if (eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cet événement')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/events/$eventId');
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;
      debugPrint('DASHBOARD NAV: data.keys = ${data.keys.toList()}');
      debugPrint('DASHBOARD NAV: data[user] = ${data['user']}');
      debugPrint('DASHBOARD NAV: data[user] runtimeType = ${data['user']?.runtimeType}');

      final user = data['user'] as Map<String, dynamic>?;
      final profileImage = _defaultAvatar;
      final userName = user?['name']?.toString() ?? 'Organisateur';

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final categoryCode = data['category_code']?.toString();
      final subCategoryCode = data['sub_category_code']?.toString();
      final formatType = data['format_type']?.toString();
      final durationType = data['duration_type']?.toString();
      final eventDate = data['event_date']?.toString();
      final startDate = data['start_date']?.toString();
      final endDate = data['end_date']?.toString();
      final startTime = data['start_time']?.toString();
      final endTime = data['end_time']?.toString();
      final priceType = data['price_type']?.toString();
      final pricingMode = data['pricing_mode']?.toString();
      final priceAmount = data['price_amount']?.toString();
      final priceCategories =
          (data['price_categories'] as List?)
              ?.map<Map<String, dynamic>>(
                (c) => Map<String, dynamic>.from(c as Map),
              )
              .toList() ??
          <Map<String, dynamic>>[];
      final reservationMode = data['reservation_mode']?.toString();
      final coverageArea = data['coverage_area']?.toString();
      final isNationwide = data['is_nationwide'] == true;
      final organizerName = data['organizer_name']?.toString();
      final isOrganizer = data['is_organizer'] != false;
      final websiteUrl = data['website_url']?.toString();
      final landingUrl = data['landing_url']?.toString();
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final tags = <PostTag>[
        if (categoryCode != null && categoryCode.isNotEmpty)
          PostTag(
            title: categoryCode,
            icon: Icons.local_offer_outlined,
            color: Colors.green,
          ),
        if (subCategoryCode != null && subCategoryCode.isNotEmpty)
          PostTag(
            title: subCategoryCode,
            icon: Icons.grid_view_outlined,
            color: Colors.grey,
          ),
        if (formatType != null && formatType.isNotEmpty)
          PostTag(
            title: formatType,
            icon: Icons.videocam_outlined,
            color: Colors.blue,
          ),
      ];

      // Check ownership
      final eventUserId =
          ev['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          eventUserId != null &&
          currentUserId != null &&
          eventUserId == currentUserId;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: profileImage,
            username: isOrganizer
                ? userName
                : (organizerName ?? 'Organisateur'),
            userType: 'Évènement',
            eventTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            categoryCode: categoryCode,
            subCategoryCode: subCategoryCode,
            formatType: formatType,
            durationType: durationType,
            eventDate: eventDate,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            priceType: priceType,
            pricingMode: pricingMode,
            priceAmount: priceAmount,
            priceCategories: priceCategories,
            reservationMode: reservationMode,
            coverageArea: coverageArea,
            isNationwide: isNationwide,
            organizerName: organizerName,
            isOrganizer: isOrganizer,
            websiteUrl: websiteUrl,
            landingUrl: landingUrl,
            acceptMessages: acceptMessages,
            isOwner: isOwner,
            eventId: eventId,
            eventData: data,
            returnToListingOnEdit: false,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> demande) async {
    final demandeId = demande['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette demande')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/$demandeId',
      );
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final user = demande['user'] as Map<String, dynamic>?;
      final profileImage =
          _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
      final userName = user?['name']?.toString() ?? 'Utilisateur';

      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final nature = data['nature']?.toString();
      final type = data['type']?.toString();
      final urgent = data['urgent'] == true;
      final budgetMax = data['budget_max']?.toString();
      final location = data['location']?.toString();
      final nationwide = data['nationwide'] == true;
      final searchRadiusKm = data['search_radius_km'] is int
          ? data['search_radius_km'] as int
          : int.tryParse(data['search_radius_km']?.toString() ?? '');
      final showGoogleLocation = data['show_google_location'] == true;
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final categoryLabel = (type != null && type.isNotEmpty)
          ? type
          : (nature != null && nature.isNotEmpty ? nature : 'Demande');

      final tags = <PostTag>[
        PostTag(
          title: categoryLabel,
          icon: Icons.label_outline,
          color: Colors.orange,
        ),
        if (urgent)
          PostTag(
            title: 'Urgent',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        if (nationwide)
          PostTag(
            title: 'Toute la France',
            icon: Icons.public,
            color: Colors.blue,
          ),
      ];

      // Check ownership
      final demandeUserId =
          demande['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          demandeUserId != null &&
          currentUserId != null &&
          demandeUserId == currentUserId;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: profileImage,
            username: userName,
            demandeTitle: title,
            description: description,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            nature: nature,
            type: type,
            urgent: urgent,
            budgetMax: budgetMax,
            location: location,
            nationwide: nationwide,
            searchRadiusKm: searchRadiusKm,
            showGoogleLocation: showGoogleLocation,
            acceptMessages: acceptMessages,
            isOwner: isOwner,
            demandeId: demandeId,
            demandeData: data,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  String _formatJobSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Salaire non spécifié';
  }

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME':
        return 'Temps plein';
      case 'PART_TIME':
        return 'Temps partiel';
      case 'INTERIM':
        return 'Intérim';
      case 'FREELANCE':
        return 'Freelance';
      case 'ALTERNANCE':
        return 'Alternance';
      case 'STAGE':
        return 'Stage';
      default:
        return val;
    }
  }

  List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return ['assets/images/details_bon_plans/Rectangle 35.png'];
    }
    final images = mediaFiles
        .where((m) => m is Map && m['url'] != null)
        .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    // Ensure we always have at least one image
    if (images.isEmpty) {
      return ['assets/images/details_bon_plans/Rectangle 35.png'];
    }
    return images;
  }

  Widget _buildBonPlanDescription(Map<String, dynamic> item) {
    final descriptionDelta = item['description_delta'];
    final descriptionPlain = item['description'] ?? '';

    if (descriptionDelta != null) {
      try {
        List opsList;

        if (descriptionDelta is List) {
          opsList = descriptionDelta;
        } else if (descriptionDelta is Map && descriptionDelta['ops'] is List) {
          opsList = descriptionDelta['ops'] as List;
        } else if (descriptionDelta is String && descriptionDelta.isNotEmpty) {
          String jsonString = descriptionDelta;
          jsonString = jsonString.replaceAllMapped(
            RegExp(r'(\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
            (match) => '${match.group(1)}"${match.group(2)}":',
          );
          jsonString = jsonString.replaceAllMapped(
            RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s]*?)(\s*[,\}\]])'),
            (match) {
              final value = match.group(1)!.trim();
              if (value == 'true' || value == 'false' || value == 'null') {
                return ': $value${match.group(2)}';
              }
              return ': "$value"${match.group(2)}';
            },
          );
          dynamic rawData = jsonDecode(jsonString);
          if (rawData is String) rawData = jsonDecode(rawData);
          if (rawData is List) {
            opsList = rawData;
          } else if (rawData is Map && rawData['ops'] is List) {
            opsList = rawData['ops'] as List;
          } else {
            throw Exception('Unknown delta format: ${rawData.runtimeType}');
          }
        } else {
          throw Exception('Unsupported type: ${descriptionDelta.runtimeType}');
        }

        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isEmpty) throw Exception('No valid ops');

        final lastInsert = filteredOps.last['insert'];
        if (lastInsert is String && !lastInsert.endsWith('\n')) {
          filteredOps.add({'insert': '\n'});
        }

        final doc = quill.Document.fromJson(filteredOps);
        final controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        return SizedBox(
          height: 60,
          child: quill.QuillEditor.basic(
            controller: controller,
            config: quill.QuillEditorConfig(
              padding: EdgeInsets.zero,
              onLaunchUrl: (url) async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error rendering rich text: $e');
      }
    }

    return Text(
      _stripHtml(descriptionPlain.toString()),
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBonPlanTag(String text, IconData icon) {
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

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/$url';
  }

  Future<void> _refreshFeed() {
    return _loadUnifiedFeed(reset: true);
  }

  Widget _buildNotifBubble() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE6F7EF),
          border: Border.all(color: const Color(0xFF2A8143), width: 1.5),
        ),
        child: const Icon(Icons.search, color: Color(0xFF2A8143), size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              snap: false,
              backgroundColor: const Color(0xFF2A8143),
              automaticallyImplyLeading: false,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double appBarHeight = constraints.maxHeight;
                  final double expandRatio =
                      ((appBarHeight - kToolbarHeight) / (120 - kToolbarHeight))
                          .clamp(0.0, 1.0);
                  final bool isCollapsed = expandRatio < 0.1;

                  return FlexibleSpaceBar(
                    background: Container(
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
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                "assets/images/LOGO VERT.png",
                                width: 130,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    titlePadding: EdgeInsets.zero,
                    title: isCollapsed
                        ? SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  _buildNotifBubble(),
                                ],
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700)),
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
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildNotifBubble(),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  //story
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ValueListenableBuilder<List<StoryUserGroup>>(
                      valueListenable: _storyStore.feedNotifier,
                      builder: (_, feedGroups, __) {
                        final ownGroup = feedGroups
                            .where((g) => g.isOwn)
                            .toList();
                        final otherGroups = feedGroups
                            .where((g) => !g.isOwn)
                            .toList();
                        final hasOwnStories =
                            ownGroup.isNotEmpty &&
                            ownGroup.first.stories.isNotEmpty;

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // "Votre story" entry
                                GestureDetector(
                                  onTap: _handleStoryEntryTap,
                                  child: Column(
                                    spacing: 5,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          GestureDetector(
                                            onTap: _handleStoryEntryTap,
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                hasOwnStories ? 2 : 10,
                                              ),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFFE6F7EF),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF3AAE5E,
                                                  ),
                                                  width: hasOwnStories
                                                      ? 2.5
                                                      : 1,
                                                ),
                                              ),
                                              child: hasOwnStories
                                                  ? CircleAvatar(
                                                      radius: 22,
                                                      backgroundImage:
                                                          (ownGroup
                                                                      .first
                                                                      .userAvatar !=
                                                                  null &&
                                                              ownGroup
                                                                  .first
                                                                  .userAvatar!
                                                                  .isNotEmpty)
                                                          ? NetworkImage(
                                                                  ApiConfig.resolveMediaUrl(
                                                                    ownGroup
                                                                        .first
                                                                        .userAvatar,
                                                                  )!,
                                                                )
                                                                as ImageProvider
                                                          : const AssetImage(
                                                              _defaultAvatar,
                                                            ),
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.add,
                                                        color: Color(
                                                          0xFF3AAE5E,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          if (hasOwnStories)
                                            Positioned(
                                              bottom: -2,
                                              right: -2,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const AddStoryScreen(),
                                                        ),
                                                      );
                                                  if (result is StoryModel) {
                                                    _storyStore.addStory(
                                                      result,
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF3AAE5E,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const Text(
                                        "Votre story",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Other users' stories from API feed
                                ...otherGroups.map(
                                  (group) => Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: AvatarsStory(
                                      name: group.userName.split(' ').first,
                                      imageName:
                                          ApiConfig.resolveMediaUrl(
                                            group.userAvatar,
                                          ) ??
                                          _defaultAvatar,
                                      onTap: () => _openStory(context, group),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ), // space on sides
                    child: Container(
                      height: 1, // thin line
                      color: Colors.grey[300], // light gray
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Catégories"),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                          child: const Text("voir tout"),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          CategoriesIcon(
                            title: "Bons plans",
                            iconColor: const Color.fromARGB(255, 252, 116, 37),
                            bgColor: Color(0xFFFFE0B2).withOpacity(0.2),
                            icon: Icons.card_giftcard_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BonsPlansScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Offre d'emploi",
                            iconColor: Colors.lightBlueAccent,
                            bgColor: Color(0xFFB3E5FC).withOpacity(0.2),
                            iconAsset: 'assets/images/offres.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OffresEmploiScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Formations",
                            iconColor: Colors.purple,
                            bgColor: Color(0xFFE1BEE7).withOpacity(0.1),
                            iconAsset: 'assets/images/Formation.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FormationScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Evenements",
                            iconColor: Colors.green,
                            bgColor: Color(0xFFE6F7EF).withOpacity(0.5),
                            icon: Icons.event_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EvenementsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Demandes",
                            iconColor: const Color.fromARGB(255, 252, 231, 49),
                            bgColor: Color.fromARGB(
                              255,
                              255,
                              250,
                              178,
                            ).withOpacity(0.2),
                            icon: Icons.chat_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DemandesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSuggestedProfiles(),

                  _buildFeedSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
