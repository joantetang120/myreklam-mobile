import 'package:flutter/material.dart';
// Bouton partager masqué
// import 'package:myreklam/services/share_service.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/bon_plan_carousel.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/report_reason_dialog.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_bon_plan_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/utils/subscription_helper.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
// Bouton partager masqué
// import 'package:share_plus/share_plus.dart';

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction; // 'like' or null

  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userReaction,
  });
}

class _ExpandableDescriptionStateful extends StatefulWidget {
  final String text;

  const _ExpandableDescriptionStateful({required this.text});

  @override
  State<_ExpandableDescriptionStateful> createState() =>
      _ExpandableDescriptionStatefulState();
}

class _ExpandableDescriptionStatefulState
    extends State<_ExpandableDescriptionStateful> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text;

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedCrossFade(
        firstChild: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: text.length > 100
                    ? '${text.substring(0, 100)}... '
                    : text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              if (text.length > 100)
                const TextSpan(
                  text: 'voir plus',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        secondChild: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            height: 1.4,
          ),
        ),
        crossFadeState: isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class ProPostDetailScreen extends StatefulWidget {
  final List<String> images;
  final String? discount;
  final String avatar;
  final String name;
  final String userType;
  final String title;
  final String description;
  final dynamic descriptionDelta;
  final List<PostTag> tags;
  final String time;
  final String? price;
  final String? originalPrice;
  final String availability;
  final String validityType;
  final String? validFrom;
  final String? validUntil;
  final String deliveryInfo;
  final String? location;
  final String? locationCity;
  final String? locationPostalCode;
  final String? link;
  final String? promo_code;
  final bool isOwner;
  final String? bonPlanId;
  final Map<String, dynamic>? bonPlanData;
  final bool acceptMessages;
  final Map<String, dynamic>? authorData;
  final String? shippingOption;
  final String? shippingCost;
  final String? availableLocationType;
  final String? conditions;
  final int? commentsCount;

  const ProPostDetailScreen({
    super.key,
    this.images = const [],
    this.discount,
    required this.avatar,
    required this.name,
    required this.userType,
    required this.title,
    this.description = '',
    this.descriptionDelta,
    this.tags = const [],
    this.time = '',
    this.price,
    this.originalPrice,
    this.availability = 'Non spécifié',
    this.validityType = 'Offre permanente',
    this.validFrom,
    this.validUntil,
    this.deliveryInfo = 'Non spécifié',
    this.location,
    this.locationCity,
    this.locationPostalCode,
    this.link,
    this.promo_code,
    this.isOwner = false,
    this.bonPlanId,
    this.bonPlanData,
    this.acceptMessages = false,
    this.authorData,
    this.shippingOption,
    this.shippingCost,
    this.availableLocationType,
    this.conditions,
    this.commentsCount,
  });

  @override
  State<ProPostDetailScreen> createState() => _ProPostDetailScreenState();
}

