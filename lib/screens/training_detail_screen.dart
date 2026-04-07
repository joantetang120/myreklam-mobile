import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/screens/creer_formation_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';

class TrainingDetailScreen extends StatefulWidget {
  final List<String> images;
  final String companyLogo;
  final String companyName;
  final String trainingTitle;
  final String description;
  final dynamic descriptionDelta;
  final List<FormationTag> tags;
  final String timeAgo;
  // Training-specific fields
  final String? website;
  final String? trainingType;
  final String? trainingCategory;
  final String? trainingSubCategory;
  final List<String> trainingStyle;
  final List<String> trainingPublic;
  final List<String> requiredLevels;
  final String? price;
  final String? priceType;
  final String? publicType;
  final String? tempo;
  final List<String> trainingFunding;
  final int? durationInH;
  final String? durationUnit;
  final String? startDate;
  final String? endDate;
  final bool dateToDefine;
  final String? addressCity;
  final String? addressZipcode;
  final String? addressLine1;
  final bool showLocation;
  final List<String> certification;
  final List<Map<String, dynamic>> documents;
  final bool isOwner;
  final String? trainingId;
  final Map<String, dynamic>? trainingData;
  final bool returnToListingOnEdit;
  // Author data for follow functionality
  final Map<String, dynamic>? authorData;

