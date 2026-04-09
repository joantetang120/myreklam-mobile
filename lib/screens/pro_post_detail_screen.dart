import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_bon_plan_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';

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
  final String? link;
  final String? promo_code;
  final bool isOwner;
  final String? bonPlanId;
  final Map<String, dynamic>? bonPlanData;
  final bool acceptMessages;
  final Map<String, dynamic>? authorData;

  const ProPostDetailScreen({
    super.key,
    this.images = const ['assets/images/details_bon_plans/Rectangle 35.png'],
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
    this.link,
    this.promo_code,
    this.isOwner = false,
    this.bonPlanId,
    this.bonPlanData,
    this.acceptMessages = false,
    this.authorData,
  });

  @override
  State<ProPostDetailScreen> createState() => _ProPostDetailScreenState();
}

class _ProPostDetailScreenState extends State<ProPostDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  List<Map<String, dynamic>> _relatedBonPlans = [];
  bool _isLoadingRelated = false;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
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
          if (widget.isOwner)
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
                      Text(
                        widget.price ?? 'Gratuit',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E9B5B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Original price crossed out
                      if (widget.originalPrice != null &&
                          widget.originalPrice!.isNotEmpty)
                        Text(
                          widget.originalPrice!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
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

                      // Promo code as tag
                      if (widget.promo_code != null &&
                          widget.promo_code.toString().isNotEmpty) ...[
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
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
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Action buttons row: Favoris (Share button commented out)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      // Commented out: Partager (Share) button
                      // Column(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     IconButton(
                      //       onPressed: () {
                      //         // TODO: Implement share functionality
                      //       },
                      //       icon: Icon(
                      //         Icons.share_outlined,
                      //         color: Colors.grey[600],
                      //         size: 24,
                      //       ),
                      //     ),
                      //     Text(
                      //       'Partager',
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         color: Colors.grey[600],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Posted time
                  Text(
                    widget.time.isNotEmpty ? widget.time : 'Posté il y a 4 h.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                          Text(
                            widget.userType,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
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
            const SizedBox(height: 8),
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
                  // Prix
                  _buildDetailItem(
                    icon: Icons.euro_symbol,
                    iconColor: Colors.orange,
                    bgColor: Colors.orange.withOpacity(0.1),
                    label: 'Prix',
                    value: widget.price ?? 'Gratuit',
                    originalValue: widget.originalPrice,
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
                  // Livraison
                  _buildDetailItem(
                    icon: Icons.directions_bike,
                    iconColor: Colors.purpleAccent,
                    bgColor: Colors.purpleAccent.withOpacity(0.05),
                    label: 'Livraison',
                    value: widget.deliveryInfo,
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
                    onPressed: () =>
                        _startConversation(context, widget.authorData!),
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
            // Localisation - no card
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
                        '${_comments.length}',
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
                  else if (_comments.isEmpty)
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
                      onPressed: () => _showCommentsSheet(context),
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
              ..._relatedBonPlans.map((bonPlan) {
                // Helper function to parse potentially JSON string fields
                dynamic parseField(dynamic field) {
                  if (field is String) {
                    try {
                      return jsonDecode(field);
                    } catch (_) {
                      return field;
                    }
                  }
                  return field;
                }

                final userData = parseField(bonPlan['user']);
                final user = userData is Map<String, dynamic> ? userData : null;
                final userName =
                    user?['particulier_profile']?['pseudo'] ??
                    user?['pro_profile']?['company_name'] ??
                    bonPlan['author']?['name'] ??
                    'Utilisateur';
                final accountType =
                    user?['account_type']?.toString() ??
                    user?['type']?.toString() ??
                    'particulier';
                final userType = accountType == 'pro'
                    ? 'Professionnel'
                    : 'Particulier';

                // Resolve avatar URL with proper base URL and storage prefix
                final rawAvatarUrl =
                    user?['particulier_profile']?['avatar_url'] ??
                    user?['pro_profile']?['avatar_url'];
                final avatarUrl =
                    ApiConfig.resolveMediaUrl(rawAvatarUrl) ??
                    'assets/images/dashboard_particulier/Ellipse 10.png';

                final mediaData = parseField(bonPlan['media']);
                final media = mediaData is List ? mediaData : <dynamic>[];

                final imageUrl = media.isNotEmpty
                    ? ApiConfig.resolveMediaUrl(
                            media.first['url']?.toString(),
                          ) ??
                          'assets/images/dashboard_particulier/Rectangle 12 (4).png'
                    : 'assets/images/dashboard_particulier/Rectangle 12 (4).png';

                final categoryData = parseField(bonPlan['category']);
                final category = categoryData is Map<String, dynamic>
                    ? categoryData
                    : null;
                final categoryName = category?['name'] ?? 'Catégorie';
                final categoryIcon = category?['icon'] != null
                    ? _getIconFromString(category!['icon']?.toString())
                    : Icons.category_outlined;

                return ProPostCard(
                  profileImage: avatarUrl,
                  username: userName,
                  userType: userType,
                  postText: bonPlan['title'] ?? 'Sans titre',
                  postImage: imageUrl,
                  reductionPercentage:
                      bonPlan['discount_display']?.toString() ?? '',
                  categoryIcon: categoryIcon,
                  categoryName: categoryName,
                  merchantName: bonPlan['merchant_name'] ?? '',
                  timeAgo: _formatTimeAgo(bonPlan['created_at']),
                  onTapCTA: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProPostDetailScreen(
                          images: media
                              .map(
                                (m) =>
                                    ApiConfig.resolveMediaUrl(
                                      m['url']?.toString(),
                                    ) ??
                                    '',
                              )
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          discount: bonPlan['discount_display']?.toString(),
                          avatar: avatarUrl,
                          name: userName,
                          userType: userType,
                          title: bonPlan['title'] ?? 'Sans titre',
                          description: bonPlan['description'] ?? '',
                          price: bonPlan['price']?.toString(),
                          originalPrice: bonPlan['original_price']?.toString(),
                          location: bonPlan['location'],
                          link: bonPlan['external_link'],
                          isOwner: false,
                          bonPlanId: bonPlan['id']?.toString(),
                          bonPlanData: bonPlan,
                          acceptMessages:
                              bonPlan['accept_messages'] == true ||
                              bonPlan['accept_messages'] == 1,
                          authorData: user,
                        ),
                      ),
                    );
                  },
                  price: bonPlan['price']?.toString() ?? '',
                  likesCount: bonPlan['likes_count'] ?? 0,
                  commentsCount: bonPlan['comments_count'] ?? 0,
                );
              }).toList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatValidity() {
    if (widget.validityType == 'permanent') {
      return 'Offre permanente';
    } else if (widget.validityType == 'dates' &&
        widget.validFrom != null &&
        widget.validUntil != null) {
      try {
        final from = DateTime.parse(widget.validFrom!);
        final until = DateTime.parse(widget.validUntil!);
        return 'Du ${from.day}/${from.month}/${from.year} au ${until.day}/${until.month}/${until.year}';
      } catch (_) {
        return 'Dates spécifiées';
      }
    }
    return 'Offre permanente';
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
    Map<String, dynamic> authorData,
  ) async {
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

    return Padding(
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
    );
  }

  void _showCommentsSheet(BuildContext context) {
    if (widget.bonPlanId == null) return;

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

              return Padding(
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
              );
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