class _ProPostDetailScreenState extends State<ProPostDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  int? _localCommentsCount;
  List<Map<String, dynamic>> _relatedBonPlans = [];
  bool _isLoadingRelated = false;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  String? _currentUserId;

  /// Check if edit option should be shown
  /// Hide edit if: 1) post is older than 2 hours OR 2) people have favorited it
  bool get _canEdit {
    if (!widget.isOwner) return false;

    final data = widget.bonPlanData;
    if (data == null) return true; // Allow edit if no data (fallback)

    // Check if post is older than 2 hours
    final createdAtStr = data['created_at']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt != null) {
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
        if (createdAt.isBefore(twoHoursAgo)) {
          return false; // Post is older than 2 hours
        }
      }
    }

    // Check if people have favorited this post
    final favoritesCount = data['favorites_count'] ?? 0;
    if (favoritesCount is int && favoritesCount > 0) {
      return false; // People have favorited
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _localCommentsCount = widget.commentsCount;
    _checkFavoriteStatus();
    _fetchComments();
    _fetchRelatedBonPlans();
    _checkFollowStatus();
  }

  void _checkFavoriteStatus() async {
    debugPrint('=== CHECK FAVORITE STATUS ===');
    debugPrint(
      'bonPlanData is_favorited: ${widget.bonPlanData?['is_favorited']}',
    );

    // First set from passed data if available
    if (widget.bonPlanData != null &&
        widget.bonPlanData!['is_favorited'] != null) {
      setState(() {
        _isFavorite = widget.bonPlanData!['is_favorited'] == true;
      });
      debugPrint('Set from bonPlanData: $_isFavorite');
      return;
    }

    // Otherwise fetch from API
    if (widget.bonPlanId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bonplans/${widget.bonPlanId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFavorited = data['data']?['is_favorited'] == true;
        setState(() {
          _isFavorite = isFavorited;
        });
        debugPrint('Fetched from API - isFavorited: $isFavorited');
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (widget.isOwner || widget.authorData == null) return;

    final authorId = widget.authorData!['id']?.toString();
    if (authorId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$authorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_following'] == true) {
          setState(() => _isFollowing = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.isOwner || widget.authorData == null) return;

    final authorId = widget.authorData!['id']?.toString();
    if (authorId == null) return;

    setState(() => _isLoadingFollow = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFollowing) {
        // Unfollow
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/unfollow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous ne suivez plus cet utilisateur'),
            ),
          );
        }
      } else {
        // Follow
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/follow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous suivez maintenant cet utilisateur'),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoadingFollow = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.bonPlanId == null) return;

    setState(() => _isLoadingFavorite = true);
    debugPrint('=== TOGGLE FAVORITE ===');
    debugPrint('bonPlanId: ${widget.bonPlanId}');
    debugPrint('Current _isFavorite: $_isFavorite');

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFavorite) {
        // Remove from favorites
        final url =
            '${ApiConfig.baseUrl}/bonplans/${widget.bonPlanId}/favorite';
        debugPrint('DELETE $url');
        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() => _isFavorite = false);
          debugPrint('Removed from favorites - _isFavorite now: $_isFavorite');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
        }
      } else {
        // Add to favorites
        final url =
            '${ApiConfig.baseUrl}/bonplans/${widget.bonPlanId}/favorite';
        debugPrint('POST $url');
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => _isFavorite = true);
          debugPrint('Added to favorites - _isFavorite now: $_isFavorite');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoadingFavorite = false);
      debugPrint('Final _isFavorite: $_isFavorite');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchComments() async {
    if (widget.bonPlanId == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final response = await ApiClient().authenticatedGet(
        '/bon-plans/${widget.bonPlanId}/comments?per_page=50',
      );

      final data = response['data'];
      if (data != null) {
        List<Map<String, dynamic>> fetched = [];
        if (data is List) {
          fetched = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          fetched = List<Map<String, dynamic>>.from(data['data']);
        }
        debugPrint('=== COMMENTS FETCHED: ${fetched.length} ===');
        setState(() {
          _comments = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _fetchRelatedBonPlans() async {
    setState(() => _isLoadingRelated = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      // Fetch latest bon plans excluding current one
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/feed/latest?type=bon_plan&per_type_limit=4',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = data['data']['items'] as List? ?? [];
          // Extract resource data and filter out current bon plan
          final filtered = items
              .map((item) {
                dynamic resourceData = item['resource'];
                Map<String, dynamic> resource;

                // Handle case where resource is a JSON string instead of Map
                if (resourceData is String) {
                  resource = jsonDecode(resourceData) as Map<String, dynamic>;
                } else if (resourceData is Map) {
                  resource = Map<String, dynamic>.from(resourceData);
                } else {
                  resource = {};
                }

                // Ensure id is available at top level for filtering
                resource['id'] = item['id'];
                // Preserve media data from the feed item (not in resource)
                if (item['media'] != null) {
                  resource['media'] = item['media'];
                }
                // Preserve reaction data from feed item (not in resource)
                if (item['user_reaction'] != null) {
                  resource['user_reaction'] = item['user_reaction'];
                }
                if (item['likes_count'] != null) {
                  resource['likes_count'] = item['likes_count'];
                }
                if (item['comments_count'] != null) {
                  resource['comments_count'] = item['comments_count'];
                }
                return resource;
              })
              .where((bonPlan) => bonPlan['id'].toString() != widget.bonPlanId)
              .take(3)
              .toList();
          setState(() {
            _relatedBonPlans = filtered;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching related bon plans: $e');
    } finally {
      setState(() => _isLoadingRelated = false);
    }
  }

  void _navigateToUserProfile() {
    if (widget.authorData == null) return;
    // TODO: Navigate to user profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil utilisateur - à implémenter')),
    );
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/$url';
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Widget _buildBonPlanImageCarousel(List<String> urls) {
    if (urls.length == 1) {
      return _buildBonPlanImage(urls.first);
    }

    return BonPlanCarousel(urls: urls);
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
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonPlanDescription(Map<String, dynamic> item) {
    final descriptionPlain = item['description']?.toString() ?? '';
    final cleanText = _stripHtml(descriptionPlain);

    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }

    return _ExpandableDescription(text: cleanText);
  }

  // Expandable description widget with "voir plus" functionality
  Widget _ExpandableDescription({required String text}) {
    return _ExpandableDescriptionStateful(text: text);
  }

  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) =>
      '${apiSlug}_$entityId';

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

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
    final apiUserReaction = resource['user_reaction']?.toString();
    final apiLikesCount = _asInt(resource['likes_count']);
    final apiCommentsCount = _asInt(resource['comments_count']);

    if (!_reactions.containsKey(key)) {
      // First time - create with API values
      _reactions[key] = _ReactionData(
        likesCount: apiLikesCount,
        commentsCount: apiCommentsCount,
        userReaction: apiUserReaction,
      );
    } else {
      // Already exists - update user_reaction from API if we don't have one
      final current = _reactions[key]!;
      if (current.userReaction == null && apiUserReaction != null) {
        current.userReaction = apiUserReaction;
      }
      // Use max of API count and current (don't let stale API overwrite local)
      if (apiLikesCount > current.likesCount) {
        current.likesCount = apiLikesCount;
      }
      if (apiCommentsCount > current.commentsCount) {
        current.commentsCount = apiCommentsCount;
      }
    }
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

  String _crudSlug(String reactionSlug) {
    const map = {'bon-plans': 'bonplans'};
    return map[reactionSlug] ?? reactionSlug;
  }

  Future<void> _refreshReactionFromApi(String apiSlug, String entityId) async {
    try {
      final response = await ApiClient().authenticatedGet(
        '/${_crudSlug(apiSlug)}/$entityId',
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
        final newReaction = respData['user_reaction']?.toString();
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = newReaction;
        });
        ReactionCacheService.save(apiSlug, entityId, newReaction);
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

  void _showEntityCommentsSheet(String apiSlug, String entityId) async {
    await _getCurrentUserId();
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
              if (!SubscriptionHelper.canAccessFeature(
                ProFeature.commentAndReact,
              )) {
                if (context.mounted) {
                  SubscriptionHelper.showTrialExpiredDialog(context);
                }
                return;
              }

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
                  // Update local comments count in feed
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
                    ReactionCacheService.saveCommentsCount(
                      apiSlug,
                      entityId,
                      data.commentsCount,
                    );
                  });
                }
                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();

                // Refresh reaction counts from API to ensure accuracy
                await _refreshReactionFromApi(apiSlug, entityId);

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

                // Update local comments count in feed
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }

                // Refresh reaction counts from API to ensure accuracy
                await _refreshReactionFromApi(apiSlug, entityId);

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
                        (user['particulier_profile']
                                as Map<String, dynamic>?)?['pseudo']
                            ?.toString() ??
                        (user['pro_profile']
                                as Map<String, dynamic>?)?['company_name']
                            ?.toString() ??
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
              // Get avatar URL from user data - check nested profiles
              final particulierProfile =
                  user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl =
                  particulierProfile?['avatar_url']?.toString() ??
                  proProfile?['avatar_url']?.toString() ??
                  proProfile?['logo_url']?.toString() ??
                  user['avatar_url']?.toString();

              return reportableCommentGesture(
                context: context,
                comment: comment,
                currentUserId: _currentUserId,
                child: Padding(
                padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isReply ? 14 : 18,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(
                                  ApiConfig.resolveMediaUrl(avatarUrl) ??
                                      avatarUrl,
                                )
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: isReply ? 12 : 16,
                                  color: Colors.grey[600],
                                )
                              : null,
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
              ));
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

  Future<void> _repostPost(String postId) async {
    try {
      await ApiClient().authenticatedPost('/posts/$postId/repost', body: {});

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

  void _showShareBottomSheet(String bonPlanId) {
    // Share functionality for bon plans
    final String shareUrl =
        '${ApiConfig.baseUrl.replaceAll('/api', '')}/bon-plans/$bonPlanId';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Partager ce bon plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF3AAE5E)),
                title: const Text('Copier le lien'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien copié dans le presse-papiers'),
                      backgroundColor: Color(0xFF3AAE5E),
                    ),
                  );
                },
              ),
              // Bouton partager masqué
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthorInfo(Map<String, dynamic> authorData) {
    // Extract profile data based on account type
    final accountType = authorData['account_type']?.toString();
    final proProfile = authorData['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        authorData['particulier_profile'] as Map<String, dynamic>?;

    // Get the appropriate profile
    final profile = accountType == 'pro' ? proProfile : particulierProfile;

    // Extract name from profile or fallback to direct fields
    final name =
        profile?['company_name']?.toString() ??
        profile?['pseudo']?.toString() ??
        '${profile?['first_name']?.toString() ?? ''} ${profile?['last_name']?.toString() ?? ''}'
            .trim();

    // Extract avatar from profile or fallback to direct fields
    final avatarUrl =
        profile?['avatar_url']?.toString() ?? profile?['avatar']?.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            image:
                avatarUrl != null &&
                    avatarUrl.isNotEmpty &&
                    (avatarUrl.startsWith("https") ||
                        avatarUrl.startsWith("http"))
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : (avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            "${ApiConfig.baseUrl.replaceAll("/api", "")}/storage/$avatarUrl",
                          ),
                          fit: BoxFit.cover,
                        )
                      : null),
          ),
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, size: 16, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isNotEmpty ? name : 'Utilisateur',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (accountType == 'pro')
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
    Map<String, dynamic>? postData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';
    final isBonPlan = apiSlug == 'bon-plans';

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
                data.commentsCount.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Bouton partager masqué
        // For bon plans: show author avatar and name on the left
        if (isBonPlan && authorData != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () {
              final userId = authorData['id']?.toString();
              final accountType = authorData['account_type']?.toString();
              if (userId != null && userId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => accountType?.toLowerCase() == 'pro'
                        ? ProPublicViewScreen(userId: userId)
                        : ParticulierPublicViewScreen(userId: userId),
                  ),
                );
              }
            },
            child: _buildAuthorInfo(authorData),
          ),
        ],
      ],
    );
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

  static const _defaultAvatar =
      'assets/images/dashboard_particulier/Ellipse 10.png';

  String _buildDeliveryInfo(Map<String, dynamic>? pickupMethods) {
    if (pickupMethods == null) return 'Non spécifié';
    final inStore = pickupMethods['in_store'] == true;
    final delivery = pickupMethods['delivery'] == true;
    if (inStore && delivery) return 'En magasin et livraison';
    if (inStore) return 'En magasin uniquement';
    if (delivery) return 'Livraison disponible';
    return 'Non spécifié';
  }

  String _buildShippingCostDisplay() {
    // If shipping option is explicitly set to 'free', show "Gratuit"
    if (widget.shippingOption == 'free') {
      return 'Gratuit';
    }
    // If shipping option is 'paid' and we have a cost
    if (widget.shippingOption == 'paid') {
      if (widget.shippingCost != null && widget.shippingCost!.isNotEmpty) {
        return 'Frais de port à ${widget.shippingCost} €';
      }
      return 'Frais de port';
    }
    // Fallback to delivery info for non-online offers
    return widget.deliveryInfo;
  }

  List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return [];
    }
    final images = mediaFiles
        .where((m) => m is Map && m['url'] != null)
        .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return images;
  }

  /// Like _asInt but returns null instead of 0 for null/invalid values
  int? _tryAsInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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
      final link = data['brand_website']?.toString();
      final pickupMethods = data['pickup_methods'] as Map<String, dynamic>?;
      final deliveryInfo = _buildDeliveryInfo(pickupMethods);
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
      final location = locationCity != null
          ? (locationPostalCode != null
                ? '$locationCity ($locationPostalCode)'
                : locationCity)
          : locationPostalCode;
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImages(mediaFiles);
      final reductionLabel = data['reduction_label']?.toString();
      // Extract price fields from API response (French field names)
      final price = data['prix_final']?.toString();
      final originalPrice = data['prix_avant_reduction']?.toString();
      final shippingOption = data['shipping_option']?.toString();
      final shippingCost = data['shipping_cost']?.toString();
      final availableLocationType = data['available_location_type']?.toString();
      final conditions = data['conditions']?.toString();

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

      await Navigator.push(
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
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            link: link,
            isOwner: isOwner,
            bonPlanId: bonPlanId,
            bonPlanData: data,
            acceptMessages: acceptMessages,
            authorData: user,
            promo_code: bp['promo_code'],
            price: price,
            originalPrice: originalPrice,
            shippingOption: shippingOption,
            shippingCost: shippingCost,
            availableLocationType: availableLocationType,
            conditions: conditions,
            commentsCount: _tryAsInt(data['comments_count']),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      debugPrint('Error fetching bon plan detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  int _calculateDiscount(dynamic originalPrice, dynamic finalPrice) {
    final original = double.tryParse(originalPrice.toString()) ?? 0;
    final finalP = double.tryParse(finalPrice.toString()) ?? 0;
    if (original <= 0 || finalP <= 0 || finalP >= original) return 0;
    final discount = ((original - finalP) / original * 100).round();
    return discount;
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check contact button conditions
    debugPrint('=== CONTACT BUTTON DEBUG ===');
    debugPrint('isOwner: ${widget.isOwner}');
    debugPrint('acceptMessages: ${widget.acceptMessages}');
    debugPrint('authorData: ${widget.authorData}');
    debugPrint('authorData != null: ${widget.authorData != null}');
    debugPrint(
      'Should show button: ${!widget.isOwner && widget.acceptMessages && widget.authorData != null}',
    );
    debugPrint('===========================');

    return AppLayout(
      backgroundColor: const Color(0xFFF9F9FB),
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ),
        title: const Text(
          'Details Bons Plans',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF616161),
                  size: 24,
                ),
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    if (widget.bonPlanId != null &&
                        widget.bonPlanData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreerBonPlanScreen(
                            bonPlanId: widget.bonPlanId,
                            initialData: widget.bonPlanData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de modifier ce bon plan'),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Color(0xFF616161),
                        ),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications activées')),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE6F7EF),
                    border: Border.all(
                      color: const Color(0xFF2A8143),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF2A8143),
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.images.isNotEmpty) ...[
              ImageCarousel(images: widget.images, discount: widget.discount),
            ],
            // Expiration banner
            if (widget.validityType != 'permanent' &&
                widget.validUntil != null &&
                widget.validUntil!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Color.fromARGB(136, 231, 28, 28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatExpirationDate(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            // Main content section - no card, edge to edge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags section
                  if (widget.bonPlanData != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Category tag
                        if (widget.bonPlanData!['category'] != null)
                          _buildTag(
                            widget.bonPlanData!['category'] is Map
                                ? widget.bonPlanData!['category']['name']
                                          ?.toString() ??
                                      ''
                                : widget.bonPlanData!['category']?.toString() ??
                                      '',
                            Icons.local_offer_outlined,
                            const Color(0xFF3AAE5E),
                          ),
                        // Subcategory tag
                        if (widget.bonPlanData!['sub_category'] != null)
                          _buildTag(
                            widget.bonPlanData!['sub_category'] is Map
                                ? widget.bonPlanData!['sub_category']['name']
                                          ?.toString() ??
                                      ''
                                : widget.bonPlanData!['sub_category']
                                          ?.toString() ??
                                      '',
                            Icons.subdirectory_arrow_right,
                            Colors.orange,
                          ),
                        // Type tag
                        if (widget.bonPlanData!['type'] != null &&
                            widget.bonPlanData!['type'].toString().isNotEmpty)
                          _buildTag(
                            widget.bonPlanData!['type']?.toString() ?? '',
                            Icons.label_outline,
                            Colors.blue,
                          ),
                      ],
                    ),
                  if (widget.bonPlanData != null) const SizedBox(height: 12),
                  // Title - big and bold
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Current price in green
                      widget.originalPrice != null && widget.price == null
                          ? Text(
                              '${widget.originalPrice}€',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E9B5B),
                              ),
                            )
                          : (widget.tags.length > 2 &&
                                    widget.tags[2].title ==
                                        'Infos pouvoir d\'achat'
                                ? SizedBox.shrink()
                                : Text(
                                    widget.price != null &&
                                            widget.price.toString().isNotEmpty
                                        ? '${widget.price}€'
                                        : 'Gratuit',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E9B5B),
                                    ),
                                  )),
                      if (widget.price != null &&
                          widget.originalPrice != null &&
                          widget.originalPrice.toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${widget.originalPrice}€',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        // Discount badge
                        if (widget.price != null &&
                            widget.price.toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${_calculateDiscount(widget.originalPrice, widget.price)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      // Discount badge
                      if (widget.discount != null &&
                          widget.discount!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9B5B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.discount!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Promo code as tag - tappable to copy
                      if (widget.promo_code != null &&
                          widget.promo_code.toString().isNotEmpty) ...[
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: widget.promo_code!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copié !'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Color(0xFF2E9B5B),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E9B5B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2E9B5B),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer_outlined,
                                    size: 14,
                                    color: Color(0xFF2E9B5B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Code promo: ${widget.promo_code}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E9B5B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Availability info - removed "Gratuit depuis France"
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dispo. chez ',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        widget.availability.isNotEmpty &&
                                widget.availability != 'Non spécifié'
                            ? widget.availability
                            : 'Moto Axxe',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // CTA Button - Voir le bon plan
                  if (widget.link != null && widget.link!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(widget.link!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: const Text(
                          'Voir le bon plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Action buttons row: Favoris (Share button commented out)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Favoris button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _toggleFavorite,
                            icon: _isLoadingFavorite
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    color: _isFavorite
                                        ? Colors.red
                                        : Colors.grey[600],
                                    size: 24,
                                  ),
                          ),
                          Text(
                            'Favoris',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isFavorite
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // Bouton partager masqué
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Posted time
                  Text(
                    widget.time.isNotEmpty
                        ? "Posté ${widget.time}"
                        : 'Posté il y a 4 h.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Description - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Details du bon plan - no card, full width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details du bon plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Disponibilité
                  _buildDetailItem(
                    icon: Icons.public,
                    iconColor: const Color(0xFF3AAE5E),
                    bgColor: const Color(0xFFE6F7EF),
                    label: 'Disponibilité',
                    value: widget.availability,
                    prefixValue: 'Chez ',
                  ),
                  const SizedBox(height: 16),
                  // Validité
                  _buildDetailItem(
                    icon: Icons.calendar_month_outlined,
                    iconColor: Colors.lightBlue,
                    bgColor: Colors.lightBlue.withOpacity(0.1),
                    label: 'Validité',
                    value: _formatValidity(),
                  ),
                  const SizedBox(height: 16),
                  // Livraison / Frais de port
                  _buildDetailItem(
                    icon: Icons.local_shipping_outlined,
                    iconColor: Colors.purpleAccent,
                    bgColor: Colors.purpleAccent.withOpacity(0.05),
                    label:
                        widget.deliveryInfo == 'Livraison disponible' ||
                            widget.deliveryInfo == 'En magasin uniquement' ||
                            widget.deliveryInfo == 'En magasin et livraison'
                        ? 'Moyen de retrait'
                        : 'Livraison',
                    value: _buildShippingCostDisplay(),
                  ),
                  // Conditions - only show if present
                  if (widget.conditions != null &&
                      widget.conditions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      icon: Icons.info_outline,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.withOpacity(0.1),
                      label: 'Conditions',
                      value: widget.conditions!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Owner section - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: widget.authorData != null
                        ? _navigateToUserProfile
                        : null,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: widget.avatar.startsWith('http')
                          ? NetworkImage(widget.avatar)
                          : AssetImage(widget.avatar) as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and user type
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.authorData != null
                          ? _navigateToUserProfile
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3AAE5E),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.userType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subscribe/Follow button
                  if (!widget.isOwner)
                    _isLoadingFollow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _toggleFollow,
                            style: TextButton.styleFrom(
                              foregroundColor: _isFollowing
                                  ? Colors.grey[600]
                                  : const Color(0xFF3AAE5E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _isFollowing
                                      ? Colors.grey[400]!
                                      : const Color(0xFF3AAE5E),
                                ),
                              ),
                            ),
                            child: Text(
                              _isFollowing ? 'Suivis' : 'Suivre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contact button - only if not owner and acceptMessages is true
            if (!widget.isOwner &&
                widget.acceptMessages &&
                widget.authorData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startConversation(
                      context,
                      widget.authorData!,
                      annonceData: {
                        'annonce_type': 'Bon Plan',
                        'annonce_id': widget.bonPlanId ?? '',
                        'title': widget.title,
                        'description': widget.description,
                        'image_url': widget.images.isNotEmpty
                            ? widget.images.first
                            : '',
                        'author_name': widget.name,
                      },
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 20),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AAE5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            if (!widget.isOwner &&
                widget.acceptMessages &&
                widget.authorData != null)
              const SizedBox(height: 16),
            // Localisation - only show if available_location_type is 'En magasin'
            if (widget.availableLocationType == 'En magasin')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localisation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.location != null &&
                        widget.location!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/details_bon_plans/Rectangle 128 (1).png',
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.location!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF616161),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Localisation non spécifiée',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Comments Card - Tap to open full comments sheet
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Commentaires',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_localCommentsCount ?? _comments.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Preview last 2 comments or empty state
                  if (_isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_comments.isEmpty &&
                      (_localCommentsCount == null || _localCommentsCount == 0))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Aucun commentaire. Soyez le premier !',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _comments
                          .take(2)
                          .map((comment) => _buildCommentItem(comment))
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  // View all comments button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => SubscriptionHelper.guardFeature(
                        context,
                        ProFeature.commentAndReact,
                        () => _showCommentsSheet(context),
                        featureName: 'Commenter',
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: Text(
                        _comments.isEmpty
                            ? 'Ajouter un commentaire'
                            : 'Voir tous les commentaires',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3AAE5E),
                        side: const BorderSide(color: Color(0xFF3AAE5E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                "Autres bons plans qui pourraient vous intéresser",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ), // space on sides
              child: Container(
                height: 1, // thin line
                color: Colors.grey[300], // light gray
              ),
            ),

            // Dynamic Related Bon Plans
            if (_isLoadingRelated)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_relatedBonPlans.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Aucun bon plan disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ..._relatedBonPlans.map((bp) {
                final bpId = bp['id']?.toString() ?? '';
                final title = bp['title']?.toString() ?? '';
                final category = bp['category']?.toString() ?? '';
                final subCategory = bp['sub_category']?.toString() ?? '';
                final type = bp['type']?.toString() ?? '';
                final merchantName = bp['available_at_name']?.toString() ?? '';
                final locationType =
                    bp['available_location_type']?.toString() ?? '';
                final createdAt = bp['created_at']?.toString();
                // Support both media_files (from BonPlanController) and media (from FeedController)
                final mediaFilesFromFiles = bp['media_files'] as List? ?? [];
                final mediaFromMedia = bp['media'] as List? ?? [];
                final mediaFiles = [...mediaFilesFromFiles, ...mediaFromMedia];

                // Debug logging for image URLs
                debugPrint('=== BON PLAN #$bpId MEDIA DEBUG ===');
                debugPrint('media_files count: ${mediaFilesFromFiles.length}');
                debugPrint('media count: ${mediaFromMedia.length}');
                for (final m in mediaFiles) {
                  debugPrint('Media item: $m');
                }

                final imageUrls = mediaFiles
                    .where((m) => m['type'] == 'image' || m['type'] == null)
                    .map((m) {
                      final rawUrl = m['url']?.toString() ?? '';
                      final resolvedUrl = _buildStorageUrl(rawUrl) ?? '';
                      debugPrint('Raw URL: $rawUrl -> Resolved: $resolvedUrl');
                      return resolvedUrl;
                    })
                    .where((url) => url.isNotEmpty)
                    .toList();
                debugPrint('Final imageUrls: $imageUrls');
                debugPrint('=====================================');
                // Check if already favorited by current user
                final favoris = bp['bon_plan_favorites'] as List? ?? [];
                final currentUserId = UserSession().id;
                final bool initialIsFavorited =
                    currentUserId != null &&
                    favoris.any(
                      (f) =>
                          f is Map &&
                          (f['user_id']?.toString() == currentUserId ||
                              f['user']?['id']?.toString() == currentUserId),
                    );

                // Use ValueNotifier for state that persists across rebuilds
                final isFavoritedNotifier = ValueNotifier<bool>(
                  initialIsFavorited,
                );

                return StatefulBuilder(
                  builder: (context, setState) {
                    bool _isLoading = false;

                    Future<void> _toggleFavorite() async {
                      if (_isLoading) return;

                      // Toggle immediately for responsive UI
                      isFavoritedNotifier.value = !isFavoritedNotifier.value;
                      setState(() => _isLoading = true);

                      try {
                        if (!isFavoritedNotifier.value) {
                          // Remove from favorites
                          await ApiClient().authenticatedDelete(
                            '/bonplans/$bpId/favorite',
                          );
                          // Update underlying data to persist state across rebuilds
                          if (bp['bon_plan_favorites'] is List) {
                            (bp['bon_plan_favorites'] as List).removeWhere(
                              (f) =>
                                  f is Map &&
                                  (f['user_id']?.toString() == currentUserId ||
                                      f['user']?['id']?.toString() ==
                                          currentUserId),
                            );
                          }
                        } else {
                          // Add to favorites
                          await ApiClient().authenticatedPost(
                            '/bonplans/$bpId/favorite',
                          );
                          // Update underlying data to persist state across rebuilds
                          if (bp['bon_plan_favorites'] is! List) {
                            bp['bon_plan_favorites'] = [];
                          }
                          (bp['bon_plan_favorites'] as List).add({
                            'user_id': currentUserId,
                            'user': {'id': currentUserId},
                          });
                        }

                        setState(() {
                          _isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavoritedNotifier.value
                                    ? 'Ajouté aux favoris'
                                    : 'Retiré des favoris',
                                style: TextStyle(color: Colors.white),
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Favorite toggle error: $e');
                        // Revert on error
                        isFavoritedNotifier.value = !isFavoritedNotifier.value;
                        setState(() {
                          _isLoading = false;
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erreur lors de la mise à jour des favoris',
                              ),
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
                                _buildBonPlanImageCarousel(imageUrls),

                              // Title
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  imageUrls.isNotEmpty ? 16 : 56,
                                  100,
                                  0,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildBonPlanDescription(bp),
                              ),
                              const SizedBox(height: 12),

                              // Price instead of tags
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    bp['original_price'] != null &&
                                            bp['price'] == null
                                        ? Text(
                                            '${bp['original_price']}€',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E9B5B),
                                            ),
                                          )
                                        : (type == 'Infos pouvoir d\'achat'
                                              ? SizedBox.shrink()
                                              : Text(
                                                  bp['price'] != null &&
                                                          bp['price']
                                                              .toString()
                                                              .isNotEmpty
                                                      ? '${bp['price']}€'
                                                      : 'Gratuit',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E9B5B),
                                                  ),
                                                )),
                                    if (bp['price'] != null &&
                                        bp['original_price'] != null &&
                                        bp['original_price']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${bp['original_price']}€',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      // Discount badge
                                      if (bp['price'] != null &&
                                          bp['price']
                                              .toString()
                                              .isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5722),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '-${_calculateDiscount(bp['original_price'], bp['price'])}%',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                    // Promo code as tag
                                    if (bp['promo_code'] != null &&
                                        bp['promo_code']
                                            .toString()
                                            .isNotEmpty) ...[
                                      Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF2E9B5B,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF2E9B5B),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.local_offer_outlined,
                                                size: 14,
                                                color: Color(0xFF2E9B5B),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Code promo: ${bp['promo_code']}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2E9B5B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Merchant + time
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Builder(
                                    builder: (ctx) {
                                      _seedReactionFromResource(
                                        'bon-plans',
                                        bpId,
                                        bp,
                                      );
                                      return _buildReactionBar(
                                        'bon-plans',
                                        bpId,
                                        acceptedMessages:
                                            bp['accept_messages'] == true,
                                        authorData:
                                            bp['user'] as Map<String, dynamic>?,
                                      );
                                    },
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
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _navigateToBonPlanDetail(bp),
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('VOIR LE BON PLAN'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9800),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
                                        isFavoritedNotifier.value
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavoritedNotifier.value
                                            ? Colors.red
                                            : Colors.grey[600],
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
              }).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatValidity() {
    switch (widget.validityType) {
      case 'permanent':
        return 'Offre permanente';
      case 'dates':
        // Handle all combinations for dates type
        final hasFrom =
            widget.validFrom != null && widget.validFrom!.isNotEmpty;
        final hasUntil =
            widget.validUntil != null && widget.validUntil!.isNotEmpty;

        if (hasFrom && hasUntil) {
          try {
            final from = DateTime.parse(widget.validFrom!);
            final until = DateTime.parse(widget.validUntil!);
            return 'À partir du ${from.day}/${from.month}/${from.year} jusqu\'au ${until.day}/${until.month}/${until.year}';
          } catch (_) {
            return 'Offre avec dates';
          }
        } else if (hasFrom) {
          try {
            final from = DateTime.parse(widget.validFrom!);
            return 'À partir du ${from.day}/${from.month}/${from.year}';
          } catch (_) {
            return 'Offre avec dates';
          }
        } else if (hasUntil) {
          try {
            final until = DateTime.parse(widget.validUntil!);
            return 'Jusqu\'au ${until.day}/${until.month}/${until.year}';
          } catch (_) {
            return 'Offre avec dates';
          }
        }
        return 'Offre avec dates';
      default:
        return 'Offre permanente';
    }
  }

  String _formatExpirationDate() {
    if (widget.validUntil != null && widget.validUntil!.isNotEmpty) {
      try {
        final date = DateTime.parse(widget.validUntil!);
        // Get month name in French
        final months = [
          'janvier',
          'février',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'août',
          'septembre',
          'octobre',
          'novembre',
          'décembre',
        ];
        final month = months[date.month - 1];
        // Format hour with leading zero
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return 'Ce bon plan expire le ${date.day} $month ';
      } catch (_) {
        return 'Date de fin: ${widget.validUntil}';
      }
    }
    return 'Offre permanente';
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null) return 'Il y a un moment';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) {
        return 'Il y a ${(diff.inDays / 30).floor()} mois';
      } else if (diff.inDays > 0) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inMinutes > 0) {
        return 'Il y a ${diff.inMinutes}min';
      }
    } catch (_) {}
    return 'Il y a un moment';
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.flight_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'finance':
        return Icons.account_balance_outlined;
      case 'tech':
        return Icons.computer_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  static Future<void> _startConversation(
    BuildContext context,
    Map<String, dynamic> authorData, {
    Map<String, dynamic>? annonceData,
  }) async {
    // Check subscription for pro users
    if (!SubscriptionHelper.canAccessFeature(ProFeature.messaging)) {
      if (context.mounted) {
        SubscriptionHelper.showPremiumRequiredDialog(
          context,
          featureName: 'Messagerie',
        );
      }
      return;
    }

    final authorId = authorData['id']?.toString();

    // Extraire le nom depuis le profil particulier
    String authorName = 'Utilisateur';
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorName =
          particulierProfile['pseudo']?.toString() ??
          authorData['email']?.toString().split('@').first ??
          'Utilisateur';
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorName =
          proProfile['company_name']?.toString() ??
          (proProfile['first_name']?.toString() != null &&
                  proProfile['last_name']?.toString() != null
              ? '${proProfile['first_name']} ${proProfile['last_name']}'
              : authorData['email']?.toString().split('@').first) ??
          'Utilisateur';
    }

    // Extraire l'avatar depuis le profil approprié
    String? authorAvatar;
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorAvatar = particulierProfile['avatar_url']?.toString();
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorAvatar = proProfile['avatar_url']?.toString();
    }

    if (authorId == null || authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de démarrer la conversation'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final otherUserId = int.tryParse(authorId);
    if (otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID utilisateur invalide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create or get conversation
      final conversationService = ConversationService();
      final conversation = await conversationService.getOrCreateConversation(
        otherUserId,
      );

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Navigate to chat conversation screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation.id.toString(),
              name: authorName,
              avatar:
                  authorAvatar ??
                  'assets/images/dashboard_particulier/Ellipse 10.png',
              status: 'En ligne',
              linkedAnnonce: annonceData,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        // Extract error message from exception
        String errorMessage = 'Échec, veuillez réessayer';
        final exceptionString = e.toString();
        if (exceptionString.startsWith('Exception: ')) {
          errorMessage = exceptionString.substring('Exception: '.length);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildDescription() {
    // If we have rich text delta, render it with Quill
    if (widget.descriptionDelta != null &&
        widget.descriptionDelta.toString().isNotEmpty) {
      try {
        List opsList;

        if (widget.descriptionDelta is List) {
          // Already a List<dynamic> of Dart maps — use directly
          opsList = widget.descriptionDelta as List;
        } else if (widget.descriptionDelta is Map &&
            (widget.descriptionDelta as Map)['ops'] is List) {
          opsList = (widget.descriptionDelta as Map)['ops'] as List;
        } else if (widget.descriptionDelta is String) {
          String jsonString = widget.descriptionDelta as String;

          // Handle unquoted keys
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
            throw Exception('Unknown delta format');
          }
        } else {
          throw Exception(
            'Unsupported descriptionDelta type: ${widget.descriptionDelta.runtimeType}',
          );
        }

        // Filter out operations with null insert values
        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isEmpty) throw Exception('No valid ops');

        // Ensure last op ends with newline (Quill requirement)
        final lastInsert = filteredOps.last['insert'];
        if (lastInsert is String && !lastInsert.endsWith('\n')) {
          filteredOps.add({'insert': '\n'});
        }

        final doc = quill.Document.fromJson(filteredOps);
        final controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        return quill.QuillEditor.basic(
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
        );
      } catch (e) {
        // Fall back to plain text if parsing fails
        debugPrint('Error rendering rich text: $e');
      }
    }

    // Fallback to plain text
    return Text(
      widget.description.isNotEmpty
          ? widget.description
          : 'Aucune description disponible.',
      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.bonPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce bon plan')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Supprimer le bon plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer ce bon plan ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          final token = await TokenStorage.getAccessToken();
                          if (token == null) throw Exception('Session expirée');
                          final response = await http.delete(
                            Uri.parse(
                              '${ApiConfig.baseUrl}/bonplans/${widget.bonPlanId}',
                            ),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 &&
                              response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bon plan supprimé avec succès'),
                                backgroundColor: Color(0xFF3AAE5E),
                              ),
                            );
                            Navigator.pop(context, 'deleted');
                          } else {
                            throw Exception('Erreur ${response.statusCode}');
                          }
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erreur: ${e.toString().replaceFirst("Exception: ", "")}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    String? originalValue,
    String? prefixValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (prefixValue != null)
                    Text(
                      prefixValue,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
              ),
              if (originalValue != null && originalValue.isNotEmpty)
                Text(
                  'Au lieu de $originalValue',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;

    // Extract name from nested profiles
    String authorName = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        authorName =
            profile['pseudo']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        authorName =
            profile['company_name']?.toString() ??
            profile['first_name']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else {
        authorName = user['name']?.toString() ?? 'Utilisateur';
      }
    }

    // Extract avatar from nested profiles
    String? rawAvatarUrl;
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        rawAvatarUrl = profile['avatar_url']?.toString();
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        rawAvatarUrl = profile['avatar_url']?.toString();
      }
      if (rawAvatarUrl == null) {
        rawAvatarUrl = user['avatar_url']?.toString();
      }
    }
    final avatarUrl = ApiConfig.resolveMediaUrl(rawAvatarUrl);

    final body = comment['body'] ?? '';
    final createdAt = comment['created_at'];
    String timeAgo = 'Il y a un moment';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
        } else if (diff.inHours > 0) {
          timeAgo = 'Il y a ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeAgo = 'Il y a ${diff.inMinutes}min';
        }
      } catch (_) {}
    }

    return reportableCommentGesture(
                context: context,
                comment: comment,
                currentUserId: _currentUserId,
                child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                avatarUrl != null && avatarUrl.toString().startsWith('http')
                ? NetworkImage(avatarUrl)
                : const AssetImage(
                        'assets/images/dashboard_particulier/Ellipse 10.png',
                      )
                      as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  void _showCommentsSheet(BuildContext context) async {
    if (widget.bonPlanId == null) return;
    await _getCurrentUserId();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final commentCtrl = TextEditingController();

            Future<void> submitComment() async {
              if (!SubscriptionHelper.canAccessFeature(
                ProFeature.commentAndReact,
              )) {
                if (context.mounted) {
                  SubscriptionHelper.showTrialExpiredDialog(context);
                }
                return;
              }

              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/bon-plans/${widget.bonPlanId}/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/bon-plans/${widget.bonPlanId}/comments',
                    body: {'body': text},
                  );
                }

                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      // Add reply to parent
                      final parent = _comments.firstWhere(
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
                      // Add new top-level comment
                      _comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  // Update main state
                  setState(() {});
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
                debugPrint('Error posting comment: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'envoi')),
                  );
                }
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);

              final newText = await showDialog<String>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
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
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(dialogCtx, editController.text),
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
                  setState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });
                  modalSetState(() {});
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
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
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
                setState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = _comments.firstWhere(
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
                    _comments.removeWhere((c) => c['id'] == commentId);
                    if (_localCommentsCount != null &&
                        _localCommentsCount! > 0) {
                      _localCommentsCount = _localCommentsCount! - 1;
                    }
                  }
                });
                modalSetState(() {});
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
              final user = comment['user'] as Map<String, dynamic>?;

              // Extract name from nested profiles
              String displayName = 'Utilisateur';
              if (user != null) {
                if (user['particulier_profile'] != null) {
                  final profile =
                      user['particulier_profile'] as Map<String, dynamic>;
                  displayName =
                      profile['pseudo']?.toString() ??
                      user['name']?.toString() ??
                      'Utilisateur';
                } else if (user['pro_profile'] != null) {
                  final profile = user['pro_profile'] as Map<String, dynamic>;
                  displayName =
                      profile['company_name']?.toString() ??
                      user['name']?.toString() ??
                      'Utilisateur';
                } else {
                  displayName = user['name']?.toString() ?? 'Utilisateur';
                }
              }

              // Extract avatar
              String? rawAvatarUrl;
              if (user != null) {
                if (user['particulier_profile'] != null) {
                  rawAvatarUrl = user['particulier_profile']['avatar_url']
                      ?.toString();
                } else if (user['pro_profile'] != null) {
                  rawAvatarUrl = user['pro_profile']['avatar_url']?.toString();
                }
              }
              final avatarUrl = ApiConfig.resolveMediaUrl(rawAvatarUrl);

              final body = comment['body'] ?? '';
              final createdAt = comment['created_at'];
              String timeAgo = 'Il y a un moment';
              if (createdAt != null) {
                try {
                  final date = DateTime.parse(createdAt);
                  final diff = DateTime.now().difference(date);
                  if (diff.inDays > 0) {
                    timeAgo = 'Il y a ${diff.inDays}j';
                  } else if (diff.inHours > 0) {
                    timeAgo = 'Il y a ${diff.inHours}h';
                  } else if (diff.inMinutes > 0) {
                    timeAgo = 'Il y a ${diff.inMinutes}min';
                  }
                } catch (_) {}
              }

              final replies = List<Map<String, dynamic>>.from(
                (comment['replies'] as List?) ?? [],
              );
              final userId = user?['id']?.toString();
              final isOwner = userId != null && userId == _currentUserId;

              return reportableCommentGesture(
                context: context,
                comment: comment,
                currentUserId: _currentUserId,
                child: Padding(
                padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isReply ? 14 : 18,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : const AssetImage(
                                      'assets/images/dashboard_particulier/Ellipse 10.png',
                                    )
                                    as ImageProvider,
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
                                  const SizedBox(width: 6),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: isReply ? 10 : 11,
                                      color: Colors.grey[500],
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
                                          if (value == 'edit')
                                            editComment(comment);
                                          else if (value == 'delete')
                                            deleteComment(comment, isReply);
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
                                style: TextStyle(
                                  fontSize: isReply ? 12 : 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Reply button
                              if (!isReply)
                                GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      replyingToId = comment['id'] as int?;
                                      replyingToName = displayName;
                                    });
                                  },
                                  child: Text(
                                    'Répondre',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Nested replies
                    if (!isReply && replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...replies.map((r) => buildCommentItem(r, isReply: true)),
                    ],
                  ],
                ),
              ));
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Commentaires (${_comments.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // Comments list
                    Expanded(
                      child: _isLoadingComments
                          ? const Center(child: CircularProgressIndicator())
                          : _comments.isEmpty
                          ? Center(
                              child: Text(
                                'Aucun commentaire\nSoyez le premier à commenter !',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: controller,
                              padding: const EdgeInsets.all(16),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                return buildCommentItem(_comments[index]);
                              },
                            ),
                    ),
                    // Reply indicator
                    if (replyingToId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.grey[100],
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
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    // Input
                    Container(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentCtrl,
                              decoration: InputDecoration(
                                hintText: replyingToId != null
                                    ? 'Répondre à $replyingToName...'
                                    : 'Ajouter un commentaire...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 3,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => submitComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: submitComment,
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF3AAE5E),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE6F7EF),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Bouton partager masqué
  // void _shareBonPlan() { ... }

  Widget _buildTag(String text, IconData icon, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
