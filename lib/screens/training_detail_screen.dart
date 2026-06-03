import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// Bouton partager masqué
// import 'package:myreklam/services/share_service.dart';
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
import 'package:myreklam/widgets/report_reason_dialog.dart';
import 'package:myreklam/screens/creer_formation_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/utils/subscription_helper.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
// Bouton partager masqué
// import 'package:share_plus/share_plus.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart' show CustomBottomBar;

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
  final String? locationCity;
  final String? locationPostalCode;
  final bool showLocation;
  final List<String> certification;
  final List<Map<String, dynamic>> documents;
  final bool isOwner;
  final String? trainingId;
  final Map<String, dynamic>? trainingData;
  final bool returnToListingOnEdit;
  // Author data for follow functionality
  final Map<String, dynamic>? authorData;
  final int? commentsCount;

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
    this.locationCity,
    this.locationPostalCode,
    this.showLocation = false,
    this.certification = const [],
    this.documents = const [],
    this.isOwner = false,
    this.trainingId,
    this.trainingData,
    this.returnToListingOnEdit = false,
    this.authorData,
    this.commentsCount,
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
  int? _localCommentsCount;
  bool _isLiked = false;
  int _likesCount = 0;
  List<Map<String, dynamic>> _similarTrainings = [];
  bool _isLoadingSimilar = false;

  /// Check if edit option should be shown
  bool get _canEdit {
    return widget.isOwner;
  }


  @override
  void initState() {
    super.initState();
    _localCommentsCount = widget.commentsCount;
    _commentsCount = widget.commentsCount ?? 0;
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
        Uri.parse(
          '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/comments?per_page=50',
        ),
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
        Uri.parse(
          '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/similar?limit=3',
        ),
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
        Uri.parse(
          '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/reactions',
        ),
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
          _likesCount =
              data['data']?['likes_count'] ??
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

  Future<void> _checkSubscriptionStatus() async {
    if (widget.isOwner || widget.trainingId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/subscription',
        ),
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
        Uri.parse(
          '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/subscribe',
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoadingSubscription = false);
    }
  }

  void _showSubscriptionDialog() {
    if (widget.trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de s\'inscrire à cette formation'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
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
          Uri.parse(
            '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() => _isFavorite = false);
          debugPrint('Removed from favorites');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
        }
      } else {
        // Favorite
        debugPrint('=== ADD FAVORITE ===');
        debugPrint('trainingId: ${widget.trainingId}');
        final response = await http.post(
          Uri.parse(
            '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        debugPrint('Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => _isFavorite = true);
          debugPrint('Added to favorites');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
        rawUrl =
            user['pro_profile']['avatar_url']?.toString() ??
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
      final particulierProfile =
          user['particulier_profile'] as Map<String, dynamic>?;

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

  String _stripHtml(String text) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return text.replaceAll(exp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Handle already complete URLs (both http:// and https://)
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return url;
    }
    // Handle URLs that might incorrectly start with /storage/ followed by http
    if (url.startsWith('/storage/http')) {
      // Extract the actual URL after /storage/
      final actualUrl = url.substring(9); // Remove '/storage/'
      if (actualUrl.toLowerCase().startsWith('http://') ||
          actualUrl.toLowerCase().startsWith('https://')) {
        return actualUrl;
      }
    }
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$serverBase/storage/$cleanUrl';
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

  String? _currentUserId;

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

      // Refresh bottom bar avatar when user data is fetched
      CustomBottomBar.refreshAvatarNotifier.value = true;

      return id;
    } catch (e) {
      debugPrint('Error fetching current user ID: $e');
      return _currentUserId;
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
            commentsCount: _tryAsInt(data['comments_count']),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
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
          'Details de la formation',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreerFormationScreen(
                          trainingId: widget.trainingId,
                          initialData: widget.trainingData,
                          shouldReturnToListingOnSuccess:
                              widget.returnToListingOnEdit,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  if (_canEdit)
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
            // 1. Image Carousel - full width
            if (widget.images.isNotEmpty) ImageCarousel(images: widget.images),

            // 2. Main content section - no card, edge to edge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tags
                  if (widget.trainingCategory != null ||
                      widget.trainingType != null)
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
                  if (widget.trainingCategory != null ||
                      widget.trainingType != null)
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
                      value: widget.trainingStyle
                          .map(_formatEnumLabel)
                          .join(', '),
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
                      value: widget.trainingPublic
                          .map(_formatEnumLabel)
                          .join(', '),
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
                      value:
                          '${widget.durationInH} ${_durationUnitLabel(widget.durationUnit)}',
                    ),
                  if (widget.durationInH != null) const SizedBox(height: 12),
                  // 5. Dates
                  if (!widget.dateToDefine &&
                      (widget.startDate != null || widget.endDate != null))
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
                  if (widget.startDate != null ||
                      widget.endDate != null ||
                      widget.dateToDefine)
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
            if (widget.documents.isNotEmpty) const SizedBox(height: 16),

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
                          backgroundColor: _isSubscribed
                              ? Colors.grey
                              : const Color(0xFFFF9800),
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
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Inscrit',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              )
                            : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.website != null && widget.website!.isNotEmpty
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

            // 6. Action buttons row (Favoris - Share button commented out)
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // Bouton partager masqué
                //         color: Colors.grey[600],
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. Company/Owner section - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar
                  ReklamAvatar(
                    avatarUrl: _resolveAvatarUrl(),
                    displayName: _resolveOwnerName(),
                    radius: 24,
                    accountType: _resolveUserType(),
                    onTap: widget.authorData != null
                        ? () => _navigateToUserProfile(context)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name and user type
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.authorData != null
                          ? () => _navigateToUserProfile(context)
                          : null,
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

            // 8. Posted time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.timeAgo.isNotEmpty ? widget.timeAgo : 'Posté récemment',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),

            // 9. Localisation - no card
            if (widget.showLocation &&
                (widget.addressCity != null || widget.addressLine1 != null))
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
            if (widget.showLocation &&
                (widget.addressCity != null || widget.addressLine1 != null))
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
                        '${_localCommentsCount ?? _comments.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => SubscriptionHelper.guardFeature(
                        context,
                        ProFeature.commentAndReact,
                        () => _showCommentsSheet(),
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
            const SizedBox(height: 32),

            // 11. Similar formations header
            if (_similarTrainings.isNotEmpty || _isLoadingSimilar) ...[
              const Center(
                child: Text(
                  'Autres formations qui pourraient vous intéresser',
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
                ),
                child: Container(height: 1, color: Colors.grey[300]),
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
                    final trainingId = training['id']?.toString() ?? '';
                    final title = training['title']?.toString() ?? 'Formation';
                    final description = _stripHtml(
                      training['description']?.toString() ?? '',
                    );
                    final provider =
                        training['provider_name']?.toString() ?? 'Organisme';
                    final duration = training['duration_in_h'];
                    final durationUnit = training['duration_unit']?.toString();
                    final price = training['price'];
                    final category =
                        training['training_category']?.toString() ?? '';
                    final subCategory =
                        training['training_sub_category']?.toString() ?? '';
                    final trainingType =
                        training['training_type']?.toString() ?? '';

                    final addressCity =
                        training['address_city']?.toString() ?? '';

                    // Helper to extract array values
                    String _extractArrayValues(dynamic field) {
                      if (field is List) {
                        return field
                            .map((item) {
                              if (item is Map)
                                return item['value']?.toString() ??
                                    item['name']?.toString() ??
                                    '';
                              return item.toString();
                            })
                            .where((s) => s.isNotEmpty)
                            .join(' · ');
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
                      final translated = trainingStyleRaw
                          .map((item) {
                            final value = item is Map
                                ? (item['value']?.toString() ?? item.toString())
                                : item.toString();
                            return _translateTrainingStyle(value);
                          })
                          .where((s) => s.isNotEmpty)
                          .join(' · ');
                      trainingStyleText = translated;
                    } else if (trainingStyleRaw != null) {
                      trainingStyleText = _translateTrainingStyle(
                        trainingStyleRaw.toString(),
                      );
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
                      final translated = trainingPublicRaw
                          .map((item) {
                            final value = item is Map
                                ? (item['value']?.toString() ?? item.toString())
                                : item.toString();
                            return _translateTrainingPublic(value);
                          })
                          .where((s) => s.isNotEmpty)
                          .join(' · ');
                      trainingPublicText = translated;
                    } else if (trainingPublicRaw != null) {
                      trainingPublicText = _translateTrainingPublic(
                        trainingPublicRaw.toString(),
                      );
                    }

                    final certification = _extractArrayValues(
                      training['certification'],
                    );

                    // Check if CPF is in training_funding array
                    final trainingFunding = training['training_funding'];
                    bool hasCpf = false;
                    if (trainingFunding is List) {
                      hasCpf = trainingFunding.any(
                        (funding) =>
                            funding.toString().toUpperCase() == 'CPF' ||
                            (funding is Map &&
                                funding['type']?.toString().toUpperCase() ==
                                    'CPF'),
                      );
                    }

                    final tags = <FormationTag>[
                      // 1st: Address city (location)
                      if (addressCity.isNotEmpty)
                        FormationTag(
                          icon: Icons.location_on_outlined,
                          text: addressCity,
                        ),
                      // 2nd: Training public (translated)
                      if (trainingPublicText.isNotEmpty)
                        FormationTag(
                          icon: Icons.people_outline,
                          text: trainingPublicText,
                        ),
                      // 3rd: Training style (translated)
                      if (trainingStyleText.isNotEmpty)
                        FormationTag(
                          icon: Icons.style_outlined,
                          text: trainingStyleText,
                        ),
                      // 4th: Certification
                      if (certification.isNotEmpty)
                        FormationTag(
                          icon: Icons.verified_outlined,
                          text: certification,
                        ),
                      // 5th: CPF eligibility
                      if (hasCpf)
                        FormationTag(
                          icon: Icons.account_balance_wallet_outlined,
                          text: 'Eligible CPF',
                        ),
                      // 6th: Training type
                      if (trainingType.isNotEmpty)
                        FormationTag(
                          icon: Icons.school_outlined,
                          text: trainingType,
                        ),
                      // 7th: Duration
                      if (duration != null)
                        FormationTag(
                          icon: Icons.timer_outlined,
                          text:
                              '$duration h${durationUnit != null ? ' / $durationUnit' : ''}',
                        ),
                      // 8th: Price (special/green) - LAST
                      if (price != null) ...[
                        () {
                          final publicType =
                              training['public_type']?.toString() ?? '';
                          String priceText = '$price €';
                          if (publicType == 'personne') {
                            priceText += ' - Par personne';
                          } else if (publicType == 'groupe') {
                            priceText += ' - Par groupe';
                          }
                          return FormationTag(
                            icon: Icons.euro,
                            text: priceText,
                            isSpecial: true,
                          );
                        }(),
                      ],
                    ];

                    final user = training['user'] as Map<String, dynamic>?;
                    final proProfile =
                        user?['pro_profile'] as Map<String, dynamic>?;
                    final particulierProfile =
                        user?['particulier_profile'] as Map<String, dynamic>?;

                    final avatarUrl =
                        proProfile?['logo_url']?.toString() ??
                        proProfile?['avatar_url']?.toString() ??
                        particulierProfile?['avatar_url']?.toString() ??
                        user?['avatar']?.toString();

                    final companyLogoUrl =
                        _buildStorageUrl(avatarUrl) ??
                        'assets/images/Formation.png';

                    // Extract owner name from profiles
                    final ownerName =
                        proProfile?['company_name']?.toString() ??
                        proProfile?['first_name']?.toString() ??
                        particulierProfile?['pseudo']?.toString() ??
                        particulierProfile?['first_name']?.toString() ??
                        training['provider_name']?.toString() ??
                        'Organisme';

                    // Check if already favorited by current user
                    final favoris =
                        training['training_favorites'] as List? ?? [];
                    final currentUserId = UserSession().id;
                    final bool initialIsFavorited =
                        currentUserId != null &&
                        favoris.any(
                          (f) =>
                              f is Map &&
                              (f['user_id']?.toString() == currentUserId ||
                                  f['user']?['id']?.toString() ==
                                      currentUserId),
                        );

                    // Use ValueNotifier for state that persists across rebuilds
                    final isFavoritedNotifier = ValueNotifier<bool>(
                      initialIsFavorited,
                    );

                    return StatefulBuilder(
                      builder: (context, setState) {
                        bool isLoading = false;

                        Future<void> _toggleFavorite() async {
                          if (isLoading || trainingId.isEmpty) return;

                          // Toggle immediately for responsive UI
                          isFavoritedNotifier.value =
                              !isFavoritedNotifier.value;
                          setState(() => isLoading = true);

                          try {
                            if (!isFavoritedNotifier.value) {
                              // Remove from favorites
                              await ApiClient().authenticatedDelete(
                                '/trainings/$trainingId/favorite',
                              );
                              // Update the underlying data to persist state across rebuilds
                              if (training['training_favorites'] is List) {
                                (training['training_favorites'] as List)
                                    .removeWhere(
                                      (f) =>
                                          f is Map &&
                                          (f['user_id']?.toString() ==
                                                  currentUserId ||
                                              f['user']?['id']?.toString() ==
                                                  currentUserId),
                                    );
                              }
                            } else {
                              // Add to favorites
                              await ApiClient().authenticatedPost(
                                '/trainings/$trainingId/favorite',
                              );
                              // Update the underlying data to persist state across rebuilds
                              if (training['training_favorites'] is! List) {
                                training['training_favorites'] = [];
                              }
                              (training['training_favorites'] as List).add({
                                'user_id': currentUserId,
                                'user': {'id': currentUserId},
                              });
                            }

                            setState(() {
                              isLoading = false;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavoritedNotifier.value
                                        ? 'Ajouté aux favoris'
                                        : 'Retiré des favoris',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Favorite toggle error: $e');
                            setState(() => isLoading = false);

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

                        return FormationCard(
                          companyLogo: companyLogoUrl,
                          companyName: ownerName,
                          formationTitle: title,
                          description: description.isNotEmpty
                              ? description
                              : 'Description non disponible.',
                          tags: tags,
                          timeAgo: _buildTimeAgo(
                            training['created_at']?.toString(),
                          ),
                          isFavorited: isFavoritedNotifier.value,
                          isLoadingFavorite: isLoading,
                          onFavoriteToggle: _toggleFavorite,
                          onApply: () => _navigateToTrainingDetail(training),
                          onReport: canReportResource(training)
                              ? () => showAnnouncementReportDialog(
                                    context: context,
                                    entityType: 'trainings',
                                    entityId: trainingId,
                                    title: title,
                                  )
                              : null,
                          onAvatarTap: () {
                            if (user?['id'] != null) {
                              final isProUser =
                                  user?['account_type']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'pro';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => isProUser
                                      ? ProPublicViewScreen(
                                          userId: user!['id'].toString(),
                                        )
                                      : ParticulierPublicViewScreen(
                                          userId: user!['id'].toString(),
                                        ),
                                ),
                              );
                            }
                          },
                          reactionBar: trainingId.isNotEmpty
                              ? Builder(
                                  builder: (ctx) {
                                    _seedReaction(
                                      'trainings',
                                      trainingId,
                                      training,
                                    );
                                    return _buildReactionBar(
                                      'trainings',
                                      trainingId,
                                    );
                                  },
                                )
                              : null,
                        );
                      },
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
      ],
    );
  }

  Widget _buildDescription() {
    // Show plain text description instead of delta
    if (widget.description.isNotEmpty) {
      return Text(
        widget.description,
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
      );
    }

    // Fallback: try to render delta if description is empty
    if (widget.descriptionDelta != null &&
        widget.descriptionDelta.toString().isNotEmpty) {
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
      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
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
        const SnackBar(
          content: Text('Impossible de supprimer cette formation'),
        ),
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
              'Supprimer la formation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette formation ? Cette action est irréversible.',
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
                              '${ApiConfig.baseUrl}/trainings/${widget.trainingId}',
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
                                content: Text(
                                  'Formation supprimée avec succès',
                                ),
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

  String _durationUnitLabel(String? unit) {
    switch (unit) {
      case '0':
        return 'heures';
      case '1':
        return 'jours';
      case '2':
        return 'semaines';
      case '3':
        return 'mois';
      case '4':
        return 'années';
      default:
        return 'heures';
    }
  }

  String _formatDates(String? start, String? end) {
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      try {
        final date = DateTime.parse(dateStr);
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
      case '1':
        return 'NET';
      case '2':
        return 'HT';
      case '3':
        return 'TTC';
      default:
        return '';
    }
  }

  String _tempoLabel(String? t) {
    switch (t) {
      case 'heure':
        return 'par heure(s)';
      case 'jour':
        return 'par jour(s)';
      case 'semaine':
        return 'par semaine(s)';
      case 'mois':
        return 'par mois(s)';
      case 'an':
        return 'par an(s)';
      case 'all':
        return 'pour toute la formation';
      default:
        return '';
    }
  }

  String _publicTypeLabel(String? type) {
    switch (type) {
      case 'personne':
        return '/ personne';
      case 'groupe':
        return '/ groupe';
      default:
        return '';
    }
  }

  String _buildLocationString() {
    final parts = <String>[];
    if (widget.addressLine1 != null && widget.addressLine1!.isNotEmpty)
      parts.add(widget.addressLine1!);
    if (widget.addressZipcode != null && widget.addressZipcode!.isNotEmpty)
      parts.add(widget.addressZipcode!);
    if (widget.addressCity != null && widget.addressCity!.isNotEmpty)
      parts.add(widget.addressCity!);
    return parts.isNotEmpty ? parts.join(', ') : 'Localisation non spécifiée';
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment, {
    bool isReply = false,
    void Function(int id, String name)? onReply,
    void Function(Map<String, dynamic>)? onEdit,
    void Function(Map<String, dynamic>, bool)? onDelete,
  }) {
    final user = comment['user'] as Map<String, dynamic>?;
    final body = comment['body']?.toString() ?? '';
    final createdAt = comment['created_at'];

    // Extract user name from nested profiles
    String displayName = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        displayName =
            profile['pseudo']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        displayName =
            profile['company_name']?.toString() ??
            '${profile['first_name']?.toString() ?? ''} ${profile['last_name']?.toString() ?? ''}'
                .trim();
        if (displayName.isEmpty)
          displayName = user['name']?.toString() ?? 'Utilisateur';
      } else {
        displayName = user['name']?.toString() ?? 'Utilisateur';
      }
    }

    // Extract avatar URL
    String? rawAvatarUrl;
    if (user != null) {
      if (user['particulier_profile'] != null) {
        rawAvatarUrl = user['particulier_profile']['avatar_url']?.toString();
      } else if (user['pro_profile'] != null) {
        rawAvatarUrl = user['pro_profile']['avatar_url']?.toString();
      }
    }
    final avatarUrl = ApiConfig.resolveMediaUrl(rawAvatarUrl);

    // Relative time
    String timeAgo = 'Il y a un moment';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
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
              ReklamAvatar(
                avatarUrl: avatarUrl,
                displayName: displayName,
                radius: isReply ? 14 : 18,
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
                        if (isOwner &&
                            (onEdit != null || onDelete != null)) ...[
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
                                  onEdit?.call(comment);
                                else if (value == 'delete')
                                  onDelete?.call(comment, isReply);
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
                    if (!isReply && onReply != null)
                      GestureDetector(
                        onTap: () {
                          final commentId = comment['id'];
                          final idInt = commentId is int
                              ? commentId
                              : int.tryParse(commentId?.toString() ?? '');
                          if (idInt != null) onReply(idInt, displayName);
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
          if (!isReply && replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...replies.map(
              (r) => _buildCommentItem(
                r,
                isReply: true,
                onReply: onReply,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ],
        ],
      ),
    ));
  }

  void _showCommentsSheet() async {
    if (widget.trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les commentaires')),
      );
      return;
    }
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
                final token = await TokenStorage.getAccessToken();
                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter')),
                  );
                  return;
                }

                final String endpoint = replyingToId != null
                    ? '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/comments/$replyingToId/reply'
                    : '${ApiConfig.baseUrl}/trainings/${widget.trainingId}/comments';
                final wasReply = replyingToId != null;

                final response = await http.post(
                  Uri.parse(endpoint),
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
                      if (wasReply) {
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
                        _comments.insert(0, newComment);
                        _commentsCount++;
                      }
                      replyingToId = null;
                      replyingToName = null;
                    });
                    if (!wasReply) {
                      setState(() {
                        _localCommentsCount =
                            (_localCommentsCount ?? _comments.length) + 1;
                      });
                    }
                  }
                  commentCtrl.clear();
                  FocusScope.of(ctx).unfocus();

                  // Refresh comments from API to ensure count is accurate
                  await _fetchComments();

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
                  _comments.removeWhere((c) => c['id'] == commentId);
                  if (_localCommentsCount != null && _localCommentsCount! > 0) {
                    _localCommentsCount = _localCommentsCount! - 1;
                  }
                });
                modalSetState(() {
                  if (_commentsCount > 0) _commentsCount--;
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
                                return _buildCommentItem(
                                  _comments[index],
                                  onReply: (id, name) {
                                    modalSetState(() {
                                      replyingToId = id;
                                      replyingToName = name;
                                    });
                                  },
                                  onEdit: editComment,
                                  onDelete: deleteComment,
                                );
                              },
                            ),
                    ),
                    if (replyingToName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Répondre à $replyingToName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
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
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF3AAE5E),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Bouton partager masqué
  // void _shareTraining() { ... }

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

  // --- Reaction infrastructure for similar items ---
  final Map<String, _ReactionData> _reactions = {};
  String _rKey(String s, String id) => '${s}_$id';
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  _ReactionData _getReaction(String s, String id) =>
      _reactions.putIfAbsent(_rKey(s, id), () => _ReactionData());
  void _seedReaction(String s, String id, Map<String, dynamic> r) {
    _reactions.putIfAbsent(
      _rKey(s, id),
      () => _ReactionData(
        likesCount: _asInt(r['likes_count']),
        commentsCount: _asInt(r['comments_count']),
        userReaction: r['user_reaction']?.toString(),
      ),
    );
  }

  Future<void> _toggleReaction(String s, String id, String type) async {
    final d = _getReaction(s, id);
    final wasLiked = d.userReaction == 'like';
    setState(() {
      if (wasLiked) {
        d.userReaction = null;
        if (d.likesCount > 0) d.likesCount--;
      } else {
        d.userReaction = 'like';
        d.likesCount++;
      }
    });
    try {
      if (wasLiked)
        await ApiClient().authenticatedDelete('/$s/$id/reactions');
      else
        await ApiClient().authenticatedPost(
          '/$s/$id/reactions',
          body: {'type': type},
        );
      final res = await ApiClient().authenticatedGet('/$s/$id');
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null && mounted)
        setState(() {
          _reactions[_rKey(s, id)] = _ReactionData(
            likesCount: _asInt(data['likes_count']),
            commentsCount: _asInt(data['comments_count']),
            userReaction: data['user_reaction']?.toString(),
          );
        });
    } catch (_) {
      setState(() {
        if (wasLiked) {
          d.userReaction = 'like';
          d.likesCount++;
        } else {
          d.userReaction = null;
          if (d.likesCount > 0) d.likesCount--;
        }
      });
    }
  }

  void _showEntityCommentsSheet(String s, String id) async {
    await _getCurrentUserId();
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    final ctrl = TextEditingController();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, ms) {
          if (isLoading && comments.isEmpty) {
            ApiClient()
                .authenticatedGet('/$s/$id/comments?per_page=50')
                .then((res) {
                  final data = res['data'];
                  List<Map<String, dynamic>> fetched = [];
                  if (data is Map && data['data'] is List)
                    fetched = List<Map<String, dynamic>>.from(data['data']);
                  else if (data is List)
                    fetched = List<Map<String, dynamic>>.from(data);
                  ms(() {
                    comments = fetched;
                    isLoading = false;
                  });
                })
                .catchError((_) {
                  ms(() => isLoading = false);
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

            final text = ctrl.text.trim();
            if (text.isEmpty) return;

            try {
              Map<String, dynamic> res;
              if (replyingToId != null) {
                res = await ApiClient().authenticatedPost(
                  '/$s/$id/comments/$replyingToId/reply',
                  body: {'body': text},
                );
              } else {
                res = await ApiClient().authenticatedPost(
                  '/$s/$id/comments',
                  body: {'body': text},
                );
              }

              final nc = res['data'] as Map<String, dynamic>?;
              if (nc != null) {
                ms(() {
                  if (replyingToId != null) {
                    final parent = comments.firstWhere(
                      (c) => c['id'] == replyingToId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.add(nc);
                      parent['replies'] = replies;
                      parent['replies_count'] =
                          (parent['replies_count'] as int? ?? 0) + 1;
                    }
                  } else {
                    comments.insert(0, nc);
                  }
                  replyingToId = null;
                  replyingToName = null;
                });
                setState(() {
                  _getReaction(s, id).commentsCount++;
                });
              }
              ctrl.clear();
              FocusScope.of(ctx).unfocus();
            } catch (e) {
              if (ctx.mounted)
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
              final updatedComment = response['data'] as Map<String, dynamic>?;
              if (updatedComment != null) {
                ms(() {
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

              ms(() {
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

              if (!isReply) {
                setState(() {
                  _getReaction(
                    s,
                    id,
                  ).commentsCount = (_getReaction(s, id).commentsCount > 0)
                      ? _getReaction(s, id).commentsCount - 1
                      : 0;
                });
              }
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
            final commentId = comment['id'];
            final commentIdInt = commentId is int
                ? commentId
                : int.tryParse(commentId?.toString() ?? '');

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
                    '${profile['first_name']?.toString() ?? ''} ${profile['last_name']?.toString() ?? ''}'
                        .trim();
                if (displayName.isEmpty)
                  displayName = user['name']?.toString() ?? 'Utilisateur';
              } else {
                displayName = user['name']?.toString() ?? 'Utilisateur';
              }
            }

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

            final body = comment['body']?.toString() ?? '';
            final createdAt = comment['created_at'];
            String timeAgo = 'à l\'instant';
            if (createdAt != null) {
              try {
                final date = DateTime.parse(createdAt.toString());
                final diff = DateTime.now().difference(date);
                if (diff.inDays > 0) {
                  timeAgo = 'Il y a ${diff.inDays}j';
                } else if (diff.inHours > 0) {
                  timeAgo = 'Il y a ${diff.inHours}h';
                } else if (diff.inMinutes > 0) {
                  timeAgo = 'Il y a ${diff.inMinutes}min';
                } else {
                  timeAgo = 'à l\'instant';
                }
              } catch (_) {}
            }

            final userId = user?['id']?.toString();
            final isOwner = userId != null && userId == _currentUserId;
            final replies = List<Map<String, dynamic>>.from(
              (comment['replies'] as List?) ?? [],
            );
            final likesCount = comment['likes_count'] as int? ?? 0;
            final isLiked = comment['user_reaction']?.toString() == 'like';

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
                      ReklamAvatar(
                        avatarUrl: avatarUrl,
                        displayName: displayName,
                        radius: isReply ? 14 : 18,
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
                            Row(
                              children: [
                                // Like button
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final cid = comment['id'];
                                      if (cid == null) return;
                                      final currentLiked =
                                          comment['user_reaction']
                                              ?.toString() ==
                                          'like';
                                      final currentCount =
                                          comment['likes_count'] as int? ?? 0;
                                      ms(() {
                                        comment['user_reaction'] = currentLiked
                                            ? null
                                            : 'like';
                                        comment['likes_count'] = currentLiked
                                            ? (currentCount > 0
                                                  ? currentCount - 1
                                                  : 0)
                                            : currentCount + 1;
                                      });
                                      if (currentLiked) {
                                        await ApiClient().authenticatedDelete(
                                          '/comments/$cid/reactions',
                                        );
                                      } else {
                                        await ApiClient().authenticatedPost(
                                          '/comments/$cid/reactions',
                                          body: {'type': 'like'},
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('Error liking comment: $e');
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.thumb_up_alt
                                            : Icons.thumb_up_alt_outlined,
                                        size: isReply ? 12 : 14,
                                        color: isLiked
                                            ? const Color(0xFF3AAE5E)
                                            : Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        likesCount.toString(),
                                        style: TextStyle(
                                          fontSize: isReply ? 11 : 12,
                                          color: isLiked
                                              ? const Color(0xFF3AAE5E)
                                              : Colors.grey[600],
                                          fontWeight: isLiked
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Reply button
                                if (!isReply && commentIdInt != null)
                                  GestureDetector(
                                    onTap: () {
                                      ms(() {
                                        replyingToId = commentIdInt;
                                        replyingToName = displayName;
                                      });
                                    },
                                    child: Text(
                                      'Répondre',
                                      style: TextStyle(
                                        fontSize: isReply ? 11 : 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            maxChildSize: 0.95,
            minChildSize: 0.3,
            builder: (_, sc) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commentaires (${comments.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : comments.isEmpty
                        ? const Center(child: Text('Aucun commentaire.'))
                        : ListView.builder(
                            controller: sc,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: comments.length,
                            itemBuilder: (_, i) =>
                                buildCommentItem(comments[i]),
                          ),
                  ),
                  // Reply indicator
                  if (replyingToName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Répondre à $replyingToName',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ms(() {
                              replyingToId = null;
                              replyingToName = null;
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Input area
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 8,
                      left: 12,
                      right: 12,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              hintText: replyingToName != null
                                  ? 'Écrire une réponse...'
                                  : 'Écrire un commentaire...',
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
                        GestureDetector(
                          onTap: submitComment,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3AAE5E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
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
      ),
    );
  }

  Widget _buildSimilarReactionBar(String s, String id) {
    final d = _getReaction(s, id);
    final isLiked = d.userReaction == 'like';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleReaction(s, id, 'like'),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                  size: 18,
                  color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  d.likesCount.toString(),
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
            onTap: () => _showEntityCommentsSheet(s, id),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 17,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  d.commentsCount.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
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
        final companyName =
            trainingData['company_name']?.toString() ?? 'Organisme';
        final website = trainingData['website']?.toString();
        final trainingType = trainingData['training_type']?.toString();
        final trainingCategory = trainingData['training_category']?.toString();
        final trainingSubCategory = trainingData['training_sub_category']
            ?.toString();
        final trainingStyle =
            (trainingData['training_style'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final trainingPublic =
            (trainingData['training_public'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final requiredLevels =
            (trainingData['required_levels'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final price = trainingData['price']?.toString();
        final priceType = trainingData['price_type']?.toString();
        final publicType = trainingData['public_type']?.toString();
        final tempo = trainingData['tempo']?.toString();
        final trainingFunding =
            (trainingData['training_funding'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final durationInH = trainingData['duration_in_h'] is int
            ? trainingData['duration_in_h'] as int
            : int.tryParse(trainingData['duration_in_h']?.toString() ?? '');
        final durationUnit = trainingData['duration_unit']?.toString();
        final startDate = trainingData['start_date']?.toString();
        final endDate = trainingData['end_date']?.toString();
        final dateToDefine = trainingData['date_to_define'] == true;
        final addressCity = trainingData['address_city']?.toString();
        final addressZipcode = trainingData['address_zipcode']?.toString();
        final addressLine1 = trainingData['address_line1']?.toString();
        final showLocation = trainingData['show_location'] == true;
        final certification =
            (trainingData['certification'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final mediaFiles =
            trainingData['media_files'] as List? ??
            trainingData['media'] as List? ??
            [];
        final documentFiles =
            trainingData['document_files'] as List? ??
            trainingData['documents'] as List? ??
            [];
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
              documents: documentFiles
                  .whereType<Map<String, dynamic>>()
                  .toList(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
      final isPro =
          widget.authorData!['account_type']?.toString().toLowerCase() == 'pro';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isPro
              ? ProPublicViewScreen(userId: widget.authorData!['id'].toString())
              : ParticulierPublicViewScreen(
                  userId: widget.authorData!['id'].toString(),
                ),
        ),
      );
    }
  }

  // Download programme document
  Future<void> _downloadProgramme() async {
    // Check subscription for pro users
    if (!SubscriptionHelper.canAccessFeature(
      ProFeature.downloadTrainingPrograms,
    )) {
      if (mounted) {
        SubscriptionHelper.showPremiumRequiredDialog(
          context,
          featureName: 'Télécharger les programmes de formations',
        );
      }
      return;
    }

    if (widget.documents.isEmpty) return;

    final document = widget.documents.first;
    final String? url = document['url']?.toString();
    final String? fileName =
        document['file_name']?.toString() ?? 'programme.pdf';

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Document non disponible')));
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
      final String safeFileName =
          fileName?.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_') ??
          'programme.pdf';
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
