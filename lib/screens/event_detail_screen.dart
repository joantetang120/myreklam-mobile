import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_evenement_screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final List<String> images;
  final String avatar;
  final String username;
  final String userType;
  final String eventTitle;
  final String description;
  final dynamic descriptionDelta;
  final List<PostTag> tags;
  final String timeAgo;
  // Event-specific fields
  final String? categoryCode;
  final String? subCategoryCode;
  final String? formatType;
  final String? durationType;
  final String? eventDate;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? priceType;
  final String? pricingMode;
  final String? priceAmount;
  final List<Map<String, dynamic>> priceCategories;
  final String? reservationMode;
  final String? coverageArea;
  final bool isNationwide;
  final String? organizerName;
  final bool isOrganizer;
  final String? websiteUrl;
  final String? landingUrl;
  final bool acceptMessages;
  final bool isOwner;
  final String? eventId;
  final Map<String, dynamic>? eventData;
  final bool returnToListingOnEdit;
  final Map<String, dynamic>? authorData;

  const EventDetailScreen({
    super.key,
    this.images = const [],
    required this.avatar,
    required this.username,
    this.userType = 'Évènement',
    required this.eventTitle,
    required this.description,
    this.descriptionDelta,
    this.tags = const [],
    this.timeAgo = '',
    this.categoryCode,
    this.subCategoryCode,
    this.formatType,
    this.durationType,
    this.eventDate,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.priceType,
    this.pricingMode,
    this.priceAmount,
    this.priceCategories = const [],
    this.reservationMode,
    this.coverageArea,
    this.isNationwide = false,
    this.organizerName,
    this.isOrganizer = true,
    this.websiteUrl,
    this.landingUrl,
    this.acceptMessages = false,
    this.isOwner = false,
    this.eventId,
    this.eventData,
    this.returnToListingOnEdit = false,
    this.authorData,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isParticipating = false;
  bool _isLoadingParticipation = false;
  
  // Comments state
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  
  // Similar events state
  List<Map<String, dynamic>> _similarEvents = [];
  bool _isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _checkParticipationStatus();
    _fetchComments();
    _fetchSimilarEvents();
  }

  Future<void> _fetchComments() async {
    if (widget.eventId == null) {
      setState(() => _isLoadingComments = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/${widget.eventId}/comments?per_page=50'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> fetched = [];
        if (data['data'] is Map && data['data']['data'] is List) {
          fetched.addAll(List<Map<String, dynamic>>.from(data['data']['data']));
        } else if (data['data'] is List) {
          fetched.addAll(List<Map<String, dynamic>>.from(data['data']));
        }
        setState(() {
          _comments = fetched;
          _isLoadingComments = false;
        });
      } else {
        setState(() => _isLoadingComments = false);
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _fetchSimilarEvents() async {
    if (widget.eventId == null) {
      setState(() => _isLoadingSimilar = false);
      return;
    }
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        setState(() => _isLoadingSimilar = false);
        return;
      }

      // Fetch a larger pool to apply similarity scoring
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/feed/latest?type=event&per_type_limit=30'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = data['data']['items'] as List? ?? [];

          // Extract resource data from each feed item
          final candidates = items.map((item) {
            dynamic resourceData = item['resource'];
            Map<String, dynamic> resource;
            if (resourceData is String) {
              resource = jsonDecode(resourceData) as Map<String, dynamic>;
            } else if (resourceData is Map) {
              resource = Map<String, dynamic>.from(resourceData);
            } else {
              resource = {};
            }
            resource['id'] = item['id'];
            if (resource['user'] == null && item['user'] != null) {
              resource['user'] = item['user'];
            }
            return resource;
          }).where((e) => e['id']?.toString() != widget.eventId).toList();

          // Scoring: rank by similarity criteria
          final scored = candidates.map((e) {
            int score = 0;
            // Même catégorie principale → +3
            if (widget.categoryCode != null &&
                e['category_code']?.toString() == widget.categoryCode) {
              score += 3;
            }
            // Même sous-catégorie → +2
            if (widget.subCategoryCode != null &&
                e['sub_category_code']?.toString() == widget.subCategoryCode) {
              score += 2;
            }
            // Même lieu → +1
            if (widget.coverageArea != null &&
                widget.coverageArea!.isNotEmpty &&
                e['coverage_area']?.toString() == widget.coverageArea) {
              score += 1;
            }
            // Même format → +1
            if (widget.formatType != null &&
                e['format_type']?.toString() == widget.formatType) {
              score += 1;
            }
            return MapEntry(score, e);
          }).toList()
            ..sort((a, b) => b.key.compareTo(a.key));

          // Keep top 5 with at least some criteria matching, fallback to top 5 recent
          var result = scored
              .where((entry) => entry.key > 0)
              .take(5)
              .map((entry) => entry.value)
              .toList();

          if (result.isEmpty) {
            result = scored.take(5).map((entry) => entry.value).toList();
          }

          if (mounted) {
            setState(() {
              _similarEvents = result;
              _isLoadingSimilar = false;
            });
          }
          return;
        }
      }
      if (mounted) setState(() => _isLoadingSimilar = false);
    } catch (e) {
      debugPrint('Error fetching similar events: $e');
      if (mounted) setState(() => _isLoadingSimilar = false);
    }
  }

  Future<void> _navigateToSimilarEvent(Map<String, dynamic> event) async {
    final mediaFiles = event['media_files'] as List? ?? [];
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          images: images,
          avatar: '',
          username: '',
          eventTitle: event['title']?.toString() ?? '',
          description: event['description']?.toString() ?? '',
          descriptionDelta: event['description_delta'],
          timeAgo: event['created_at']?.toString() ?? '',
          eventId: event['id']?.toString(),
          eventData: event,
          authorData: event['user'] as Map<String, dynamic>?,
          priceType: event['price_type']?.toString(),
          priceAmount: event['price_amount']?.toString(),
          pricingMode: event['pricing_mode']?.toString(),
          priceCategories: [],
          reservationMode: event['reservation_mode']?.toString(),
          coverageArea: event['coverage_area']?.toString(),
          websiteUrl: event['website_url']?.toString(),
          categoryCode: event['category_code']?.toString(),
          subCategoryCode: event['sub_category_code']?.toString(),
          formatType: event['format_type']?.toString(),
          durationType: event['duration_type']?.toString(),
          eventDate: event['event_date']?.toString(),
          startDate: event['start_date']?.toString(),
          endDate: event['end_date']?.toString(),
          startTime: event['start_time']?.toString(),
          endTime: event['end_time']?.toString(),
        ),
      ),
    );
  }

  Widget _buildSimilarEventCard(Map<String, dynamic> event) {
    // Extract user data
    final user = event['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile = user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final profileImage = avatarUrl?.isNotEmpty == true
        ? (avatarUrl!.startsWith('http')
            ? avatarUrl
            : '${ApiConfig.baseUrl.replaceAll('/api', '')}/storage/$avatarUrl')
        : 'assets/images/dashboard_particulier/Ellipse 12.png';

    // Extract owner name from profiles
    final ownerName = proProfile?['company_name']?.toString() ??
                      proProfile?['first_name']?.toString() ??
                      particulierProfile?['pseudo']?.toString() ??
                      particulierProfile?['first_name']?.toString() ??
                      user?['name']?.toString() ??
                      'Organisateur';

    final eventTitle = event['title']?.toString() ?? 'Évènement';

    // Extract media
    final mediaFiles = event['media_files'] as List? ?? [];
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
    final eventImage = images.isNotEmpty
        ? images.first
        : 'assets/images/dashboard_particulier/Rectangle 12 (4).png';

    // Categories
    final categories = <String>[
      if (event['category_label']?.toString().isNotEmpty ?? false)
        event['category_label'].toString(),
      if (event['sub_category_label']?.toString().isNotEmpty ?? false)
        event['sub_category_label'].toString(),
    ];

    // Price
    final priceType = event['price_type']?.toString();
    final priceAmount = event['price_amount']?.toString();
    final price = priceType == 'gratuit'
        ? 'Gratuit'
        : (priceAmount?.isNotEmpty == true ? '$priceAmount €' : 'Gratuit');

    // Location
    final coverageArea =
        event['coverage_area']?.toString() ??
        event['location']?.toString() ??
        'Non spécifié';

    // Date
    String eventDate = '';
    final rawDate = event['event_date']?.toString() ?? event['start_date']?.toString() ?? '';
    if (rawDate.isNotEmpty) {
      try {
        final d = DateTime.parse(rawDate);
        const months = [
          'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
          'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
        ];
        eventDate = '${d.day} ${months[d.month - 1]} ${d.year}';
      } catch (_) {
        eventDate = rawDate;
      }
    }

    // Tags
    final tags = <String>[
      if (event['sub_category_code']?.toString().isNotEmpty ?? false)
        event['sub_category_code'].toString(),
      if (event['format_type']?.toString().isNotEmpty ?? false)
        event['format_type'].toString(),
    ];

    final eventId = event['id']?.toString() ?? '';

    return EvenementCard(
      profileImage: profileImage,
      username: ownerName,
      userType: user?['account_type']?.toString() ?? 'particulier',
      eventTitle: eventTitle,
      eventImage: eventImage,
      badge: event['status']?.toString(),
      categories: categories.isNotEmpty ? categories : ['Général'],
      eventDate: eventDate.isNotEmpty ? eventDate : 'Date à définir',
      location: coverageArea,
      timeAgo: event['created_at']?.toString() ?? '',
      price: price,
      likesCount: (event['likes_count'] as int?) ?? 0,
      commentsCount: (event['comments_count'] as int?) ?? 0,
      onTapCTA: () => _navigateToSimilarEvent(event),
      tags: tags.isNotEmpty ? tags : null,
      onAvatarTap: () {
        if (user?['id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PublicProfileScreen(userId: user!['id'].toString()),
            ),
          );
        }
      },
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 365) return 'Il y a ${diff.inDays ~/ 365} an(s)';
      if (diff.inDays > 30) return 'Il y a ${diff.inDays ~/ 30} mois';
      if (diff.inDays > 0) return 'Il y a ${diff.inDays} jour(s)';
      if (diff.inHours > 0) return 'Il y a ${diff.inHours} heure(s)';
      if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes} minute(s)';
      return 'À l\'instant';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _checkFollowStatus() async {
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$authorId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de suivre cet utilisateur')),
      );
      return;
    }

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
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/unfollow'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        );
        if (response.statusCode == 200) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vous ne suivez plus cet utilisateur')),
          );
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/follow'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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

  Future<void> _checkParticipationStatus() async {
    if (widget.isOwner || widget.eventId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/${widget.eventId}/participation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['is_participating'] == true) {
          setState(() => _isParticipating = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking participation status: $e');
    }
  }

  Future<void> _participate() async {
    if (widget.isOwner || widget.eventId == null) return;

    setState(() => _isLoadingParticipation = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/events/${widget.eventId}/participate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        setState(() => _isParticipating = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participation enregistrée avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Vous participez déjà à cet événement')),
        );
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoadingParticipation = false);
    }
  }

  void _showParticipationDialog() {
    if (widget.eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de participer à cet événement')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirmer la participation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment participer à cet événement ?',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Text(
                '"${widget.eventTitle}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Organisateur: ${_resolveOwnerName()}',
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
              onPressed: _isLoadingParticipation
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _participate();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
              child: _isLoadingParticipation
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

  Map<String, dynamic>? _effectiveAuthorData() {
    if (widget.authorData != null) {
      debugPrint('DEBUG: authorData available: ${widget.authorData?.keys}');
      return widget.authorData;
    }
    final user = widget.eventData?['user'];
    debugPrint('DEBUG: eventData user type: ${user?.runtimeType}');
    if (user is Map<String, dynamic>) {
      debugPrint('DEBUG: user keys: ${user.keys}');
      return user;
    }
    // Handle case where user might be a JSON string
    if (user is String) {
      try {
        final decoded = jsonDecode(user);
        if (decoded is Map<String, dynamic>) {
          debugPrint('DEBUG: decoded user from string, keys: ${decoded.keys}');
          return decoded;
        }
      } catch (e) {
        debugPrint('DEBUG: failed to decode user string: $e');
      }
    }
    return null;
  }

  String _resolveOwnerName() {
    final user = _effectiveAuthorData();
    debugPrint('DEBUG: _resolveOwnerName user=null: ${user == null}');
    if (user != null) {
      final proProfile = user['pro_profile'] as Map<String, dynamic>?;
      final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
      debugPrint('DEBUG: pro_profile null: ${proProfile == null}, particulierProfile null: ${particulierProfile == null}');

      if (proProfile != null) {
        final companyName = proProfile['company_name']?.toString();
        if (companyName != null && companyName.isNotEmpty) return companyName;

        final firstName = proProfile['first_name']?.toString() ?? '';
        final lastName = proProfile['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) return fullName;
      }

      if (particulierProfile != null) {
        final pseudo = particulierProfile['pseudo']?.toString();
        if (pseudo != null && pseudo.isNotEmpty) return pseudo;

        final firstName = particulierProfile['first_name']?.toString() ?? '';
        final lastName = particulierProfile['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) return fullName;
      }

      final name = user['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      final email = user['email']?.toString();
      if (email != null && email.isNotEmpty) return email.split('@').first;
    }
    return widget.username;
  }

  String _resolveUserType() {
    final user = _effectiveAuthorData();
    final accountType = user?['account_type']?.toString();
    if (accountType == 'pro') return 'Pro';
    if (accountType == 'particulier') return 'Particulier';
    return widget.userType;
  }

  String _resolveAvatarUrl() {
    final user = _effectiveAuthorData();
    debugPrint('DEBUG: _resolveAvatarUrl user=null: ${user == null}');
    if (user != null) {
      String? rawUrl;
      final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
      final proProfile = user['pro_profile'] as Map<String, dynamic>?;
      debugPrint('DEBUG: avatar sources - logo_url: ${proProfile?['logo_url']}, avatar_url: ${proProfile?['avatar_url']}, particulier: ${particulierProfile?['avatar_url']}, user.avatar: ${user['avatar']}');

      rawUrl =
          proProfile?['logo_url']?.toString() ??
          proProfile?['avatar_url']?.toString() ??
          particulierProfile?['avatar_url']?.toString() ??
          user['avatar']?.toString();

      final resolved = ApiConfig.resolveMediaUrl(rawUrl);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }

    final resolvedFromParam = ApiConfig.resolveMediaUrl(widget.avatar);
    return resolvedFromParam ?? widget.avatar;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
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
          'Détail Évènement',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF616161), size: 24),
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreerEvenementScreen(
                        eventId: widget.eventId,
                        initialData: widget.eventData,
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
            )
          else
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications activées')),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 14),
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
                  // Category tags with icons (like training screen)
                  if (widget.categoryCode != null || widget.formatType != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (widget.categoryCode != null)
                          _buildTag(
                            widget.categoryCode!,
                            Icons.category_outlined,
                            const Color(0xFF9C27B0),
                          ),
                        if (widget.formatType != null)
                          _buildTag(
                            widget.formatType!,
                            Icons.event_available_outlined,
                            Colors.blue,
                          ),
                      ],
                    ),
                  if (widget.categoryCode != null || widget.formatType != null)
                    const SizedBox(height: 12),

                  // Title - big and bold
                  Text(
                    widget.eventTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

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

            // 4. Event details section - no card, full width
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
                  // Sous-catégorie
                  if (widget.subCategoryCode != null && widget.subCategoryCode!.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.subdirectory_arrow_right,
                      iconColor: Colors.orange,
                      bgColor: Colors.orange.withOpacity(0.1),
                      label: "Type d'evenements",
                      value: widget.subCategoryCode!,
                    ),
                  if (widget.subCategoryCode != null && widget.subCategoryCode!.isNotEmpty)
                    const SizedBox(height: 12),
                  // Date
                  if (_hasDateInfo())
                    _buildDetailItem(
                      icon: Icons.event_outlined,
                      iconColor: const Color(0xFF3AAE5E),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Date',
                      value: _buildDateDisplay(),
                    ),
                  if (_hasDateInfo())
                    const SizedBox(height: 12),
                  // Horaires
                  if (widget.startTime != null && widget.startTime!.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.access_time,
                      iconColor: Colors.teal,
                      bgColor: Colors.teal.withOpacity(0.1),
                      label: 'Horaires',
                      value: _buildTimeDisplay(),
                    ),
                  if (widget.startTime != null && widget.startTime!.isNotEmpty)
                    const SizedBox(height: 12),
                  // Organisateur
                  _buildDetailItem(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF1976D2),
                    bgColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    label: 'Organisateur',
                    value: _resolveOwnerName(),
                  ),
                  const SizedBox(height: 12),
                  // Lieu
                  if (widget.coverageArea != null && widget.coverageArea!.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF3AAE5E),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Lieu',
                      value: widget.coverageArea!,
                    ),
                  if (widget.coverageArea != null && widget.coverageArea!.isNotEmpty)
                    const SizedBox(height: 12),
                  // Réservation
                  if (widget.reservationMode != null && widget.reservationMode!.isNotEmpty)
                    _buildDetailItem(
                      icon: Icons.confirmation_num_outlined,
                      iconColor: Colors.purple,
                      bgColor: Colors.purple.withValues(alpha: 0.1),
                      label: 'Réservation',
                      value: widget.reservationMode!,
                    ),
                  if (widget.reservationMode != null && widget.reservationMode!.isNotEmpty)
                    const SizedBox(height: 12),
                  // Prix - même logique que la liste (défaut: Gratuit)
                  _buildPriceSection(),
                  const SizedBox(height: 12),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Site web link button (outside Informations section)
            if (widget.websiteUrl != null && widget.websiteUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(widget.websiteUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Visiter le site web'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
            if (widget.websiteUrl != null && widget.websiteUrl!.isNotEmpty)
              const SizedBox(height: 16),

            // 5. "Je participe" button - full width
            if (!widget.isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isParticipating
                        ? null
                        : () => _showParticipationDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isParticipating ? Colors.grey : const Color(0xFF3AAE5E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isParticipating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Inscrit', style: TextStyle(fontSize: 14)),
                            ],
                          )
                        : const Text(
                            'Je participe',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            if (!widget.isOwner)
              const SizedBox(height: 16),

            // 6. Action buttons row (Favoris, Partager)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.favorite_outline, color: Colors.grey[600], size: 24),
                    ),
                    Text('Favoris', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 24),
                    ),
                    Text('Partager', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                  GestureDetector(
                    onTap: widget.authorData != null ? () => _navigateToUserProfile(context) : null,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: (_resolveAvatarUrl() ?? '').startsWith('http')
                          ? NetworkImage(_resolveAvatarUrl()!)
                          : AssetImage(_resolveAvatarUrl() ?? 'assets/images/Evenement.png') as ImageProvider,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            _resolveUserType(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
            if (widget.coverageArea != null && widget.coverageArea!.isNotEmpty)
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
                      widget.isNationwide
                          ? 'Toute la France'
                          : (widget.coverageArea ?? 'Non spécifié'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.coverageArea != null && widget.coverageArea!.isNotEmpty)
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
                      onPressed: () {},
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

            // 11. Similar events header - always visible
            const Center(
              child: Text(
                'Autres événements similaires',
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
            if (_isLoadingSimilar)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_similarEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _similarEvents.map((event) => _buildSimilarEventCard(event)).toList(),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Aucun événement similaire trouvé',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cet événement')),
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
              'Supprimer l\'événement',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet événement ? Cette action est irréversible.',
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
                            Uri.parse('${ApiConfig.baseUrl}/events/${widget.eventId}'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Événement supprimé avec succès'),
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

  Widget _buildDescription() {
    // Prioritize plain description field over descriptionDelta
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

    // Fallback to descriptionDelta if description is empty
    if (widget.descriptionDelta != null && widget.descriptionDelta.toString().isNotEmpty) {
      try {
        dynamic rawData;
        if (widget.descriptionDelta is List) {
          rawData = widget.descriptionDelta;
        } else if (widget.descriptionDelta is Map) {
          rawData = widget.descriptionDelta;
        } else {
          String jsonString = widget.descriptionDelta.toString();
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
        debugPrint('Error rendering rich text in event detail: $e');
      }
    }

    return Text(
      widget.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF3AAE5E)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _hasDateInfo() {
    return widget.eventDate != null || widget.startDate != null || widget.endDate != null ||
        widget.durationType == 'permanent';
  }

  String _buildDateDisplay() {
    if (widget.durationType == 'permanent') return 'Permanent';
    if (widget.durationType == 'one_day' && widget.eventDate != null) {
      return _formatDate(widget.eventDate!);
    }
    if (widget.durationType == 'multi_day') {
      final start = widget.startDate != null ? _formatDate(widget.startDate!) : '';
      final end = widget.endDate != null ? _formatDate(widget.endDate!) : '';
      if (start.isNotEmpty && end.isNotEmpty) {
        return 'Du $start au $end';
      }
      if (start.isNotEmpty) return 'À partir du $start';
      if (end.isNotEmpty) return "Jusqu'au $end";
    }
    if (widget.eventDate != null) return _formatDate(widget.eventDate!);
    if (widget.startDate != null) return 'À partir du ${_formatDate(widget.startDate!)}';
    return 'Date non spécifiée';
  }

  String _buildTimeDisplay() {
    final start = widget.startTime;
    final end = widget.endTime;

    // Format time without seconds (HH:MM)
    String formatTime(String? time) {
      if (time == null || time.isEmpty) return '';
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}h${parts[1]}';
      }
      return time;
    }

    final startFormatted = formatTime(start);
    final endFormatted = formatTime(end);

    if (startFormatted.isNotEmpty && endFormatted.isNotEmpty) {
      return 'De $startFormatted à $endFormatted';
    } else if (startFormatted.isNotEmpty) {
      return 'À partir de $startFormatted';
    } else if (endFormatted.isNotEmpty) {
      return "Jusqu'à $endFormatted";
    }
    return 'Horaires non spécifiés';
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>?;
    final body = comment['body']?.toString() ?? '';
    final createdAt = comment['created_at']?.toString() ?? '';
    
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _buildPriceDisplay() {
    if (widget.priceType == 'gratuit') return 'Gratuit';
    if (widget.priceAmount != null && widget.priceAmount!.isNotEmpty) {
      return '${widget.priceAmount} €';
    }
    return 'Gratuit';
  }

  String _reservationLabel(String? mode) {
    switch (mode) {
      case 'sans_inscription': return 'Sans inscription';
      case 'inscription': return 'Inscription requise';
      case 'achat_billet': return 'Achat de billet obligatoire';
      default: return mode ?? '';
    }
  }

  Widget _buildTag(String tag, IconData icon, Color color) {
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
          const SizedBox(width: 6),
          Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    // Same logic as event list: default to 'gratuit' if null
    final priceType = widget.priceType?.toLowerCase() ?? 'gratuit';

    if (priceType == 'payant') {
      final pricingMode = widget.pricingMode?.toLowerCase() ?? '';

      // Unique price
      if (pricingMode == 'unique') {
        final amount = widget.priceAmount ?? '';
        return _buildDetailItem(
          icon: Icons.euro,
          iconColor: const Color(0xFFFF9800),
          bgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
          label: 'Prix',
          value: amount.isNotEmpty ? '$amount €' : 'Gratuit',
        );
      }

      // Categories price
      if (pricingMode == 'categories') {
        final validCategories = widget.priceCategories
            .where((c) => (c['tarif']?.toString() ?? '').isNotEmpty)
            .toList();
        if (validCategories.isEmpty) {
          return _buildDetailItem(
            icon: Icons.euro,
            iconColor: const Color(0xFFFF9800),
            bgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
            label: 'Prix',
            value: 'Gratuit',
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.euro, color: Color(0xFFFF9800), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prix',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...validCategories.map((category) {
                    final name = category['name']?.toString() ?? '';
                    final tarif = category['tarif']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '$name: $tarif €',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      }
      
      // payant but unknown pricingMode → Gratuit
      return _buildDetailItem(
        icon: Icons.euro,
        iconColor: const Color(0xFFFF9800),
        bgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
        label: 'Prix',
        value: 'Gratuit',
      );
    }

    // gratuit or unknown price_type → Gratuit
    return _buildDetailItem(
      icon: Icons.euro,
      iconColor: const Color(0xFFFF9800),
      bgColor: const Color(0xFFFF9800).withValues(alpha: 0.1),
      label: 'Prix',
      value: 'Gratuit',
    );
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
}