import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/search_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart' show FormationCard, FormationTag;
import 'package:myreklam/widgets/job_announcement_card.dart' show JobAnnouncementCard, JobDetailTag;
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/post_detail_full_screen.dart';
import 'package:myreklam/widgets/post_content_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? category;
  final String location;
  final double? locationLat;
  final double? locationLng;
  final String? locationCity;
  final String? locationPostalCode;
  final double radius;
  final bool allFrance;
  final String? searchType;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.category,
    required this.location,
    this.locationLat,
    this.locationLng,
    this.locationCity,
    this.locationPostalCode,
    this.radius = 0,
    this.allFrance = false,
    this.searchType,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _ReactionData {
  int likesCount = 0;
  int commentsCount = 0;
  String? userReaction;
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _selectedTab;
  bool _isLoading = true;
  List<Map<String, dynamic>> _annonceResults = [];
  List<Map<String, dynamic>> _userResults = [];
  int _annoncesTotal = 0;
  int _usersTotal = 0;
  String? _error;
  final TextEditingController _inlineSearchController = TextEditingController();

  // Reaction state management (same as dashboard)
  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) => '${apiSlug}_$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Like _asInt but returns null instead of 0 for null/invalid values
  int? _tryAsInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _seedReactionFromFeed(String apiSlug, String entityId, Map<String, dynamic> resource) {
    final key = _reactionKey(apiSlug, entityId);
    if (!_reactions.containsKey(key)) {
      final apiReaction = resource['user_reaction']?.toString();
      final userReaction = ReactionCacheService.isCached(apiSlug, entityId)
          ? ReactionCacheService.load(apiSlug, entityId)
          : apiReaction;
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      final apiCommentsCount = _asInt(resource['comments_count']);
      final cachedCommentsCount = ReactionCacheService.loadCommentsCount(apiSlug, entityId);
      _reactions[key] = _ReactionData()
        ..likesCount = (cachedCount != null && cachedCount > apiCount) ? cachedCount : apiCount
        ..commentsCount = (cachedCommentsCount != null && cachedCommentsCount > apiCommentsCount) ? cachedCommentsCount : apiCommentsCount
        ..userReaction = userReaction;
    }
  }

  Future<void> _toggleReaction(String apiSlug, String entityId, String type) async {
    final data = _getReaction(apiSlug, entityId);
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
        ReactionCacheService.save(apiSlug, entityId, respData['user_reaction']?.toString());
        ReactionCacheService.saveCount(apiSlug, entityId, data.likesCount);
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

  Widget _buildReactionBar(String apiSlug, String entityId, {bool acceptedMessages = false, Map<String, dynamic>? authorData}) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final likeColor = isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500]!;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: likeColor,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${data.likesCount}',
                style: TextStyle(color: likeColor, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey[500], size: 18),
            const SizedBox(width: 4),
            Text(
              '${data.commentsCount}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        if (acceptedMessages && authorData != null)
          GestureDetector(
            onTap: () => _navigateToConversation(authorData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAE5E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message_outlined, color: const Color(0xFF3AAE5E), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Message',
                    style: TextStyle(color: const Color(0xFF3AAE5E), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToConversation(Map<String, dynamic> authorData) {
    final userId = authorData['id']?.toString();
    final name = authorData['name']?.toString() ?? 'Utilisateur';
    if (userId != null) {
      // TODO: Navigate to conversation screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation avec $name (ID: $userId)')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.searchType ?? 'annonces';
    _inlineSearchController.text = widget.query;
    ReactionCacheService.init();
    _fetchResults();
  }

  @override
  void dispose() {
    _inlineSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both annonces and users in parallel
      await Future.wait([
        _fetchAnnonces(),
        _fetchUsers(),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _fetchAnnonces() async {
    final queryParams = <String, String>{
      'type': 'annonces',
      'per_page': '50',
    };
    final q = _inlineSearchController.text.trim();
    if (q.isNotEmpty) queryParams['q'] = q;
    if (widget.category != null) queryParams['category'] = widget.category!;
    if (widget.location.isNotEmpty) queryParams['location'] = widget.location;
    if (widget.locationLat != null) queryParams['lat'] = widget.locationLat!.toString();
    if (widget.locationLng != null) queryParams['lng'] = widget.locationLng!.toString();
    if (widget.locationCity != null) queryParams['city'] = widget.locationCity!;
    if (widget.locationPostalCode != null) queryParams['postal_code'] = widget.locationPostalCode!;
    if (widget.allFrance) queryParams['all_france'] = '1';

    final qs = Uri(queryParameters: queryParams).query;
    final resp = await ApiClient().get('/search?$qs');

    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final allItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    // Filter out posts from search results
    final items = allItems.where((item) => item['feed_type']?.toString() != 'post').toList();
    final total = data['meta']?['total'] ?? 0;

    // Seed reactions BEFORE setState to prevent _getReaction pre-populating with empty data
    for (final item in items) {
      final feedType = item['feed_type']?.toString() ?? '';
      final resource = item['resource'] is Map<String, dynamic> ? item['resource'] as Map<String, dynamic> : item;
      final apiSlug = _feedTypeToApiSlug[feedType];
      final entityId = resource['id']?.toString() ?? '';
      if (apiSlug != null && entityId.isNotEmpty) {
        _seedReactionFromFeed(apiSlug, entityId, resource);
      }
    }

    if (mounted) {
      setState(() {
        _annonceResults = items;
        _annoncesTotal = total is int ? total : int.tryParse(total.toString()) ?? 0;
      });
    }
  }

  final Map<String, String> _feedTypeToApiSlug = {
    'bon_plan': 'bon-plans',
    'job_offer': 'job-offers',
    'training': 'trainings',
    'event': 'events',
    'demande': 'demandes',
    // Note: 'post' is intentionally excluded from search results
  };

  Future<void> _fetchUsers() async {
    final queryParams = <String, String>{
      'type': 'users',
      'per_page': '50',
    };
    final q = _inlineSearchController.text.trim();
    if (q.isNotEmpty) queryParams['q'] = q;

    final qs = Uri(queryParameters: queryParams).query;
    final resp = await ApiClient().get('/search?$qs');

    final data = resp['data'] as Map<String, dynamic>? ?? {};
    final currentUserId = UserSession().id;
    if (mounted) {
      setState(() {
        final allUsers = List<Map<String, dynamic>>.from(data['users'] ?? []);
        // Filter out current user from results
        _userResults = allUsers.where((user) => user['id']?.toString() != currentUserId).toList();
        final total = data['meta']?['total'] ?? 0;
        _usersTotal = total is int ? total : int.tryParse(total.toString()) ?? 0;
      });
    }
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return ApiConfig.resolveMediaUrl(url) ?? '';
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'à l\'instant';
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
      if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
      if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
      return 'il y a ${(diff.inDays / 365).floor()} an(s)';
    } catch (_) {
      return '';
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
                builder: (context) => const ParticulierMainScreen(initialIndex: 3),
              ),
            );
          },
        ),
        title: const Text(
          'Résultats de la recherche',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Inline search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inlineSearchController,
                    onSubmitted: (_) => _fetchResults(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[600], size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('Annonces ($_annoncesTotal)', _selectedTab == 'annonces', () {
                  setState(() => _selectedTab = 'annonces');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Particuliers ($_usersTotal)', _selectedTab == 'users', () {
                  setState(() => _selectedTab = 'users');
                }),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3AAE5E)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Erreur lors de la recherche',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _fetchResults, child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _selectedTab == 'annonces'
                        ? _buildAnnoncesList()
                        : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  /* ---------- ANNONCES LIST ---------- */
  Widget _buildAnnoncesList() {
    if (_annonceResults.isEmpty) {
      return _buildEmptyState('Aucun résultat trouvé', 'Essayez de modifier vos critères de recherche.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _annonceResults.length,
      itemBuilder: (context, index) {
        final item = _annonceResults[index];
        return _buildFeedItemCard(item);
      },
    );
  }

  Widget _buildFeedItemCard(Map<String, dynamic> item) {
    // Handle both unified feed format (with feed_type/resource) and direct search results
    String feedType = item['feed_type']?.toString() ?? '';
    Map<String, dynamic> resource = item['resource'] is Map<String, dynamic> ? item['resource'] : item;

    // If no feed_type, try to infer from data structure
    if (feedType.isEmpty) {
      if (item['promo_code'] != null || item['reduction_label'] != null || item['prix_final'] != null) {
        feedType = 'bon_plan';
      } else if (item['contract_type'] != null || item['company_name'] != null || item['salary_min'] != null) {
        feedType = 'job_offer';
      } else if (item['organizer_name'] != null || (item['duration_in_h'] != null && item['training_type'] != null)) {
        feedType = 'training';
      } else if (item['start_date'] != null || item['event_date'] != null || item['coverage_area'] != null) {
        feedType = 'event';
      } else if (item['budget'] != null || item['nature'] != null) {
        feedType = 'demande';
      } else if (item['content'] != null || item['delta'] != null) {
        feedType = 'post';
      }
    }

    final apiSlug = _feedTypeToApiSlug[feedType];
    final entityId = resource['id']?.toString() ?? '';
    if (apiSlug != null && entityId.isNotEmpty) {
      _seedReactionFromFeed(apiSlug, entityId, resource);
    }

    switch (feedType) {
      case 'bon_plan':
        return _buildBonPlanCard(resource);
      case 'job_offer':
        return _buildJobOfferCard(resource);
      case 'training':
        return _buildTrainingCard(resource);
      case 'event':
        return _buildEventCard(resource);
      case 'demande':
        return _buildDemandeCard(resource);
      case 'post':
        return _buildPostCard(resource);
      default:
        return _buildGenericCard(item);
    }
  }

  // ---------- TYPE-SPECIFIC CARD BUILDERS ----------

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final bpId = bp['id']?.toString() ?? '';
    final title = bp['title']?.toString() ?? '';
    final category = bp['category']?.toString() ?? '';
    final subCategory = bp['sub_category']?.toString() ?? '';
    final type = bp['type']?.toString() ?? '';
    final merchantName = bp['available_at_name']?.toString() ?? '';
    final locationType = bp['available_location_type']?.toString() ?? '';
    final createdAt = bp['created_at']?.toString();
    final mediaFiles = (bp['media_files'] as List? ?? [])..addAll(bp['media'] as List? ?? []);
    final imageUrls = mediaFiles.where((m) => m['type'] == 'image' || m['type'] == null).map((m) {
      final url = m['url']?.toString() ?? '';
      if (url.isEmpty) return '';
      if (url.startsWith('http')) return url;
      return _resolveUrl(url);
    }).where((url) => url.isNotEmpty).toList();

    // Extract owner info from user data
    // Feed API returns nested user object; Search API returns flat author_* fields
    final user = bp['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile = user?['particulier_profile'] as Map<String, dynamic>?;
    final ownerId = user?['id']?.toString() ?? bp['author_id']?.toString();
    // display_name is computed server-side: company_name for pro, pseudo for particulier
    final ownerName = user?['display_name']?.toString() ??
        proProfile?['company_name']?.toString() ??
        proProfile?['pseudo']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        particulierProfile?['company_name']?.toString() ??
        bp['author_name']?.toString() ??
        user?['name']?.toString() ??
        'Utilisateur';
    // avatar_url is computed server-side: logo_url for pro, avatar_url for particulier
    final ownerAvatar = user?['avatar_url']?.toString() ??
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        bp['author_avatar']?.toString() ??
        user?['avatar']?.toString() ??
        '';
    final accountTypeStr = user?['account_type']?.toString() ?? bp['author_type']?.toString() ?? '';
    final isPro = accountTypeStr.toLowerCase() == 'pro';

    // Check if already favorited
    final favoris = bp['bon_plan_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    final bool initialIsFavorited = currentUserId != null &&
        favoris.any((f) => f is Map && (f['user_id']?.toString() == currentUserId || f['user']?['id']?.toString() == currentUserId));
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading) return;
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => _isLoading = true);
          try {
            if (!isFavoritedNotifier.value) {
              await ApiClient().authenticatedDelete('/bonplans/$bpId/favorite');
              if (bp['bon_plan_favorites'] is List) {
                (bp['bon_plan_favorites'] as List).removeWhere((f) => f is Map && (f['user_id']?.toString() == currentUserId || f['user']?['id']?.toString() == currentUserId));
              }
            } else {
              await ApiClient().authenticatedPost('/bonplans/$bpId/favorite');
              if (bp['bon_plan_favorites'] is! List) bp['bon_plan_favorites'] = [];
              (bp['bon_plan_favorites'] as List).add({'user_id': currentUserId, 'user': {'id': currentUserId}});
            }
            setState(() => _isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavoritedNotifier.value ? 'Ajouté aux favoris' : 'Retiré des favoris'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => _isLoading = false);
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrls.isNotEmpty) _buildImageCarousel(imageUrls),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, imageUrls.isNotEmpty ? 16 : 56, 100, 0),
                    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBonPlanDescription(bp),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        bp['original_price'] != null && bp['price'] == null
                            ? Text('${bp['original_price']}€', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E9B5B)))
                            : (type == 'Infos pouvoir d\'achat' ? const SizedBox.shrink() : Text(bp['price'] != null && bp['price'].toString().isNotEmpty ? '${bp['price']}€' : 'Gratuit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E9B5B)))),
                        if (bp['price'] != null && bp['original_price'] != null && bp['original_price'].toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('${bp['original_price']}€', style: TextStyle(fontSize: 14, color: Colors.grey[500], decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (merchantName.isNotEmpty) ...[
                          Icon(Icons.store_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(child: Text('$locationType chez $merchantName', style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                        ] else const Spacer(),
                        if (createdAt != null) ...[
                          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(_timeAgo(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
                  const SizedBox(height: 10),
                  if (bpId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Reaction bar on the left
                          Expanded(
                            child: _buildReactionBar('bon-plans', bpId, acceptedMessages: false),
                          ),
                          // Owner avatar and name on the right
                          GestureDetector(
                            onTap: () {
                              if (ownerId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isPro
                                        ? ProPublicViewScreen(userId: ownerId)
                                        : ParticulierPublicViewScreen(userId: ownerId),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: ownerAvatar.isNotEmpty
                                      ? (ownerAvatar.startsWith('http')
                                          ? NetworkImage(ownerAvatar)
                                          : NetworkImage(ApiConfig.resolveMediaUrl(ownerAvatar) ?? ''))
                                      : null,
                                  child: ownerAvatar.isEmpty
                                      ? Icon(isPro ? Icons.business : Icons.person, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ownerName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToBonPlanDetail(bp),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('VOIR LE BON PLAN'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      ),
                    ),
                  ),
                ],
              ),
              // Favorite button
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: _isLoading ? null : _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]))
                        : Icon(isFavoritedNotifier.value ? Icons.favorite : Icons.favorite_border, color: isFavoritedNotifier.value ? Colors.red : Colors.grey[600], size: 20),
                  ),
                ),
              ),
              // Type tag
              Positioned(
                top: 12,
                right: 12,
                child: _buildTypeTag('Bon Plan', const Color(0xFFFF9800), Icons.local_offer),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobOfferCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location = job['location']?.toString() ?? job['city']?.toString() ?? 'Non spécifié';
    final contract = job['contract_type']?.toString() ?? '';
    final salary = job['salary_label']?.toString() ?? job['salary']?.toString();
    final createdAt = job['created_at']?.toString();

    // Check favorite status
    final favoris = job['job_offer_favorites'] as List? ?? [];
    final bool initialIsFavorited = favoris.isNotEmpty;
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    final tags = <JobDetailTag>[
      if (location.isNotEmpty) JobDetailTag(icon: Icons.location_on_outlined, text: location),
      if (contract.isNotEmpty) JobDetailTag(icon: Icons.description_outlined, text: contract),
      if (salary != null && salary.isNotEmpty) JobDetailTag(icon: Icons.euro, text: salary, isSpecial: true),
    ];

    final user = job['user'] as Map<String, dynamic>?;
    final avatarUrl = _resolveUserAvatar(user);
    // Use resolved user name from profile (company_name for pro users)
    final companyName = _resolveUserName(user, fallback: job['company_name']?.toString() ?? 'Entreprise');

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || jobId.isEmpty) return;
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => _isLoading = true);
          try {
            if (!isFavoritedNotifier.value) {
              await ApiClient().authenticatedDelete('/job-offers/$jobId/favorite');
              if (job['job_offer_favorites'] is List) {
                (job['job_offer_favorites'] as List).removeWhere((f) => f is Map && (f['user_id']?.toString() == UserSession().id || f['user']?['id']?.toString() == UserSession().id));
              }
            } else {
              await ApiClient().authenticatedPost('/job-offers/$jobId/favorite');
              if (job['job_offer_favorites'] is! List) job['job_offer_favorites'] = [];
              (job['job_offer_favorites'] as List).add({'user_id': UserSession().id, 'user': {'id': UserSession().id}});
            }
            setState(() => _isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isFavoritedNotifier.value ? 'Ajouté aux favoris' : 'Retiré des favoris'), duration: const Duration(seconds: 2), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => _isLoading = false);
          }
        }

        return JobAnnouncementCard(
          companyLogo: avatarUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty ? description : 'Description non disponible.',
          tags: tags,
          timeAgo: _timeAgo(createdAt),
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToJobDetail(job),
          onAvatarTap: () => _navigateToUserProfile(user),
          reactionBar: jobId.isNotEmpty ? _buildReactionBar('job-offers', jobId) : null,
        );
      },
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> training) {
    final trainingId = training['id']?.toString() ?? '';
    final title = training['title']?.toString() ?? 'Formation';
    final description = _stripHtml(training['description']?.toString() ?? '');
    final provider = training['provider_name']?.toString() ?? 'Organisme';
    final duration = training['duration_in_h'];
    final durationUnit = training['duration_unit']?.toString();
    final price = training['price'];
    final addressCity = training['address_city']?.toString() ?? '';
    final createdAt = training['created_at']?.toString();

    // Check favorite status
    final favoris = training['training_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    final bool initialIsFavorited = currentUserId != null &&
        favoris.any((f) => f is Map && (f['user_id']?.toString() == currentUserId || f['user']?['id']?.toString() == currentUserId));
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    final tags = <FormationTag>[
      if (addressCity.isNotEmpty) FormationTag(icon: Icons.location_on_outlined, text: addressCity),
      if (duration != null) FormationTag(icon: Icons.timer_outlined, text: '$duration h${durationUnit != null ? ' / $durationUnit' : ''}'),
      if (price != null) FormationTag(icon: Icons.euro, text: '$price €', isSpecial: true),
    ];

    final user = training['user'] as Map<String, dynamic>?;
    final avatarUrl = _resolveUserAvatar(user, fallback: 'assets/images/Formation.png');
    final ownerName = _resolveUserName(user, fallback: provider);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoading = false;

        Future<void> _toggleFavorite() async {
          if (isLoading || trainingId.isEmpty) return;
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => isLoading = true);
          try {
            if (!isFavoritedNotifier.value) {
              await ApiClient().authenticatedDelete('/trainings/$trainingId/favorite');
              if (training['training_favorites'] is List) {
                (training['training_favorites'] as List).removeWhere((f) => f is Map && (f['user_id']?.toString() == currentUserId || f['user']?['id']?.toString() == currentUserId));
              }
            } else {
              await ApiClient().authenticatedPost('/trainings/$trainingId/favorite');
              if (training['training_favorites'] is! List) training['training_favorites'] = [];
              (training['training_favorites'] as List).add({'user_id': currentUserId, 'user': {'id': currentUserId}});
            }
            setState(() => isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isFavoritedNotifier.value ? 'Ajouté aux favoris' : 'Retiré des favoris'), duration: const Duration(seconds: 2), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => isLoading = false);
          }
        }

        return FormationCard(
          companyLogo: avatarUrl,
          companyName: ownerName,
          formationTitle: title,
          description: description.isNotEmpty ? description : 'Description non disponible.',
          tags: tags,
          timeAgo: _timeAgo(createdAt),
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToTrainingDetail(training),
          onAvatarTap: () => _navigateToUserProfile(user),
          reactionBar: trainingId.isNotEmpty ? _buildReactionBar('trainings', trainingId) : null,
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventId = event['id']?.toString() ?? '';
    final title = event['title']?.toString() ?? 'Événement';
    final createdAt = event['created_at']?.toString();
    final eventDate = event['event_date']?.toString() ?? '';
    final location = event['location']?.toString() ?? '';
    final price = event['price']?.toString();
    final mediaFiles = event['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty ? mediaFiles.first['url']?.toString() : null;

    final user = event['user'] as Map<String, dynamic>?;
    final avatarUrl = _resolveUserAvatar(user);
    final userName = _resolveUserName(user, fallback: 'Organisateur');
    final isProUser = user?['account_type']?.toString().toLowerCase() == 'pro';

    return EvenementCard(
      profileImage: avatarUrl,
      username: userName,
      userType: isProUser ? 'Professionnel' : 'Particulier',
      eventTitle: title,
      eventImage: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : 'assets/images/dashboard_particulier/Image.png',
      categories: [if (event['category']?.toString().isNotEmpty == true) event['category'].toString()],
      eventDate: eventDate.isNotEmpty ? eventDate : 'Date à définir',
      location: location.isNotEmpty ? location : 'Lieu à définir',
      timeAgo: _timeAgo(createdAt),
      price: price != null && price.isNotEmpty ? '$price €' : 'Gratuit',
      likesCount: _getReaction('events', eventId).likesCount,
      commentsCount: _getReaction('events', eventId).commentsCount,
      reactionBar: eventId.isNotEmpty ? _buildReactionBar('events', eventId) : null,
      onTapCTA: () => _navigateToEventDetail(event),
      onAvatarTap: () => _navigateToUserProfile(user),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final demandeId = demande['id']?.toString() ?? '';
    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');
    final createdAt = demande['created_at']?.toString();
    final category = demande['category']?.toString() ?? '';
    final budget = demande['budget']?.toString();

    final user = demande['user'] as Map<String, dynamic>?;
    final avatarUrl = _resolveUserAvatar(user);
    final userName = _resolveUserName(user, fallback: 'Utilisateur');

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () => _navigateToUserProfile(user),
              child: CircleAvatar(backgroundImage: avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : AssetImage(avatarUrl) as ImageProvider),
            ),
            title: GestureDetector(onTap: () => _navigateToUserProfile(user), child: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600))),
            subtitle: Text('Demande', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE6F7EF), borderRadius: BorderRadius.circular(4)),
                    child: Text(category, style: const TextStyle(fontSize: 12, color: Color(0xFF3AAE5E), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (description.isNotEmpty) Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 3, overflow: TextOverflow.ellipsis),
                if (budget != null && budget.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.euro, size: 14, color: const Color(0xFF3AAE5E)),
                      const SizedBox(width: 4),
                      Text('Budget: $budget €', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF3AAE5E))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (demandeId.isNotEmpty) _buildReactionBar('demandes', demandeId),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDemandeDetail(demande),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('VOIR LA DEMANDE'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3AAE5E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['id']?.toString() ?? '';
    final content = _stripHtml(post['content']?.toString() ?? '');
    final createdAt = post['created_at']?.toString();
    final mediaFiles = post['media_files'] as List? ?? [];

    final user = post['user'] as Map<String, dynamic>?;
    final avatarUrl = _resolveUserAvatar(user);
    final userName = _resolveUserName(user, fallback: 'Utilisateur');

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () => _navigateToUserProfile(user),
              child: CircleAvatar(backgroundImage: avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : AssetImage(avatarUrl) as ImageProvider),
            ),
            title: GestureDetector(onTap: () => _navigateToUserProfile(user), child: Text(userName, style: const TextStyle(fontWeight: FontWeight.w600))),
            subtitle: Text('Publication', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            trailing: Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ),
          if (content.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(content, style: const TextStyle(fontSize: 14))),
          if (mediaFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildImageCarousel(mediaFiles.map((m) => _resolveUrl(m['url']?.toString())).where((u) => u.isNotEmpty).toList())),
          ],
          const SizedBox(height: 12),
          if (postId.isNotEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildReactionBar('posts', postId)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGenericCard(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? item['resource']?['title']?.toString() ?? 'Sans titre';
    final createdAt = item['created_at']?.toString() ?? item['resource']?['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_timeAgo(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // ---------- HELPER METHODS ----------

  Widget _buildBonPlanDescription(Map<String, dynamic> bp) {
    final desc = _stripHtml(bp['description']?.toString() ?? '');
    if (desc.isEmpty) return const SizedBox.shrink();
    return Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis);
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrls.first,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(width: double.infinity, height: 180, color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
      ),
    );
  }

  Widget _buildTypeTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _resolveUserAvatar(Map<String, dynamic>? user, {String fallback = 'assets/images/default_avatar.png'}) {
    if (user == null) return fallback;
    // Server-computed avatar_url (logo_url for pro, avatar_url for particulier)
    final serverAvatarUrl = user['avatar_url']?.toString();
    if (serverAvatarUrl != null && serverAvatarUrl.isNotEmpty) {
      final resolved = _resolveUrl(serverAvatarUrl);
      if (resolved.isNotEmpty) return resolved;
    }
    // Fallback to nested profile data
    final proProfile = user['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
    final avatarUrl = proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user['avatar']?.toString() ??
        user['author_avatar']?.toString() ??
        '';
    if (avatarUrl.isEmpty) return fallback;
    final resolved = _resolveUrl(avatarUrl);
    return resolved.isNotEmpty ? resolved : fallback;
  }

  String _resolveUserName(Map<String, dynamic>? user, {String fallback = 'Utilisateur'}) {
    if (user == null) return fallback;
    // Server-computed display_name (company_name for pro, pseudo for particulier)
    final serverDisplayName = user['display_name']?.toString();
    if (serverDisplayName != null && serverDisplayName.isNotEmpty) {
      return serverDisplayName;
    }
    // Fallback to nested profile data and flat fields
    final proProfile = user['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
    return proProfile?['company_name']?.toString() ??
        proProfile?['first_name']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        particulierProfile?['first_name']?.toString() ??
        user['name']?.toString() ??
        user['author_name']?.toString() ??
        fallback;
  }

  void _navigateToUserProfile(Map<String, dynamic>? user) {
    if (user == null || user['id'] == null) return;
    final userId = user['id'].toString();
    final isPro = user['account_type']?.toString().toLowerCase() == 'pro';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => isPro ? ProPublicViewScreen(userId: userId) : ParticulierPublicViewScreen(userId: userId)),
    );
  }

  // ---------- TYPE-SPECIFIC NAVIGATION METHODS ----------

  Future<void> _navigateToBonPlanDetail(Map<String, dynamic> bp) async {
    final bpId = bp['id']?.toString();
    if (bpId == null || bpId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir ce bon plan')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ApiClient().authenticatedGet('/bonplans/$bpId');
      if (!mounted) return;
      Navigator.pop(context);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      final profileImage = user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '';
      final username = user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur';
      final userType = user?['account_type']?.toString() ?? 'Particulier';
      final currentUserId = UserSession().id;
      final isOwner = bp['user_id']?.toString() == currentUserId || data['user_id']?.toString() == currentUserId;
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImagesFromMedia(mediaFiles);
      final tags = <PostTag>[
        if (data['category']?.toString().isNotEmpty == true) PostTag(title: data['category'].toString(), icon: Icons.local_offer_outlined, color: Colors.orange),
        if (data['sub_category']?.toString().isNotEmpty == true) PostTag(title: data['sub_category'].toString(), icon: Icons.grid_view_outlined, color: Colors.grey),
      ];
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProPostDetailScreen(
        images: images, discount: data['reduction_label']?.toString(), avatar: profileImage.isNotEmpty ? profileImage : 'assets/images/default_avatar.png',
        name: username, userType: userType, title: data['title']?.toString() ?? 'Bon plan',
        description: _stripHtml(data['description']?.toString() ?? ''), descriptionDelta: data['description_delta'],
        tags: tags, time: _timeAgo(data['created_at']?.toString()), availability: data['available_at_name']?.toString() ?? 'Non spécifié',
        validityType: data['validity_type']?.toString() ?? 'permanent', validFrom: data['valid_from']?.toString(), validUntil: data['valid_until']?.toString(),
        deliveryInfo: _buildDeliveryInfo(data['pickup_methods']), location: _buildLocation(data['location_city'], data['location_postal_code']),
        locationCity: data['location_city']?.toString(),
        locationPostalCode: data['location_postal_code']?.toString(),
        link: data['brand_website']?.toString(), isOwner: isOwner, bonPlanId: bpId, bonPlanData: data,
        acceptMessages: data['accept_messages'] == true, authorData: user, price: data['prix_final']?.toString(),
        originalPrice: data['prix_avant_reduction']?.toString(), shippingOption: data['shipping_option']?.toString(),
        shippingCost: data['shipping_cost']?.toString(), availableLocationType: data['available_location_type']?.toString(),
        conditions: data['conditions']?.toString(),
        commentsCount: _tryAsInt(data['comments_count']),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _navigateToJobDetail(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir cette offre')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ApiClient().authenticatedGet('/job-offers/$jobId');
      if (!mounted) return;
      Navigator.pop(context);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      final companyName = data['company_name']?.toString() ?? user?['display_name']?.toString() ?? 'Entreprise';
      final companyLogo = user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final descriptionDelta = data['description_delta'];
      final contractType = data['contract_type'] is Map ? data['contract_type']['name']?.toString() : data['contract_type']?.toString();
      final workTime = data['work_time'] is Map ? data['work_time']['name']?.toString() : data['work_time']?.toString();
      final location = data['location'] is Map ? data['location']['city']?.toString() : data['location']?.toString();
      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final tags = <JobDetailTag>[
        if (contractType != null && contractType.isNotEmpty) JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime != null && workTime.isNotEmpty) JobDetailTag(icon: Icons.access_time, text: workTime),
        if (location != null && location.isNotEmpty) JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (salaryMin != null || salaryMax != null) JobDetailTag(icon: Icons.euro, text: _formatSalary(salaryMin, salaryMax), isSpecial: true),
      ];
      Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(
        jobOfferId: jobId,
        companyLogo: companyLogo,
        companyName: companyName,
        jobTitle: title,
        description: description,
        descriptionDelta: descriptionDelta,
        tags: tags,
        advantages: const [],
        timeAgo: _timeAgo(data['created_at']?.toString()),
        location: location ?? '',
        locationCity: data['location_city']?.toString(),
        locationPostalCode: data['location_postal_code']?.toString(),
        isOwner: job['user_id']?.toString() == UserSession().id,
        jobOfferData: data,
        acceptMessages: data['accept_messages'] == true,
        authorData: user,
        commentsCount: _tryAsInt(data['comments_count']),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  String _formatSalary(dynamic min, dynamic max) {
    if (min != null && max != null) return '$min - $max €';
    if (min != null) return 'À partir de $min €';
    if (max != null) return 'Jusqu\'à $max €';
    return 'Salaire non précisé';
  }

  Future<void> _navigateToTrainingDetail(Map<String, dynamic> tr) async {
    final trainingId = tr['id']?.toString();
    if (trainingId == null || trainingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir cette formation')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ApiClient().authenticatedGet('/trainings/$trainingId');
      if (!mounted) return;
      Navigator.pop(context);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      final companyName = data['organizer_name']?.toString() ?? user?['display_name']?.toString() ?? 'Organisateur';
      final companyLogo = user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '';
      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final descriptionDelta = data['description_delta'];
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImagesFromMedia(mediaFiles);
      final tags = <FormationTag>[
        if (data['category']?.toString().isNotEmpty == true) FormationTag(icon: Icons.school_outlined, text: data['category'].toString()),
      ];
      Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingDetailScreen(
        trainingId: trainingId,
        companyLogo: companyLogo,
        companyName: companyName,
        trainingTitle: title,
        description: description,
        descriptionDelta: descriptionDelta,
        images: images,
        tags: tags,
        timeAgo: _timeAgo(data['created_at']?.toString()),
        locationCity: data['location_city']?.toString(),
        locationPostalCode: data['location_postal_code']?.toString(),
        isOwner: tr['user_id']?.toString() == UserSession().id,
        trainingData: data,
        authorData: user,
        commentsCount: _tryAsInt(data['comments_count']),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _navigateToEventDetail(Map<String, dynamic> ev) async {
    final eventId = ev['id']?.toString();
    if (eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir cet événement')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ApiClient().authenticatedGet('/events/$eventId');
      if (!mounted) return;
      Navigator.pop(context);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      final avatar = user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '';
      final username = user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur';
      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final descriptionDelta = data['description_delta'];
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImagesFromMedia(mediaFiles);
      final tags = <PostTag>[
        if (data['category']?.toString().isNotEmpty == true) PostTag(title: data['category'].toString(), icon: Icons.category_outlined, color: Colors.blue),
      ];
      Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(
        eventId: eventId,
        avatar: avatar.isNotEmpty ? avatar : 'assets/images/default_avatar.png',
        username: username,
        eventTitle: title,
        description: description,
        descriptionDelta: descriptionDelta,
        images: images,
        tags: tags,
        timeAgo: _timeAgo(data['created_at']?.toString()),
        eventDate: data['start_date']?.toString() ?? data['event_date']?.toString(),
        coverageArea: data['coverage_area']?.toString() ?? data['location']?.toString(),
        locationCity: data['location_city']?.toString(),
        locationPostalCode: data['location_postal_code']?.toString(),
        isOwner: ev['user_id']?.toString() == UserSession().id,
        eventData: data,
        acceptMessages: data['accept_messages'] == true,
        authorData: user,
        commentsCount: _tryAsInt(data['comments_count']),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> demande) async {
    final demandeId = demande['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir cette demande')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ApiClient().authenticatedGet('/demandes/$demandeId');
      if (!mounted) return;
      Navigator.pop(context);
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final user = data['user'] as Map<String, dynamic>?;
      final avatar = user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '';
      final username = user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur';
      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImagesFromMedia(mediaFiles);
      final tags = <PostTag>[
        if (data['category']?.toString().isNotEmpty == true) PostTag(title: data['category'].toString(), icon: Icons.category_outlined, color: Colors.purple),
      ];
      Navigator.push(context, MaterialPageRoute(builder: (_) => DemandeDetailScreen(
        demandeId: demandeId,
        avatar: avatar.isNotEmpty ? avatar : 'assets/images/default_avatar.png',
        username: username,
        demandeTitle: title,
        description: description,
        images: images,
        tags: tags,
        timeAgo: _timeAgo(data['created_at']?.toString()),
        location: data['location_city']?.toString(),
        locationCity: data['location_city']?.toString(),
        locationPostalCode: data['location_postal_code']?.toString(),
        budgetMax: data['budget']?.toString(),
        isOwner: demande['user_id']?.toString() == UserSession().id,
        demandeData: data,
        acceptMessages: data['accept_messages'] == true,
        commentsCount: _tryAsInt(data['comments_count']),
      )));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  String _buildLocation(String? city, String? postalCode) {
    if (city != null) return postalCode != null ? '$city ($postalCode)' : city;
    return postalCode ?? '';
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

  List<String> _extractImagesFromMedia(List? mediaFiles) {
    if (mediaFiles == null) return [];
    final urls = mediaFiles.where((m) => m is Map && m['url'] != null).map((m) {
      final url = m['url'].toString();
      return _resolveUrl(url);
    }).where((u) => u.isNotEmpty).toList();
    return urls;
  }

  String _stripHtml(String html) {
    if (html.isEmpty) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /* ---------- USERS LIST ---------- */
  Widget _buildUsersList() {
    if (_userResults.isEmpty) {
      return _buildEmptyState('Aucun utilisateur trouvé', 'Essayez un autre nom ou pseudo.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'Anonyme';
    final avatar = _resolveUrl(user['avatar']?.toString());
    final accountType = user['account_type']?.toString() ?? 'particulier';
    final ville = user['ville']?.toString();
    final isFollowing = user['is_following'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: () => _navigateToUserProfile(user),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey))
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accountType == 'pro' ? const Color(0xFFFFF3E0) : const Color(0xFFE6F7EF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                accountType == 'pro' ? 'Pro' : 'Particulier',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accountType == 'pro' ? const Color(0xFFFF9800) : const Color(0xFF3AAE5E),
                ),
              ),
            ),
            if (isFollowing) ...[
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Suivi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
            if (ville != null && ville.isNotEmpty) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text(ville, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  /* ---------- SHARED WIDGETS ---------- */
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