  const TrainingDetailScreen({
    super.key,
    this.images = const [],
    required this.companyLogo,
    required this.companyName,
    required this.trainingTitle,
    required this.description,
    this.descriptionDelta,
    required this.tags,
    required this.timeAgo,
    this.website,
    this.trainingType,
    this.trainingCategory,
    this.trainingSubCategory,
    this.trainingStyle = const [],
    this.trainingPublic = const [],
    this.requiredLevels = const [],
    this.price,
    this.priceType,
    this.publicType,
    this.tempo,
    this.trainingFunding = const [],
    this.durationInH,
    this.durationUnit,
    this.startDate,
    this.endDate,
    this.dateToDefine = false,
    this.addressCity,
    this.addressZipcode,
    this.addressLine1,
    this.showLocation = false,
    this.certification = const [],
    this.documents = const [],
    this.isOwner = false,
    this.trainingId,
    this.trainingData,
    this.returnToListingOnEdit = false,
    this.authorData,
  });

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isSubscribed = false;
  bool _isLoadingSubscription = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  int _commentsCount = 0;
  bool _isLiked = false;
  int _likesCount = 0;
  List<Map<String, dynamic>> _similarTrainings = [];
  bool _isLoadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _checkSubscriptionStatus();
    _checkFavoriteStatus();
    _fetchComments();
    _fetchLikes();
    _fetchSimilarTrainings();
  }

  Future<void> _fetchComments() async {
    if (widget.trainingId == null) return;
    
    setState(() => _isLoadingComments = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/comments?per_page=50'),
        headers: {
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> fetched = [];
        if (data['data'] is Map && data['data']['data'] is List) {
          fetched = List<Map<String, dynamic>>.from(data['data']['data']);
        } else if (data['data'] is List) {
          fetched = List<Map<String, dynamic>>.from(data['data']);
        }
        setState(() {
          _comments = fetched;
          _commentsCount = fetched.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _fetchLikes() async {
    if (widget.trainingId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}'),
        headers: {
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _likesCount = data['data']?['likes_count'] ?? 0;
          _isLiked = data['data']?['user_has_liked'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching likes: $e');
    }
  }

  Future<void> _fetchSimilarTrainings() async {
    if (widget.trainingId == null) return;

    setState(() => _isLoadingSimilar = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/similar?limit=3'),
        headers: {
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          setState(() {
            _similarTrainings = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching similar trainings: $e');
    } finally {
      setState(() => _isLoadingSimilar = false);
    }
  }

  Future<void> _toggleLike() async {
    if (widget.trainingId == null) return;
    
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/reactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': 'like'}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLiked = data['data']?['user_has_liked'] ?? !_isLiked;
          _likesCount = data['data']?['likes_count'] ?? 
            (_isLiked ? _likesCount + 1 : _likesCount - 1);
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
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

  Future<void> _checkSubscriptionStatus() async {
    if (widget.isOwner || widget.trainingId == null) return;
    
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/subscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['is_subscribed'] == true) {
          setState(() => _isSubscribed = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  Future<void> _subscribe() async {
    if (widget.isOwner || widget.trainingId == null) return;
    
    setState(() => _isLoadingSubscription = true);
    
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/subscribe'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 201) {
        setState(() => _isSubscribed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription enregistrée avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
        
        // Award 1 My for subscribing to training and show modal
        try {
          final mysResponse = await MysEarningService().awardMys(
            actionType: 'training_subscription',
            referenceId: widget.trainingId?.toString(),
          );
          if (mysResponse['success'] == true && context.mounted) {
            final newBalance = mysResponse['earning']?['new_balance'];
            if (newBalance != null) {
              UserSession().updateMys(newBalance);
            }
            final amount = mysResponse['earning']?['amount'] ?? 1;
            await MysRewardModal.show(
              context,
              amount: amount,
              actionType: 'subscribe',
            );
          }
        } catch (e) {
          debugPrint("Error awarding My's for training subscription: $e");
        }
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Vous êtes déjà inscrit')),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoadingSubscription = false);
    }
  }

  void _showSubscriptionDialog() {
    if (widget.trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de s\'inscrire à cette formation')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirmer l\'inscription',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment vous inscrire à cette formation ?',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Text(
                '"${widget.trainingTitle}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Organisme: ${_resolveOwnerName()}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isLoadingSubscription
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _subscribe();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: _isLoadingSubscription
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.trainingId == null) return;
    
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['is_favorited'] == true) {
          setState(() => _isFavorite = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.trainingId == null) return;
    
    setState(() => _isLoadingFavorite = true);
    
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }
      
      if (_isFavorite) {
        // Unfavorite
        debugPrint('=== REMOVE FAVORITE ===');
        debugPrint('trainingId: ${widget.trainingId}');
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/favorite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() => _isFavorite = false);
          debugPrint('Removed from favorites');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retiré des favoris')),
          );
        }
      } else {
        // Favorite
        debugPrint('=== ADD FAVORITE ===');
        debugPrint('trainingId: ${widget.trainingId}');
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/favorite'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => _isFavorite = true);
          debugPrint('Added to favorites');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ajouté aux favoris')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  String? _resolveAvatarUrl() {
    // First try authorData if available
    if (widget.authorData != null) {
      final user = widget.authorData!;
      String? rawUrl;
      
      if (user['particulier_profile'] != null) {
        rawUrl = user['particulier_profile']['avatar_url']?.toString();
      } else if (user['pro_profile'] != null) {
        rawUrl = user['pro_profile']['avatar_url']?.toString() ?? 
                 user['pro_profile']['logo_url']?.toString();
      }
      
      if (rawUrl != null && rawUrl.isNotEmpty) {
        return ApiConfig.resolveMediaUrl(rawUrl);
      }
    }
    
    // Fall back to companyLogo parameter
    if (widget.companyLogo.startsWith('http')) {
      return widget.companyLogo;
    }
    return widget.companyLogo;
  }

  String _resolveOwnerName() {
    if (widget.authorData != null) {
      final user = widget.authorData!;
      final proProfile = user['pro_profile'] as Map<String, dynamic>?;
      final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
      
      // Try pro profile first
      if (proProfile != null) {
        final companyName = proProfile['company_name']?.toString();
        if (companyName != null && companyName.isNotEmpty) return companyName;
        
        final firstName = proProfile['first_name']?.toString() ?? '';
        final lastName = proProfile['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) return fullName;
      }
      // Try particulier profile
      if (particulierProfile != null) {
        final pseudo = particulierProfile['pseudo']?.toString();
        if (pseudo != null && pseudo.isNotEmpty) return pseudo;
        
        final firstName = particulierProfile['first_name']?.toString() ?? '';
        final lastName = particulierProfile['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) return fullName;
      }
      // Fallback to user name/email
      final name = user['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      
      final email = user['email']?.toString();
      if (email != null && email.isNotEmpty) return email.split('@').first;
    }
    return widget.companyName;
  }

  String _resolveUserType() {
    if (widget.authorData != null) {
      final accountType = widget.authorData!['account_type']?.toString();
      if (accountType == 'pro') return 'Pro';
      if (accountType == 'particulier') return 'Particulier';
    }
    return 'Pro';
  }

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail de la formation',
          style: TextStyle(
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
                icon: const Icon(Icons.more_vert, color: Color(0xFF616161), size: 24),
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreerFormationScreen(
                          trainingId: widget.trainingId,
                          initialData: widget.trainingData,
                          shouldReturnToListingOnSuccess: widget.returnToListingOnEdit,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Color(0xFF616161)),
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
                    border: Border.all(color: const Color(0xFF2A8143), width: 1.5),
                  ),
                  child: const Icon(Icons.notifications, color: Color(0xFF2A8143), size: 18),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Carousel - full width
            if (widget.images.isNotEmpty)
              ImageCarousel(images: widget.images),

            // 2. Main content section - no card, edge to edge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tags
                  if (widget.trainingCategory != null || widget.trainingType != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (widget.trainingCategory != null)
                          _buildTag(
                            widget.trainingCategory!,
                            Icons.category_outlined,
                            const Color(0xFF9C27B0),
                          ),
                        if (widget.trainingType != null)
                          _buildTag(
                            _formatEnumLabel(widget.trainingType!),
                            Icons.school_outlined,
                            Colors.blue,
                          ),
                      ],
                    ),
                  if (widget.trainingCategory != null || widget.trainingType != null)
                    const SizedBox(height: 12),

                  // Title - big and bold
                  Text(
                    widget.trainingTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags (location, duration, etc.) - GRAY TAGS
                  // if (widget.tags.isNotEmpty) ...[
                  //   Builder(
                  //     builder: (context) {
                  //       // Filter out price tags (euro icon) since we show them separately
                  //       final nonPriceTags = widget.tags.where((tag) => tag.icon != Icons.euro).toList();
                  //       final sortedTags = List<FormationTag>.from(nonPriceTags)
                  //         ..sort((a, b) {
                  //           final aIsLocation = a.icon == Icons.location_on_outlined ||
                  //                            a.icon == Icons.location_on;
                  //           final bIsLocation = b.icon == Icons.location_on_outlined ||
                  //                            b.icon == Icons.location_on;
                  //           if (aIsLocation && !bIsLocation) return -1;
                  //           if (!aIsLocation && bIsLocation) return 1;
                  //           return 0;
                  //         });
                  //       return Wrap(
                  //         spacing: 8,
                  //         runSpacing: 8,
                  //         children: sortedTags.map((tag) => _buildDetailTag(tag)).toList(),
                  //       );
                  //     },
                  //   ),
                  //   const SizedBox(height: 16),
                  // ],

                  // const SizedBox(height: 16),
                ],
              ),
            ),
            // const SizedBox(height: 8),

            // 3. Description - no card, full width
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

            // 4. Training details section - no card, full width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 1. Type d'enseignement
                  if (widget.trainingStyle.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.laptop_chromebook,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.withOpacity(0.1),
                      label: 'Type d\'enseignement',
                      value: widget.trainingStyle.map(_formatEnumLabel).join(', '),
                    ),
                  if (widget.trainingStyle.isNotEmpty)
                    const SizedBox(height: 12),
                  // 2. Public cible
                  if (widget.trainingPublic.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.people_outline,
                      iconColor: Colors.teal,
                      bgColor: Colors.teal.withOpacity(0.1),
                      label: 'Public cible',
                      value: widget.trainingPublic.map(_formatEnumLabel).join(', '),
                    ),
                  if (widget.trainingPublic.isNotEmpty)
                    const SizedBox(height: 12),
                  // 3. Prérequis
                  if (widget.requiredLevels.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.school_outlined,
                      iconColor: Colors.purple,
                      bgColor: Colors.purple.withOpacity(0.1),
                      label: 'Prérequis',
                      value: widget.requiredLevels.join(', '),
                    ),
                  if (widget.requiredLevels.isNotEmpty)
                    const SizedBox(height: 12),
                  // 4. Durée
                  if (widget.durationInH != null)
                    _buildDetailItem(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFF3AAE5E),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Durée',
                      value: '${widget.durationInH} ${_durationUnitLabel(widget.durationUnit)}',
                    ),
                  if (widget.durationInH != null)
                    const SizedBox(height: 12),
                  // 5. Dates
                  if (!widget.dateToDefine && (widget.startDate != null || widget.endDate != null))
                    _buildDetailItem(
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.blue,
                      bgColor: Colors.blue.withOpacity(0.1),
                      label: 'Dates',
                      value: _formatDates(widget.startDate, widget.endDate),
                    ),
                  if (widget.dateToDefine)
                    _buildDetailItem(
                      icon: Icons.calendar_today_outlined,
                      iconColor: Colors.blue,
                      bgColor: Colors.blue.withOpacity(0.1),
                      label: 'Dates',
                      value: 'À définir',
                    ),
                  if (widget.startDate != null || widget.endDate != null || widget.dateToDefine)
                    const SizedBox(height: 12),
                  // 6. Certifications
                  if (widget.certification.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.verified_outlined,
                      iconColor: const Color(0xFFFF9800),
                      bgColor: const Color(0xFFFF9800).withOpacity(0.1),
                      label: 'Certifications',
                      value: widget.certification.join(', '),
                    ),
                  if (widget.certification.isNotEmpty)
                    const SizedBox(height: 12),
                  // 7. Financement (CPF)
                  if (widget.trainingFunding.contains('CPF'))
                    _buildDetailItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF3AAE5E),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Financement',
                      value: 'Éligible CPF',
                    ),
                  if (widget.trainingFunding.contains('CPF'))
                    const SizedBox(height: 12),
                  // 8. Prix
                  _buildDetailItem(
                    icon: Icons.euro,
                    iconColor: const Color(0xFF3AAE5E),
                    bgColor: const Color(0xFFE6F7EF),
                    label: 'Prix',
                    value: _formatPrice(),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4.5 Voir le programme button (if documents exist)
            if (widget.documents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadProgramme,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Voir le programme'),
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
            if (widget.documents.isNotEmpty)
              const SizedBox(height: 16),

            // 5. Apply buttons - full width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!widget.isOwner) ...[
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: _isSubscribed
                            ? null
                            : () => _showSubscriptionDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubscribed ? Colors.grey : const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubscribed
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Inscrit', style: TextStyle(fontSize: 14)),
                                ],
                              )
                            : const Text(
                                "S'inscrire",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: widget.website != null && widget.website!.isNotEmpty
                          ? () => _openWebsite(context)
                          : null,
                      icon: const Icon(Icons.language, size: 18),
                      label: const Text("Site de l'organisme"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                        side: const BorderSide(color: Color(0xFFFF9800)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Action buttons row (Favoris, Partager)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_outline,
                              color: _isFavorite ? Colors.red : Colors.grey[600],
                              size: 24,
                            ),
                    ),
                    Text(
                      'Favoris',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // Partager button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        // TODO: Implement share functionality
                      },
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    Text(
                      'Partager',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. Company/Owner section - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: widget.authorData != null ? () => _navigateToUserProfile(context) : null,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: (_resolveAvatarUrl() ?? '').startsWith('http')
                          ? NetworkImage(_resolveAvatarUrl()!)
                          : AssetImage(_resolveAvatarUrl() ?? 'assets/images/Formation.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and user type
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.authorData != null ? () => _navigateToUserProfile(context) : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resolveOwnerName(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            'Pro',
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 8. Posted time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.timeAgo.isNotEmpty ? widget.timeAgo : 'Posté récemment',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 9. Localisation - no card
            if (widget.showLocation && (widget.addressCity != null || widget.addressLine1 != null))
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
                      _buildLocationString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.showLocation && (widget.addressCity != null || widget.addressLine1 != null))
              const SizedBox(height: 16),

            // 10. Comments Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        Icons.comment_outlined,
                        color: Color(0xFF616161),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Commentaires',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_comments.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCommentsSheet(),
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
            const SizedBox(height: 32),

            // 11. Similar formations header
            if (_similarTrainings.isNotEmpty || _isLoadingSimilar) ...[
              const Center(
                child: Text(
                  'Autres formations similaires',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              // Similar formations cards
              if (_isLoadingSimilar)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Column(
                  children: _similarTrainings.map((training) {
                      final mediaFiles = training['media_files'] as List? ?? [];
                      final images = mediaFiles
                          .where((m) => m is Map && m['url'] != null)
                          .map((m) {
                            final url = m['url']?.toString() ?? '';
                            if (url.startsWith('http')) return url;
                            final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
                            return '$serverBase/storage/$url';
                          })
                          .where((url) => url.isNotEmpty)
                          .toList();

                      final trainingCategory = training['training_category']?.toString();
                      final trainingType = training['training_type']?.toString();
                      final durationInH = training['duration_in_h'] is int
                          ? training['duration_in_h'] as int
                          : int.tryParse(training['duration_in_h']?.toString() ?? '');
                      final price = training['price']?.toString();

                      final tags = <FormationTag>[
                        if (trainingCategory != null && trainingCategory.isNotEmpty)
                          FormationTag(icon: Icons.category_outlined, text: trainingCategory),
                        if (trainingType != null && trainingType.isNotEmpty)
                          FormationTag(icon: Icons.school_outlined, text: trainingType),
                        if (durationInH != null)
                          FormationTag(icon: Icons.timer_outlined, text: '$durationInH h'),
                        if (price != null)
                          FormationTag(icon: Icons.euro, text: '$price €', isSpecial: true),
                      ];

                      return FormationCard(
                        companyLogo: training['company_logo']?.toString() ?? 'assets/images/Formation.png',
                        companyName: training['owner_name']?.toString() ?? 'Organisme',
                        formationTitle: training['title']?.toString() ?? '',
                        description: training['description']?.toString() ?? '',
                        tags: tags,
                        timeAgo: _timeAgo(training['created_at']?.toString() ?? ''),
                        onApply: () => _navigateToSimilarTraining(training),
                      );
                    }).toList(),
                  ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    // Show plain text description instead of delta
    if (widget.description.isNotEmpty) {
      return Text(
        widget.description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          height: 1.5,
        ),
      );
    }

    // Fallback: try to render delta if description is empty
    if (widget.descriptionDelta != null && widget.descriptionDelta.toString().isNotEmpty) {
      try {
        dynamic rawData;
        if (widget.descriptionDelta is List) {
          rawData = widget.descriptionDelta;
        } else if (widget.descriptionDelta is Map) {
          rawData = widget.descriptionDelta;
        } else {
          String jsonString = widget.descriptionDelta.toString();
          // Handle JavaScript object notation
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
          rawData = jsonDecode(jsonString);
        }

        List opsList;
        if (rawData is List) {
          opsList = rawData;
        } else if (rawData is Map && rawData['ops'] is List) {
          opsList = rawData['ops'] as List;
        } else {
          throw Exception('Unknown delta format');
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
        debugPrint('Error rendering rich text in training detail: $e');
      }
    }

    return Text(
      'Aucune description disponible.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  String _formatEnumLabel(String value) {
    // Teaching types (training_style) translations
    const teachingTypes = {
      'All': 'Tout',
      'OnSite': 'En centre',
      'InCompany': 'En entreprise',
      'Remote': 'À distance',
      'InApprenticeship': 'En alternance',
    };

    // Target publics (training_public) translations
    const targetPublics = {
      'AllPublic': 'Tout public',
      'Employed': 'Salarié en poste',
      'JobSeeker': 'Demandeurs d\'emploi',
      'Company': 'Entreprise',
      'Student': 'Étudiant',
    };

    // Check for exact matches first
    if (teachingTypes.containsKey(value)) {
      return teachingTypes[value]!;
    }
    if (targetPublics.containsKey(value)) {
      return targetPublics[value]!;
    }

    // Fallback: Convert PascalCase / camelCase to readable
    return value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cette formation')),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Supprimer la formation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette formation ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
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
                            Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Formation supprimée avec succès'),
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
                              content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}'),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _durationUnitLabel(String? unit) {
    switch (unit) {
      case '0': return 'heures';
      case '1': return 'jours';
      case '2': return 'semaines';
      case '3': return 'mois';
      case '4': return 'années';
      default: return 'heures';
    }
  }

  String _formatDates(String? start, String? end) {
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        final date = DateTime.parse(dateStr);
        final months = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (e) {
        return dateStr;
      }
    }

    final formattedStart = formatDate(start);
    final formattedEnd = formatDate(end);

    if (formattedStart.isNotEmpty && formattedEnd.isNotEmpty) {
      return 'Du $formattedStart au $formattedEnd';
    }
    if (formattedStart.isNotEmpty) return 'À partir du $formattedStart';
    if (formattedEnd.isNotEmpty) return "Jusqu'au $formattedEnd";
    return 'À définir';
  }

  String _formatPrice() {
    if (widget.priceType == '4') return 'Gratuit';
    if (widget.priceType == '5') return 'Sur devis';
    if (widget.price != null) {
      final priceLabel = _priceTypeLabel(widget.priceType);
      final tempoLabel = _tempoLabel(widget.tempo);
      final publicLabel = _publicTypeLabel(widget.publicType);
      return '${widget.price} € $priceLabel $publicLabel $tempoLabel'.trim();
    }
    return 'Prix non spécifié';
  }

  String _priceTypeLabel(String? type) {
    switch (type) {
      case '1': return 'NET';
      case '2': return 'HT';
      case '3': return 'TTC';
      default: return '';
    }
  }

  String _tempoLabel(String? t) {
    switch (t) {
      case 'heure': return 'par heure(s)';
      case 'jour': return 'par jour(s)';
      case 'semaine': return 'par semaine(s)';
      case 'mois': return 'par mois(s)';
      case 'an': return 'par an(s)';
      case 'all': return 'pour toute la formation';
      default: return '';
    }
  }

  String _publicTypeLabel(String? type) {
    switch (type) {
      case 'personne': return '/ personne';
      case 'groupe': return '/ groupe';
      default: return '';
    }
  }

  String _buildLocationString() {
    final parts = <String>[];
    if (widget.addressLine1 != null && widget.addressLine1!.isNotEmpty) parts.add(widget.addressLine1!);
    if (widget.addressZipcode != null && widget.addressZipcode!.isNotEmpty) parts.add(widget.addressZipcode!);
    if (widget.addressCity != null && widget.addressCity!.isNotEmpty) parts.add(widget.addressCity!);
    return parts.isNotEmpty ? parts.join(', ') : 'Localisation non spécifiée';
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final body = comment['body']?.toString() ?? '';
    final createdAt = comment['created_at']?.toString() ?? '';
    
    // Extract user name from nested profiles
    String displayName = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        displayName = profile['pseudo']?.toString() ?? 
                     user['name']?.toString() ?? 
                     'Utilisateur';
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        displayName = profile['company_name']?.toString() ?? 
                     '${profile['first_name']?.toString() ?? ''} ${profile['last_name']?.toString() ?? ''}'.trim();
        if (displayName.isEmpty) displayName = user['name']?.toString() ?? 'Utilisateur';
      } else {
        displayName = user['name']?.toString() ?? 'Utilisateur';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF3AAE5E).withOpacity(0.1),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Color(0xFF3AAE5E),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet() {
    if (widget.trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les commentaires')),
      );
      return;
    }
    
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
                final token = await TokenStorage.getAccessToken();
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter')),
                  );
                  return;
                }
                
                final response = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/trainings/${widget.trainingId}/comments'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({'body': text}),
                );
                
                if (response.statusCode == 201 || response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  final newComment = data['data'] as Map<String, dynamic>?;
                  if (newComment != null) {
                    modalSetState(() {
                      _comments.insert(0, newComment);
                      _commentsCount++;
                    });
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
                }
              } catch (e) {
                debugPrint('Error posting comment: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur lors de l\'envoi')),
                );
              }
            }
            
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_commentsCount commentaire${_commentsCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                    'Aucun commentaire',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _comments.length,
                                  itemBuilder: (context, index) {
                                    return _buildCommentItem(_comments[index]);
                                  },
                                ),
                    ),
                    // Input field
                    Container(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
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
                                hintText: 'Ajouter un commentaire...',
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: submitComment,
                            icon: const Icon(Icons.send, color: Color(0xFF3AAE5E)),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Helper method for colored category tags (like job detail)
  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for gray detail tags (like job detail)
  Widget _buildDetailTag(FormationTag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tag.isSpecial ? const Color(0xFFE6F7EF) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tag.isSpecial ? const Color(0xFF3AAE5E).withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 14,
            color: tag.isSpecial ? const Color(0xFF3AAE5E) : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: tag.isSpecial ? FontWeight.w600 : FontWeight.w500,
              color: tag.isSpecial ? const Color(0xFF3AAE5E) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to similar training detail
  Future<void> _navigateToSimilarTraining(Map<String, dynamic> training) async {
    final trainingId = training['id']?.toString();
    if (trainingId == null || trainingId.isEmpty) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId'),
        headers: {
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
          'Accept': 'application/json',
        },
      );

      Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trainingData = data['data'] as Map<String, dynamic>?;
        if (trainingData == null) return;

        // Extract training details
        final title = trainingData['title']?.toString() ?? '';
        final description = trainingData['description']?.toString() ?? '';
        final descriptionDelta = trainingData['description_delta'];
        final companyName = trainingData['company_name']?.toString() ?? 'Organisme';
        final website = trainingData['website']?.toString();
        final trainingType = trainingData['training_type']?.toString();
        final trainingCategory = trainingData['training_category']?.toString();
        final trainingSubCategory = trainingData['training_sub_category']?.toString();
        final trainingStyle = (trainingData['training_style'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final trainingPublic = (trainingData['training_public'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final requiredLevels = (trainingData['required_levels'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final price = trainingData['price']?.toString();
        final priceType = trainingData['price_type']?.toString();
        final publicType = trainingData['public_type']?.toString();
        final tempo = trainingData['tempo']?.toString();
        final trainingFunding = (trainingData['training_funding'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final durationInH = trainingData['duration_in_h'] is int ? trainingData['duration_in_h'] as int : int.tryParse(trainingData['duration_in_h']?.toString() ?? '');
        final durationUnit = trainingData['duration_unit']?.toString();
        final startDate = trainingData['start_date']?.toString();
        final endDate = trainingData['end_date']?.toString();
        final dateToDefine = trainingData['date_to_define'] == true;
        final addressCity = trainingData['address_city']?.toString();
        final addressZipcode = trainingData['address_zipcode']?.toString();
        final addressLine1 = trainingData['address_line1']?.toString();
        final showLocation = trainingData['show_location'] == true;
        final certification = (trainingData['certification'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final mediaFiles = trainingData['media_files'] as List? ?? trainingData['media'] as List? ?? [];
        final documentFiles = trainingData['document_files'] as List? ?? trainingData['documents'] as List? ?? [];
        final createdAt = trainingData['created_at']?.toString();
        final userData = trainingData['user'] as Map<String, dynamic>?;

        // Build images
        final images = mediaFiles
            .where((m) => m is Map && m['url'] != null)
            .map((m) {
              final url = m['url']?.toString() ?? '';
              if (url.startsWith('http')) return url;
              final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
              return '$serverBase/storage/$url';
            })
            .where((url) => url.isNotEmpty)
            .toList();

        // Build tags
        final tags = <FormationTag>[
          if (trainingCategory != null && trainingCategory.isNotEmpty)
            FormationTag(icon: Icons.category_outlined, text: trainingCategory),
          if (trainingSubCategory != null && trainingSubCategory.isNotEmpty)
            FormationTag(icon: Icons.subdirectory_arrow_right, text: trainingSubCategory),
          if (trainingType != null && trainingType.isNotEmpty)
            FormationTag(icon: Icons.school_outlined, text: trainingType),
          if (durationInH != null)
            FormationTag(icon: Icons.timer_outlined, text: '$durationInH h'),
          if (price != null)
            FormationTag(icon: Icons.euro, text: '$price €', isSpecial: true),
        ];

        // Navigate to detail screen
        await Navigator.push(
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
              timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
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
              documents: documentFiles.whereType<Map<String, dynamic>>().toList(),
              isOwner: false,
              trainingId: trainingId,
              trainingData: trainingData,
              returnToListingOnEdit: false,
              authorData: userData,
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error navigating to similar training: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  String _timeAgo(String isoDate) {
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

  // Helper method for detail items (like job detail)
  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Open website URL
  void _openWebsite(BuildContext context) {
    if (widget.website != null && widget.website!.isNotEmpty) {
      _launchUrl(widget.website!);
    }
  }

  // Navigate to user profile
  void _navigateToUserProfile(BuildContext context) {
    if (widget.authorData != null && widget.authorData!['id'] != null) {
      // TODO: Navigate to PublicProfileScreen if available
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => PublicProfileScreen(userId: widget.authorData!['id'].toString()),
      //   ),
      // );
    }
  }

  // Download programme document
  Future<void> _downloadProgramme() async {
    if (widget.documents.isEmpty) return;

    final document = widget.documents.first;
    final String? url = document['url']?.toString();
    final String? fileName = document['file_name']?.toString() ?? 'programme.pdf';

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document non disponible')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );

      // Get directory for download
      // On Android 10+, we use app's external storage directory to avoid scoped storage issues
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          throw Exception('Impossible d\'accéder au stockage externe');
        }
        // Create a Downloads subfolder in app's external storage
        downloadsDir = Directory('${downloadsDir.path}/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('Impossible d\'accéder au dossier Downloads');
        }
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String safeFileName = fileName?.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_') ?? 'programme.pdf';
      final String finalFileName = '${timestamp}_$safeFileName';
      final String savePath = '${downloadsDir.path}/$finalFileName';

      // Download file using Dio
      final dio = Dio();
      final token = await TokenStorage.getAccessToken();
      
      await dio.download(
        url,
        savePath,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document téléchargé: $finalFileName'),
          backgroundColor: const Color(0xFF3AAE5E),
        ),
      );
    } catch (e) {
      debugPrint('Error downloading document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
