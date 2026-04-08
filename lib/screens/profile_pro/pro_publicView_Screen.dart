import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ProPublicViewScreen extends StatefulWidget {
  final String? userId; // null means viewing own profile

  const ProPublicViewScreen({super.key, this.userId});

  @override
  State<ProPublicViewScreen> createState() => _ProPublicViewScreenState();
}

class _ReviewEntry {
  final String avatarPath;
  final String name;
  final String timeAgo;
  final String reviewText;
  final int rating;

  const _ReviewEntry({
    required this.avatarPath,
    required this.name,
    required this.timeAgo,
    required this.reviewText,
    required this.rating,
  });
}

class _ProPublicViewScreenState extends State<ProPublicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  final _conversationService = ConversationService();
  final TextEditingController _reviewController = TextEditingController();

  String _selectedAnnonceFilter = 'Tout';

  // Media gallery state
  int _selectedMediaTab = 0; // 0 = photos, 1 = videos

  List<Map<String, dynamic>> _bonPlans = [];
  List<Map<String, dynamic>> _jobOffers = [];
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingAnnonces = true;
  String? _annoncesError;

  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  
  // Reviews - now dynamic from backend
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  String? _reviewsError;
  int _reviewRating = 0;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  bool _isLoadingProfile = true;
  Map<String, dynamic>? _profileResponse;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // Check if viewing own profile by comparing widget.userId with current user's ID
  bool get _isViewingOwnProfile {
    final currentUserId = UserSession().id?.toString();
    final viewingUserId = widget.userId;
    
    // If no userId provided, it's own profile
    if (viewingUserId == null) return true;
    
    // If userId matches current user's ID, it's own profile
    return viewingUserId == currentUserId;
  }

  int get _totalCount =>
      _bonPlans.length +
      _jobOffers.length +
      _events.length +
      _demandes.length +
      _trainings.length;

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

  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _workTimeLabel(String workTime) {
    switch (workTime) {
      case 'full_time':
        return 'Temps plein';
      case 'part_time':
        return 'Temps partiel';
      case 'freelance':
        return 'Freelance';
      case 'internship':
        return 'Stage';
      default:
        return workTime;
    }
  }

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

  Widget _buildJobOffersList() {
    final items = _jobOffers;
    if (items.isEmpty) {
      return const Text(
        'Aucune annonce',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((jo) => _buildJobOfferCard(jo)).toList());
  }

  Widget _buildTrainingsList() {
    final items = _trainings;
    if (items.isEmpty) {
      return const Text(
        'Aucune annonce',
        style: TextStyle(color: Color(0xFF666666)),
      );
    }
    return Column(children: items.map((tr) => _buildTrainingCard(tr)).toList());
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

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final title = (bp['title'] ?? '').toString();
    final category = (bp['category'] ?? '').toString();
    final subCategory = (bp['sub_category'] ?? '').toString();
    final type = (bp['type'] ?? '').toString();
    final status = bp['status']?.toString() ?? '';
    final merchantName = (bp['available_at_name'] ?? '').toString();
    final locationType = (bp['available_location_type'] ?? '').toString();
    final createdAt = bp['created_at']?.toString();
    final mediaFiles = bp['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? mediaFiles.first is Map
              ? (mediaFiles.first['url']?.toString())
              : null
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
          Row(
            children: [
              Expanded(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _statusColor(status).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
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

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'published':
        return const Color(0xFF2A8143);
      case 'draft':
        return Colors.grey;
      case 'expired':
        return Colors.red;
      default:
        return const Color(0xFFEF8A40);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
      case 'published':
        return 'Actif';
      case 'draft':
        return 'Brouillon';
      case 'expired':
        return 'Expiré';
      default:
        return status.isNotEmpty ? status : '—';
    }
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

  Widget _buildJobOfferCard(Map<String, dynamic> jo) {
    final title = (jo['title'] ?? '').toString();
    final description = (jo['description'] ?? '').toString();
    final createdAt = jo['created_at']?.toString();

    final companyRaw = jo['company'];
    final companyName = companyRaw is Map
        ? (companyRaw['name'] ?? '').toString()
        : (companyRaw ?? '').toString();

    final contractType = (jo['contract_type'] ?? '').toString();
    final workTime = (jo['work_time'] ?? '').toString();
    final location = (jo['location'] ?? '').toString();
    final categoryRaw = jo['category'];
    final categoryName = categoryRaw is Map
        ? (categoryRaw['name'] ?? '').toString()
        : (categoryRaw ?? '').toString();
    final salaryMin = jo['salary_min'];
    final salaryMax = jo['salary_max'];

    final advantagesRaw = jo['advantages'] as List? ?? [];
    final advantages = advantagesRaw.take(3).map((a) => a.toString()).toList();

    final user = jo['user'] is Map<String, dynamic>
        ? jo['user'] as Map<String, dynamic>
        : null;

    String cardCompanyName = companyName.isNotEmpty
        ? companyName
        : 'Entreprise';
    String cardCompanyLogo = '';
    if (user != null) {
      if (user['pro_profile'] is Map) {
        final p = user['pro_profile'] as Map;
        final n = p['company_name']?.toString() ?? '';
        if (n.isNotEmpty) cardCompanyName = n;
        final logo =
            p['avatar_url']?.toString() ?? p['logo_url']?.toString() ?? '';
        if (logo.isNotEmpty) cardCompanyLogo = logo;
      } else if (user['particulier_profile'] is Map) {
        final p = user['particulier_profile'] as Map;
        final n = p['pseudo']?.toString() ?? '';
        if (n.isNotEmpty) cardCompanyName = n;
        final logo = p['avatar_url']?.toString() ?? '';
        if (logo.isNotEmpty) cardCompanyLogo = logo;
      }
    }

    final tags = <JobDetailTag>[
      if (contractType.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contractType),
      if (workTime.isNotEmpty)
        JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
      if (location.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: location),
      if (categoryName.isNotEmpty)
        JobDetailTag(icon: Icons.category_outlined, text: categoryName),
      if (salaryMin != null || salaryMax != null)
        JobDetailTag(
          icon: Icons.euro,
          text: _formatSalary(salaryMin, salaryMax),
          isSpecial: true,
        ),
    ];

    return JobAnnouncementCard(
      companyLogo: cardCompanyLogo,
      companyName: cardCompanyName,
      jobTitle: title,
      description: description,
      tags: tags,
      advantages: advantages,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: null,
    );
  }

  String _formatSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Salaire non spécifié';
  }

  Widget _buildTrainingCard(Map<String, dynamic> tr) {
    final title = (tr['title'] ?? '').toString();
    final description = _stripHtml((tr['description'] ?? '').toString());
    final createdAt = tr['created_at']?.toString();

    final price = tr['price'];
    final durationHours = tr['duration_in_h'];
    final durationUnit = tr['duration_unit']?.toString();
    final status = tr['status']?.toString() ?? '';
    final category = tr['training_category']?.toString() ?? '';
    final subCategory = tr['training_sub_category']?.toString() ?? '';
    final trainingType = tr['training_type']?.toString() ?? '';

    final user = tr['user'] is Map<String, dynamic>
        ? tr['user'] as Map<String, dynamic>
        : null;
    String cardCompanyName = 'Entreprise';
    String cardCompanyLogo = 'assets/images/profil/Rectangle 238.png';

    if (user != null) {
      if (user['pro_profile'] is Map) {
        final p = user['pro_profile'] as Map;
        final n = p['company_name']?.toString() ?? '';
        if (n.isNotEmpty) cardCompanyName = n;
        final logo =
            p['avatar_url']?.toString() ?? p['logo_url']?.toString() ?? '';
        if (logo.isNotEmpty) cardCompanyLogo = logo;
      }
    }

    final tags = <FormationTag>[
      if (category.isNotEmpty)
        FormationTag(icon: Icons.category_outlined, text: category),
      if (subCategory.isNotEmpty)
        FormationTag(icon: Icons.subdirectory_arrow_right, text: subCategory),
      if (trainingType.isNotEmpty)
        FormationTag(icon: Icons.school_outlined, text: trainingType),
      if (price != null)
        FormationTag(
          icon: Icons.euro,
          text: '${price.toString()} €',
          isSpecial: true,
        ),
      if (durationHours != null)
        FormationTag(
          icon: Icons.timer_outlined,
          text:
              '$durationHours h${durationUnit != null ? ' / $durationUnit' : ''}',
        ),
      if (status.isNotEmpty)
        FormationTag(icon: Icons.flag_outlined, text: _statusLabel(status)),
    ];
    return FormationCard(
      companyLogo: cardCompanyLogo,
      companyName: cardCompanyName,
      formationTitle: title,
      description: description.isNotEmpty
          ? description
          : 'Aucune description fournie.',
      tags: tags,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: null,
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

    final user = d['user'] is Map<String, dynamic>
        ? d['user'] as Map<String, dynamic>
        : null;

    String username = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] is Map) {
        final p = user['particulier_profile'] as Map;
        username =
            p['pseudo']?.toString() ??
            user['email']?.toString().split('@').first ??
            'Utilisateur';
      } else if (user['pro_profile'] is Map) {
        final p = user['pro_profile'] as Map;
        username =
            p['company_name']?.toString() ??
            user['email']?.toString().split('@').first ??
            'Utilisateur';
      }
    }

    String profileImage = 'assets/images/profil/Rectangle 238.png';
    if (user != null) {
      if (user['particulier_profile'] is Map) {
        final p = user['particulier_profile'] as Map;
        final avatarUrl = p['avatar_url']?.toString() ?? '';
        if (avatarUrl.isNotEmpty) profileImage = avatarUrl;
      } else if (user['pro_profile'] is Map) {
        final p = user['pro_profile'] as Map;
        final avatarUrl =
            p['avatar_url']?.toString() ?? p['logo_url']?.toString() ?? '';
        if (avatarUrl.isNotEmpty) profileImage = avatarUrl;
      }
    }

    final mediaFiles = d['media_files'] as List? ?? [];
    final imageUrlRaw = mediaFiles.isNotEmpty
        ? (mediaFiles.first is Map ? mediaFiles.first['url'] : null)?.toString()
        : null;
    final imageUrl = (imageUrlRaw != null && imageUrlRaw.isNotEmpty)
        ? imageUrlRaw
        : null;

    final displayLocation = nationwide
        ? 'Toute la France'
        : (location.isNotEmpty ? location : 'Non spécifié');

    return DemandeCard(
      profileImage: profileImage,
      username: username,
      categoryLabel: nature,
      categoryColor: const Color(0xFFEF8A40),
      title: title,
      description: description.length > 200
          ? '${description.substring(0, 200)}...'
          : description,
      location: displayLocation,
      postImage: imageUrl,
      likesCount: 0,
      commentsCount: 0,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onTapCTA: null,
    );
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
      _loadReviews();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    
    final targetUserId = widget.userId ?? _profileResponse?['user']?['id']?.toString();
    if (targetUserId == null) {
      setState(() => _isLoadingReviews = false);
      return;
    }

    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final response = await ApiClient().authenticatedGet('/reviews/user/$targetUserId');
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(response['reviews'] ?? []);
          _averageRating = (response['average_rating'] ?? 0.0).toDouble();
          _totalReviews = response['total_reviews'] ?? 0;
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _reviewsError = response['message'] ?? 'Erreur de chargement';
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reviewsError = 'Erreur de connexion: $e';
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_reviewRating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez noter et commenter avant d\'envoyer votre avis.',
          ),
        ),
      );
      return;
    }

    // Check if viewing own profile
    if (_isViewingOwnProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas donner un avis à votre propre profil.'),
        ),
      );
      return;
    }

    final targetUserId = widget.userId;
    if (targetUserId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedPost(
        '/reviews/user/$targetUserId',
        body: {
          'rating': _reviewRating,
          'comment': _reviewController.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response['success'] == true) {
        // Clear form
        setState(() {
          _reviewRating = 0;
          _reviewController.clear();
        });

        // Reload reviews
        await _loadReviews();

        // Update UserSession with new My's balance from response
        // The backend should return the updated mys count, or we can refresh from profile
        if (response['new_mys_balance'] != null) {
          UserSession().updateMys(response['new_mys_balance']);
        }

        // Show reward modal
        if (mounted && response['mys_earned'] != null) {
          await MysRewardModal.show(
            context,
            amount: response['mys_earned'],
            actionType: 'review',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Erreur lors de l\'envoi de l\'avis'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            content: Text(_isFollowing ? 'Vous suivez maintenant cet utilisateur' : 'Vous ne suivez plus cet utilisateur'),
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _conversationService.getOrCreateConversation(targetId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final profile = _profileResponse?['profile'];
      final displayName = (profile is Map) 
          ? (profile['company_name']?.toString() ?? 'Entreprise')
          : 'Entreprise';
      
      String? avatarUrl;
      if (profile is Map) {
        avatarUrl = profile['avatar_url']?.toString() ?? profile['logo_url']?.toString();
      }
      final resolvedAvatar = avatarUrl != null && avatarUrl.isNotEmpty
          ? (avatarUrl.startsWith('http') ? avatarUrl : ApiConfig.resolveMediaUrl(avatarUrl))
          : null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar: resolvedAvatar ?? 'assets/images/dashboard_particulier/Ellipse 10.png',
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

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final user = rawPost['user'] as Map<String, dynamic>?;
    final userType = user?['account_type']?.toString() ?? 'Professionnel';
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

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return const <Map<String, dynamic>>[];
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
        ApiClient().authenticatedGet('/job-offers'),
        ApiClient().authenticatedGet('/trainings'),
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
      final jobOffers = filterByUser(_extractList(results[1]));
      final trainings = filterByUser(_extractList(results[2]));
      final events = filterByUser(_extractList(results[3]));
      final demandes = filterByUser(_extractList(results[4]));

      if (!mounted) return;
      setState(() {
        _bonPlans = bonPlans;
        _jobOffers = jobOffers;
        _trainings = trainings;
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

  String? _resolveAvatarUrl() {
    final profile = _profileResponse?['profile'];
    final raw = profile is Map ? profile['avatar_url']?.toString() : null;
    return raw;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profileResponse?['profile'];
    final companyName = profile is Map
        ? profile['company_name']?.toString()
        : null;
    final firstName = profile is Map ? profile['first_name']?.toString() : null;
    final lastName = profile is Map ? profile['last_name']?.toString() : null;
    final nameParts = <String>[];
    if (firstName != null && firstName.trim().isNotEmpty) {
      nameParts.add(firstName.trim());
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      nameParts.add(lastName.trim());
    }
    final displayName = companyName ?? nameParts.join(' ');
    final siret = profile is Map ? profile['siret']?.toString() : null;
    final secteur = profile is Map
        ? profile['secteur_activite']?.toString()
        : null;
    final avatarUrl = _resolveAvatarUrl();

    // Get social links
    final socialLinks = profile is Map
        ? (profile['social_links'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    final facebookUrl = socialLinks['facebook']?.toString();
    final instagramUrl = socialLinks['instagram']?.toString();
    final youtubeUrl = socialLinks['youtube']?.toString();
    // final linkedinUrl = socialLinks['linkedin']?.toString();
    // final snapchatUrl = socialLinks['snapchat']?.toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
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
                            color: const Color(0xFF2E9B5B),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              displayName.isNotEmpty ? displayName : '—',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              siret != null && siret.trim().isNotEmpty
                                  ? 'SIRET: $siret'
                                  : 'SIRET: —',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/profil_pro/profil-etiq.png',
                                  width: 17,
                                  height: 17,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  (secteur != null && secteur.trim().isNotEmpty)
                                      ? secteur
                                      : '—',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD700),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_averageRating.toStringAsFixed(1)} ($_totalReviews avis)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E9B5B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF8A40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF2E9B5B),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: avatarUrl != null
                                  ? (avatarUrl.startsWith('http')
                                        ? NetworkImage(avatarUrl)
                                              as ImageProvider
                                        : NetworkImage(
                                                ApiConfig.resolveMediaUrl(
                                                      avatarUrl,
                                                    ) ??
                                                    '',
                                              )
                                              as ImageProvider)
                                  : AssetImage(
                                          'assets/images/dashboard_particulier/Ellipse 10.png',
                                        )
                                        as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 75,
                        left: 30,
                        child: Column(
                          children: [
                            // Facebook
                            if (facebookUrl != null && facebookUrl.isNotEmpty)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1877F2,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(facebookUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch Facebook: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.facebook,
                                    color: Color(0xFF1877F2),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            if (facebookUrl != null && facebookUrl.isNotEmpty)
                              const SizedBox(height: 12),
                            // Instagram
                            if (instagramUrl != null && instagramUrl.isNotEmpty)
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE1306C,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(instagramUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch Instagram: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.instagram,
                                    color: Color(0xFFE1306C),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            if (instagramUrl != null && instagramUrl.isNotEmpty)
                              const SizedBox(height: 12),
                            // YouTube
                            if (youtubeUrl != null && youtubeUrl.isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF0000,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final uri = Uri.parse(youtubeUrl);
                                    try {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        'Could not launch YouTube: $e',
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    FontAwesomeIcons.youtube,
                                    color: Color(0xFFFF0000),
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Message and Suivre buttons - only show when viewing other users' profiles
                  if (!_isViewingOwnProfile)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startConversation,
                              icon: const Icon(Icons.message_outlined, size: 18),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3AAE5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingFollow ? null : _toggleFollow,
                              icon: _isLoadingFollow
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF3AAE5E),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isFollowing ? Icons.check : Icons.person_add_outlined,
                                      size: 18,
                                    ),
                              label: Text(_isFollowing ? 'Suivi' : 'Suivre'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3AAE5E),
                                side: const BorderSide(color: Color(0xFF3AAE5E)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            'Annonce(${_totalCount})',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Tab(
                          height: 32,
                          child: Text('Post', textAlign: TextAlign.center),
                        ),
                        Tab(
                          height: 32,
                          child: Text(
                            'Avis ($_totalReviews)',
                            textAlign: TextAlign.center,
                          ),
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
                        _buildAvisTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPresentationTab() {
    final profile = _profileResponse?['profile'];
    final presentation = profile is Map
        ? profile['presentation']?.toString()
        : null;
    final bannerUrl = profile is Map ? profile['banner_url']?.toString() : null;
    final gallery = profile is Map
        ? (profile['gallery'] as List<dynamic>? ?? [])
        : <dynamic>[];

    // Get social links
    final socialLinks = profile is Map
        ? (profile['social_links'] as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    final facebookUrl = socialLinks['facebook']?.toString();
    final instagramUrl = socialLinks['instagram']?.toString();
    final youtubeUrl = socialLinks['youtube']?.toString();
    final linkedinUrl = socialLinks['linkedin']?.toString();
    final tiktokUrl = socialLinks['tiktok']?.toString();
    final snapchatUrl = socialLinks['snapchat']?.toString();
    final xUrl = socialLinks['x']?.toString();

    // Filter images and videos
    final images = gallery.where((item) {
      final url = item.toString().toLowerCase();
      return !url.endsWith('.mp4') &&
          !url.endsWith('.mov') &&
          !url.endsWith('.avi') &&
          !url.endsWith('.webm') &&
          !url.endsWith('.mkv');
    }).toList();

    final videos = gallery.where((item) {
      final url = item.toString().toLowerCase();
      return url.endsWith('.mp4') ||
          url.endsWith('.mov') ||
          url.endsWith('.avi') ||
          url.endsWith('.webm') ||
          url.endsWith('.mkv');
    }).toList();

    String buildImageUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      if (url.startsWith('http') || url.startsWith('https')) return url;
      return '$serverBase/storage/$url';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merged Banner + Presentation + Social Links Card
          Container(
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
                // Banner Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: bannerUrl != null && bannerUrl.isNotEmpty
                        ? Image.network(
                            buildImageUrl(bannerUrl),
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink();
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                
                // Presentation Section
                if (presentation?.trim().isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: Text(
                      'Présentation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                    child: Text(
                      presentation!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                
                // Social Links Section
                if (facebookUrl != null || instagramUrl != null || 
                    youtubeUrl != null || linkedinUrl != null || 
                    tiktokUrl != null || snapchatUrl != null || xUrl != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                    child: Divider(color: Colors.grey[200]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Text(
                      'Réseaux sociaux',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (facebookUrl != null && facebookUrl.isNotEmpty)
                          _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2), facebookUrl),
                        if (instagramUrl != null && instagramUrl.isNotEmpty)
                          _buildSocialIcon(Icons.camera_alt, const Color(0xFFE1306C), instagramUrl),
                        if (youtubeUrl != null && youtubeUrl.isNotEmpty)
                          _buildSocialIcon(Icons.play_circle_filled, const Color(0xFFFF0000), youtubeUrl),
                        if (linkedinUrl != null && linkedinUrl.isNotEmpty)
                          _buildSocialIcon(Icons.business, const Color(0xFF0A66C2), linkedinUrl),
                        if (tiktokUrl != null && tiktokUrl.isNotEmpty)
                          _buildSocialIcon(Icons.music_note, Colors.black, tiktokUrl),
                        if (snapchatUrl != null && snapchatUrl.isNotEmpty)
                          _buildSocialIcon(Icons.screenshot, const Color(0xFFFFFC00), snapchatUrl),
                        if (xUrl != null && xUrl.isNotEmpty)
                          _buildSocialIcon(Icons.tag, Colors.black, xUrl),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Media Gallery Card
          if (gallery.isNotEmpty)
            Container(
              width: double.infinity,
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
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
                    child: Text(
                      'Médias photos et vidéos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMediaTab = 0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                color: _selectedMediaTab == 0
                                    ? const Color(0xFFEF8A40)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                color: _selectedMediaTab == 0
                                    ? const Color(0xFFEF8A40)
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMediaTab = 1),
                          child: Column(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                color: _selectedMediaTab == 1
                                    ? const Color(0xFFEF8A40)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 3,
                                color: _selectedMediaTab == 1
                                    ? const Color(0xFFEF8A40)
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    child: _selectedMediaTab == 0
                        ? _buildPhotosGrid(images, buildImageUrl)
                        : _buildVideosGrid(videos, buildImageUrl),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () async {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('Could not launch $url: $e');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPhotosGrid(
    List<dynamic> images,
    String Function(String?) buildUrl,
  ) {
    if (images.isEmpty) {
      return Center(
        child: Text('Aucune photo', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            buildUrl(images[index].toString()),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 30),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVideosGrid(
    List<dynamic> videos,
    String Function(String?) buildUrl,
  ) {
    if (videos.isEmpty) {
      return Center(
        child: Text('Aucune vidéo', style: TextStyle(color: Colors.grey[600])),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
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
                'Offres d\'emploi',
                _selectedAnnonceFilter == "Offres d'emploi",
              ),
              _buildFilterChip(
                'Formations',
                _selectedAnnonceFilter == 'Formations',
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
                if (_jobOffers.isNotEmpty) _buildJobOffersList(),
                if (_trainings.isNotEmpty) _buildTrainingsList(),
                if (_events.isNotEmpty) _buildEventsList(),
                if (_demandes.isNotEmpty) _buildDemandesList(),
                if (_bonPlans.isEmpty &&
                    _jobOffers.isEmpty &&
                    _trainings.isEmpty &&
                    _events.isEmpty &&
                    _demandes.isEmpty)
                  const Text(
                    'Aucune annonce',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
              ],
            )
          else if (_selectedAnnonceFilter == 'Bons plans')
            _buildBonPlansList()
          else if (_selectedAnnonceFilter == "Offres d'emploi")
            _buildJobOffersList()
          else if (_selectedAnnonceFilter == 'Formations')
            _buildTrainingsList()
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
                "Vous n'avez pas encore publié de post.",
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

  Widget _buildAvisTab() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviews list
            if (_isLoadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reviewsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      _reviewsError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadReviews,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            else if (_reviews.isNotEmpty)
              ..._reviews
                  .map(
                    (review) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildReviewCard(
                        avatarPath: review['author_avatar'] ?? 'assets/images/dashboard_particulier/Ellipse 10.png',
                        name: review['author_name'] ?? 'Utilisateur',
                        timeAgo: review['time_ago'] ?? '',
                        reviewText: review['comment'] ?? '',
                        rating: review['rating'] ?? 0,
                      ),
                    ),
                  )
                  .toList()
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'Aucun avis pour le moment.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Review form - only show when viewing other users' profiles
            if (!_isViewingOwnProfile)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donner votre avis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _reviewRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              index < _reviewRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 28,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Votre commentaire...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFFF9800)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Envoyer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manjari',
                          ),
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
  }

  Widget _buildReviewCard({
    required String avatarPath,
    required String name,
    required String timeAgo,
    required String reviewText,
    required int rating,
  }) {
    // Resolve avatar URL
    ImageProvider avatarImage;
    if (avatarPath.startsWith('http')) {
      avatarImage = NetworkImage(avatarPath);
    } else if (avatarPath.startsWith('assets/')) {
      avatarImage = AssetImage(avatarPath);
    } else {
      final resolvedUrl = ApiConfig.resolveMediaUrl(avatarPath);
      avatarImage = resolvedUrl != null ? NetworkImage(resolvedUrl) : AssetImage('assets/images/dashboard_particulier/Ellipse 10.png');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: avatarImage),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                        fontFamily: 'Manjari',
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (index) =>
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reviewText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4F4F4F),
              height: 1.4,
              fontFamily: 'Manjari',
            ),
          ),
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

  Widget _buildAnnonceCard(
    String userName,
    String userType,
    String description,
    String? imagePath,
    String price,
    String? oldPrice,
    String? discount,
    String? category,
    String? availability,
    String time,
    int? likes,
    int? comments,
  ) {
    return Container(
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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: const AssetImage(
                  'assets/images/dashboard_particulier/Ellipse 10.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: userType == 'Pro'
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: userType == 'Pro' ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        userType,
                        style: TextStyle(
                          color: userType == 'Pro'
                              ? Colors.green.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Icon(Icons.close, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              children: [
                TextSpan(text: description),
                const TextSpan(
                  text: '...plus',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          if (imagePath != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF8A40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (category != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          if (availability != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'En ligne disponible chez '),
                        TextSpan(
                          text: 'Amazon',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF8A40),
                ),
              ),
              if (oldPrice != null) ...[
                const SizedBox(width: 10),
                Text(
                  oldPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF8A40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Image.asset(
                  'assets/images/profil_pro/paper.png',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Voir le bon plan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (likes != null) ...[
                Icon(
                  Icons.thumb_up_outlined,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '$likes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
              ],
              if (comments != null) ...[
                Image.asset(
                  'assets/images/profil_pro/ann-card-comm.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$comments',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
              ],
              Image.asset(
                'assets/images/profil_pro/ann-card-share.png',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(String time, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          RichText(
            text: TextSpan(
              text: 'Publier ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              children: [
                TextSpan(
                  text: time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageUrl,
                  width: 90,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore ...voir plus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 4),
              Text('125', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-comm.png',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 4),
              Text('10', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-share.png',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 4),
              Text('2', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewConfirmationDialog extends StatelessWidget {
  const _ReviewConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                InkWell(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF0E0),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFFF8600),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _AvisSuccessBadge(),
            const SizedBox(height: 24),
            const Text(
              'Cet avis sera définitif après publication et ne pourra être modifié ou supprimé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                      foregroundColor: const Color(0xFF6F6F6F),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisSuccessBadge extends StatelessWidget {
  const _AvisSuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9EF), Color(0xFFFFE0B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(top: 12, right: 18, child: _buildBubble(14, 0.4)),
          Positioned(top: 20, left: 24, child: _buildBubble(10, 0.35)),
          Positioned(bottom: 20, right: 30, child: _buildBubble(12, 0.3)),
          Positioned(bottom: 10, left: 30, child: _buildBubble(9, 0.45)),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC477), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/profil/avis/streamline-ultimate-color_smiley-happy.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.4),
          width: 1,
        ),
      ),
    );
  }
}
