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
import 'package:myreklam/services/conversation_service.dart';

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
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _relatedBonPlans = [];
  bool _isLoadingRelated = false;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _fetchRelatedBonPlans();
    _checkFollowStatus();
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
            const SnackBar(content: Text('Vous ne suivez plus cet utilisateur')),
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
            const SnackBar(content: Text('Vous suivez maintenant cet utilisateur')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoadingFollow = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    if (widget.bonPlanId == null) return;
    
    setState(() => _isLoadingComments = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/comments/bon-plans/${widget.bonPlanId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final commentsData = data['data']['data'] ?? data['data'];
          if (commentsData is List) {
            setState(() {
              _comments = commentsData.cast<Map<String, dynamic>>();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postComment() async {
    if (widget.bonPlanId == null || _commentController.text.trim().isEmpty) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/comments/bon-plans/${widget.bonPlanId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'body': _commentController.text.trim()}),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        _fetchComments();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
    }
  }

  Future<void> _fetchRelatedBonPlans() async {
    setState(() => _isLoadingRelated = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      // Fetch latest bon plans excluding current one
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/feed/latest?type=bon_plan&per_type_limit=4'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = data['data']['items'] as List? ?? [];
          // Filter out current bon plan and take up to 3
          final filtered = items
              .where((item) => item['id'].toString() != widget.bonPlanId)
              .take(3)
              .toList();
          setState(() {
            _relatedBonPlans = filtered.cast<Map<String, dynamic>>();
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
                    if (widget.bonPlanId != null && widget.bonPlanData != null) {
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
              const SizedBox(height: 16),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: UserDetailCard(
                avatar: widget.avatar,
                name: widget.name,
                userType: widget.userType,
                onSubscribe: widget.isOwner ? null : _toggleFollow,
                onTap: widget.authorData != null ? _navigateToUserProfile : null,
                showSubscribeButton: !widget.isOwner,
                isFollowing: _isFollowing,
                isLoading: _isLoadingFollow,
              ),
            ),
            const SizedBox(height: 16),
            PostContentCard(
              tags: widget.tags.isEmpty
                  ? [
                      PostTag(
                        title: 'High-Tech',
                        icon: Icons.local_offer_outlined,
                        color: Colors.orange,
                      ),
                      PostTag(
                        title: 'Photographie',
                        icon: Icons.grid_view_outlined,
                        color: Colors.grey,
                      ),
                      PostTag(
                        title: 'Bons plans',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                    ]
                  : widget.tags,
              title: widget.title,
              time: widget.time,
              onLike: () {},
              onShare: () {},
            ),
            const SizedBox(height: 16),
            // Offer Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Details du bons plans',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  // Single Column Layout for Details
                  _buildDetailItem(
                    icon: Icons.euro_symbol,
                    iconColor: Colors.orange,
                    bgColor: Colors.orange.withOpacity(0.1),
                    label: 'Prix',
                    value: widget.price ?? 'Gratuit',
                    originalValue: widget.originalPrice,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.public,
                    iconColor: const Color(0xFF3AAE5E),
                    bgColor: const Color(0xFFE6F7EF),
                    label: 'Disponibilité',
                    value: widget.availability,
                    prefixValue: 'Chez ',
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.calendar_month_outlined,
                    iconColor: Colors.lightBlue,
                    bgColor: Colors.lightBlue.withOpacity(0.1),
                    label: 'Validité',
                    value: _formatValidity(),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.directions_bike,
                    iconColor: Colors.purpleAccent,
                    bgColor: Colors.purpleAccent.withOpacity(0.05),
                    label: 'Livraison',
                    value: widget.deliveryInfo,
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Primary CTA
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
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Voir le bon plan'),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description Card
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
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contact button - only if not owner and acceptMessages is true
            if (!widget.isOwner && widget.acceptMessages && widget.authorData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startConversation(context, widget.authorData!),
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
            if (!widget.isOwner && widget.acceptMessages && widget.authorData != null)
              const SizedBox(height: 16),
            // Localisation Card
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
                        Icons.location_on_outlined,
                        color: Color(0xFF3AAE5E),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Localisation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  if (widget.location != null && widget.location!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/details_bon_plans/Rectangle 128 (1).png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.location!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
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
            // Comments Card
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comments list
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
                          'Aucun commentaire',
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
                          .map((comment) => _buildCommentItem(comment))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Comment input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 2,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _postComment,
                        icon: const Icon(Icons.send, color: Color(0xFF3AAE5E)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE6F7EF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
                final user = bonPlan['user'] as Map<String, dynamic>?;
                final userName = user?['particulier_profile']?['pseudo'] ??
                    user?['pro_profile']?['company_name'] ??
                    bonPlan['author']?['name'] ??
                    'Utilisateur';
                final userType = user?['type'] == 'pro' ? 'Professionnel' : 'Particulier';
                final avatarUrl = user?['particulier_profile']?['avatar_url'] ??
                    user?['pro_profile']?['avatar_url'] ??
                    'assets/images/dashboard_particulier/Ellipse 10.png';
                final media = bonPlan['media'] as List? ?? [];
                final imageUrl = media.isNotEmpty
                    ? media.first['url']?.toString() ??
                      'assets/images/dashboard_particulier/Rectangle 12 (4).png'
                    : 'assets/images/dashboard_particulier/Rectangle 12 (4).png';
                final category = bonPlan['category'] as Map<String, dynamic>?;
                final categoryName = category?['name'] ?? 'Catégorie';
                final categoryIcon = category?['icon'] != null
                    ? _getIconFromString(category!['icon'])
                    : Icons.category_outlined;

                return ProPostCard(
                  profileImage: avatarUrl,
                  username: userName,
                  userType: userType,
                  postText: bonPlan['title'] ?? 'Sans titre',
                  postImage: imageUrl,
                  reductionPercentage: bonPlan['discount_display']?.toString() ?? '',
                  categoryIcon: categoryIcon,
                  categoryName: categoryName,
                  merchantName: bonPlan['merchant_name'] ?? '',
                  timeAgo: _formatTimeAgo(bonPlan['created_at']),
                  onTapCTA: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProPostDetailScreen(
                          images: media.map((m) => m['url']?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
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
                          acceptMessages: bonPlan['accept_messages'] == true || bonPlan['accept_messages'] == 1,
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
    if (widget.descriptionDelta != null && widget.descriptionDelta.toString().isNotEmpty) {
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
      widget.description.isNotEmpty ? widget.description : 'Aucune description disponible.',
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
    final authorName = user?['name'] ?? 'Utilisateur';
    final avatarUrl = user?['avatar_url'];
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
            backgroundImage: avatarUrl != null && avatarUrl.toString().startsWith('http')
                ? NetworkImage(avatarUrl)
                : const AssetImage('assets/images/dashboard_particulier/Ellipse 10.png') as ImageProvider,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
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
}
