import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/publish_options_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/utils/user_session.dart';

class ProAnnoncesScreen extends StatefulWidget {
  const ProAnnoncesScreen({super.key});

  @override
  State<ProAnnoncesScreen> createState() => _ProAnnoncesScreenState();
}

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction; // 'like' or null

  _ReactionData({this.likesCount = 0, this.commentsCount = 0, this.userReaction});
}

class _ProAnnoncesScreenState extends State<ProAnnoncesScreen> {
  String selectedCategory = 'Bons plans';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _currentUserId;

  List<Map<String, dynamic>> _bonPlans = [];
  bool _isLoadingBonPlans = true;
  String? _bonPlansError;

  List<Map<String, dynamic>> _jobOffers = [];
  bool _isLoadingJobOffers = true;
  String? _jobOffersError;

  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;
  String? _eventsError;

  Future<String?> _ensureCurrentUserId() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final id = response['user']?['id']?.toString();
      if (id != null && id.isNotEmpty) {
        _currentUserId = id;
      }
      return _currentUserId;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingDemandes = true;
  String? _demandesError;

  List<Map<String, dynamic>> _trainings = [];
  bool _isLoadingTrainings = true;
  String? _trainingsError;

  @override
  void initState() {
    super.initState();
    _ensureCurrentUserId();
    _loadBonPlans();
    _loadJobOffers();
    _loadEvents();
    _loadDemandes();
    _loadTrainings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBonPlans() async {
    setState(() {
      _isLoadingBonPlans = true;
      _bonPlansError = null;
    });
    try {
      debugPrint('Pro: Fetching bon plans from: /bonplans');
      final response = await ApiClient().authenticatedGet('/bonplans');
      debugPrint('Pro: Bon plans response keys: ${response.keys.toList()}');
      final data = response['data'];
      debugPrint('Pro: Bon plans data type: ${data.runtimeType}');
      if (data is List) {
        _bonPlans = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        _bonPlans = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _bonPlans = [];
      }
      debugPrint('Pro: Loaded ${_bonPlans.length} bon plans');
    } on ApiException catch (e) {
      debugPrint('Pro: Error loading bon plans: ${e.message}');
      _bonPlansError = e.message;
    } catch (e) {
      debugPrint('Pro: Error loading bon plans: $e');
      _bonPlansError = 'Erreur de chargement';
    } finally {
      if (mounted) setState(() => _isLoadingBonPlans = false);
    }
  }

  Future<void> _loadJobOffers() async {
    setState(() {
      _isLoadingJobOffers = true;
      _jobOffersError = null;
    });
    try {
      debugPrint('Pro: Fetching job offers from: /job-offers');
      final response = await ApiClient().authenticatedGet('/job-offers');
      debugPrint('Pro: Job offers response keys: ${response.keys.toList()}');
      final data = response['data'];
      debugPrint('Pro: Job offers data type: ${data.runtimeType}');
      if (data is List) {
        _jobOffers = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        _jobOffers = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _jobOffers = [];
      }
      debugPrint('Pro: Loaded ${_jobOffers.length} job offers');
    } on ApiException catch (e) {
      debugPrint('Pro: Error loading job offers: ${e.message}');
      _jobOffersError = e.message;
    } catch (e) {
      debugPrint('Pro: Error loading job offers: $e');
      _jobOffersError = 'Erreur de chargement';
    } finally {
      if (mounted) setState(() => _isLoadingJobOffers = false);
    }
  }

  Future<void> _loadDemandes() async {
    setState(() {
      _isLoadingDemandes = true;
      _demandesError = null;
    });
    try {
      debugPrint('Pro: Fetching demandes from: /demandes');
      final response = await ApiClient().authenticatedGet('/demandes');
      final data = response['data'];
      if (data is List) {
        _demandes = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        _demandes = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _demandes = [];
      }
      debugPrint('Pro: Loaded ${_demandes.length} demandes');
    } on ApiException catch (e) {
      debugPrint('Pro: Error loading demandes: ${e.message}');
      _demandesError = e.message;
    } catch (e) {
      debugPrint('Pro: Error loading demandes: $e');
      _demandesError = 'Erreur de chargement';
    } finally {
      if (mounted) setState(() => _isLoadingDemandes = false);
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });
    try {
      debugPrint('Pro: Fetching events from: /events');
      final response = await ApiClient().authenticatedGet('/events');
      final data = response['data'];
      if (data is List) {
        _events = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        _events = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _events = [];
      }
      debugPrint('Pro: Loaded ${_events.length} events');
    } on ApiException catch (e) {
      debugPrint('Pro: Error loading events: ${e.message}');
      _eventsError = e.message;
    } catch (e) {
      debugPrint('Pro: Error loading events: $e');
      _eventsError = 'Erreur de chargement';
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoadingTrainings = true;
      _trainingsError = null;
    });
    try {
      debugPrint('Pro: Fetching trainings from: /trainings');
      final response = await ApiClient().authenticatedGet('/trainings');
      final data = response['data'];
      if (data is List) {
        _trainings = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('data')) {
        _trainings = List<Map<String, dynamic>>.from(data['data']);
      } else {
        _trainings = [];
      }
      debugPrint('Pro: Loaded ${_trainings.length} trainings');
    } on ApiException catch (e) {
      debugPrint('Pro: Error loading trainings: ${e.message}');
      _trainingsError = e.message;
    } catch (e) {
      debugPrint('Pro: Error loading trainings: $e');
      _trainingsError = 'Erreur de chargement';
    } finally {
      if (mounted) setState(() => _isLoadingTrainings = false);
    }
  }

  List<Map<String, dynamic>> get _filteredBonPlans {
    if (_searchQuery.isEmpty) return _bonPlans;
    final q = _searchQuery.toLowerCase();
    return _bonPlans.where((bp) {
      final title = (bp['title'] ?? '').toString().toLowerCase();
      final desc = (bp['description'] ?? '').toString().toLowerCase();
      final cat = (bp['category'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q) || cat.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredJobOffers {
    if (_searchQuery.isEmpty) return _jobOffers;
    final q = _searchQuery.toLowerCase();
    return _jobOffers.where((jo) {
      final title = (jo['title'] ?? '').toString().toLowerCase();
      final desc = (jo['description'] ?? '').toString().toLowerCase();
      final company = (jo['company']?['name'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q) || company.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredDemandes {
    if (_searchQuery.isEmpty) return _demandes;
    final q = _searchQuery.toLowerCase();
    return _demandes.where((d) {
      final title = (d['title'] ?? '').toString().toLowerCase();
      final desc = (d['description'] ?? '').toString().toLowerCase();
      final nature = (d['nature'] ?? '').toString().toLowerCase();
      final type = (d['type'] ?? '').toString().toLowerCase();
      return title.contains(q) ||
          desc.contains(q) ||
          nature.contains(q) ||
          type.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    final q = _searchQuery.toLowerCase();
    return _events.where((ev) {
      final title = (ev['title'] ?? '').toString().toLowerCase();
      final desc = (ev['description'] ?? '').toString().toLowerCase();
      final location = (ev['coverage_area'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q) || location.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredTrainings {
    if (_searchQuery.isEmpty) return _trainings;
    final q = _searchQuery.toLowerCase();
    return _trainings.where((tr) {
      final title = (tr['title'] ?? '').toString().toLowerCase();
      final desc = (tr['description'] ?? '').toString().toLowerCase();
      final cat = (tr['training_category'] ?? '').toString().toLowerCase();
      return title.contains(q) || desc.contains(q) || cat.contains(q);
    }).toList();
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int get _totalCount =>
      _bonPlans.length +
      _jobOffers.length +
      _events.length +
      _demandes.length +
      _trainings.length;

  int get _activeCount {
    final activeBp = _bonPlans
        .where(
          (bp) => bp['status'] == 'published' || bp['status'] == 'PUBLISHED',
        )
        .length;
    final activeJo = _jobOffers
        .where(
          (jo) => jo['status'] == 'PUBLISHED' || jo['status'] == 'published',
        )
        .length;
    final activeEvents = _events
        .where(
          (ev) => (ev['status'] ?? '').toString().toUpperCase() == 'PUBLISHED',
        )
        .length;
    final activeDemandes = _demandes
        .where(
          (d) => (d['status'] ?? '').toString().toUpperCase() == 'PUBLISHED',
        )
        .length;
    return activeBp + activeJo + activeEvents + activeDemandes;
  }

  int get _expiredCount {
    final expBp = _bonPlans
        .where(
          (bp) =>
              bp['status'] == 'rejected' ||
              bp['status'] == 'REJECTED' ||
              bp['status'] == 'ARCHIVED' ||
              bp['status'] == 'archived',
        )
        .length;
    final expJo = _jobOffers
        .where(
          (jo) =>
              jo['status'] == 'REJECTED' ||
              jo['status'] == 'rejected' ||
              jo['status'] == 'ARCHIVED' ||
              jo['status'] == 'archived',
        )
        .length;
    final expEvents = _events.where((ev) {
      final status = (ev['status'] ?? '').toString().toUpperCase();
      return status == 'REJECTED' || status == 'ARCHIVED';
    }).length;
    final expDemandes = _demandes.where((d) {
      final status = (d['status'] ?? '').toString().toUpperCase();
      return status == 'REJECTED' || status == 'ARCHIVED';
    }).length;
    return expBp + expJo + expEvents + expDemandes;
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
      String profileImage = user?['avatar_url']?.toString() ?? '';
      if (profileImage.isEmpty) {
        profileImage = _buildImageUrl(user?['avatar']?.toString());
      }
      if (profileImage.isEmpty) {
        profileImage = 'assets/images/default_profile.png';
      }
      // Use display_name which contains company_name for pro or pseudo for particulier
      final username =
          user?['display_name']?.toString() ??
          user?['name']?.toString() ??
          'Mon bon plan';
      final userType = user?['account_type']?.toString() ?? 'Professionnel';
      final title = data['title']?.toString() ?? 'Bon plan';
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
            time: _timeAgo(data['created_at']?.toString()),
            availability: availableAt,
            validityType: validityType,
            validFrom: validFrom,
            validUntil: validUntil,
            deliveryInfo: deliveryInfo,
            location: location,
            link: link,
            isOwner: true,
            bonPlanId: bonPlanId,
            bonPlanData: data,
            acceptMessages: acceptMessages,
            authorData: user,
            promo_code: bp['promo_code'],
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadBonPlans();
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

  List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return ['assets/images/details_bon_plans/Rectangle 35.png'];
    }
    final images = <String>[];
    for (final m in mediaFiles) {
      if (m is Map && m['url'] != null) {
        final url = _buildImageUrl(m['url']?.toString());
        if (url.isNotEmpty) {
          images.add(url);
        }
      }
    }
    return images.isNotEmpty
        ? images
        : ['assets/images/details_bon_plans/Rectangle 35.png'];
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
      if (diff.inDays < 30) return 'il y a ${diff.inDays ~/ 7} sem.';
      return 'il y a ${diff.inDays ~/ 30} mois';
    } catch (_) {
      return '';
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'PUBLISHED':
        return 'Publié';
      case 'PENDING_REVIEW':
        return 'En attente';
      case 'DRAFT':
        return 'Brouillon';
      case 'REJECTED':
        return 'Rejeté';
      case 'ARCHIVED':
        return 'Archivé';
      default:
        return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PUBLISHED':
        return const Color(0xFF4CAF50);
      case 'PENDING_REVIEW':
        return const Color(0xFFFF9800);
      case 'DRAFT':
        return Colors.grey;
      case 'REJECTED':
        return const Color(0xFFF44336);
      case 'ARCHIVED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _buildImageUrl(String? url) {
    if (url == null) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    String fullUrl = url;
    if (url.startsWith('http')) {
      // fullUrl = url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
      fullUrl = url;
    } else {
      fullUrl = '$serverBase$url';
    }
    debugPrint('Image URL: $fullUrl');
    return fullUrl;
  }

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME':
        return 'Temps plein';
      case 'PART_TIME':
        return 'Temps partiel';
      default:
        return val;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Mes annonces',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadBonPlans(),
            _loadJobOffers(),
            _loadEvents(),
            _loadDemandes(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Faire une recherche',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E9B5B),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dynamic stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '$_totalCount',
                            'Total',
                            'assets/images/profil_pro/annonce-2.png',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '$_activeCount',
                            'Activés',
                            'assets/images/profil_pro/annonce-3.png',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '$_expiredCount',
                            'Expirées',
                            'assets/images/profil_pro/annonce-1.png',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Divider(color: Color(0xFFE0E0E0)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtre par catégorie',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PublishOptionsScreen(),
                              ),
                            ).then((_) {
                              _loadBonPlans();
                              _loadJobOffers();
                              _loadEvents();
                            });
                          },
                          icon: Image.asset(
                            'assets/images/profil_pro/post.png',
                            width: 20,
                            height: 20,
                          ),
                          label: const Text(
                            'Poster une annonce',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8A40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Category filter icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          CategoriesIcon(
                            title: 'Bons plans',
                            iconColor: const Color.fromARGB(255, 252, 116, 37),
                            bgColor: const Color(0xFFFFE0B2).withOpacity(0.2),
                            icon: Icons.card_giftcard_outlined,
                            onTap: () =>
                                setState(() => selectedCategory = 'Bons plans'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Offre d'emploi",
                            iconColor: Colors.lightBlueAccent,
                            bgColor: const Color(0xFFB3E5FC).withOpacity(0.2),
                            iconAsset: 'assets/images/offres.png',
                            onTap: () => setState(
                              () => selectedCategory = "Offre d'emploi",
                            ),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Formations',
                            iconColor: Colors.purple,
                            bgColor: const Color(0xFFE1BEE7).withOpacity(0.1),
                            iconAsset: 'assets/images/Formation.png',
                            onTap: () =>
                                setState(() => selectedCategory = 'Formations'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Evenements',
                            iconColor: Colors.green,
                            bgColor: const Color(0xFFE6F7EF).withOpacity(0.5),
                            icon: Icons.event_outlined,
                            onTap: () =>
                                setState(() => selectedCategory = 'Événement'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Demandes',
                            iconColor: const Color.fromARGB(255, 252, 231, 49),
                            bgColor: const Color.fromARGB(
                              255,
                              255,
                              250,
                              178,
                            ).withOpacity(0.2),
                            icon: Icons.chat_outlined,
                            onTap: () =>
                                setState(() => selectedCategory = 'Demandes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dynamic content
                  _buildContent(),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedCategory == 'Bons plans') return _buildBonPlansList();
    if (selectedCategory == "Offre d'emploi") return _buildJobOffersList();
    if (selectedCategory == 'Formations') return _buildTrainingsList();
    if (selectedCategory == 'Événement') return _buildEventsList();
    if (selectedCategory == 'Demandes') return _buildDemandesList();
    return _buildEmptyState('Bientôt disponible pour cette catégorie');
  }

  Widget _buildDemandesList() {
    if (_isLoadingDemandes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_demandesError != null) {
      return _buildErrorState(_demandesError!, onRetry: _loadDemandes);
    }
    final items = _filteredDemandes;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune demande trouvée pour "$_searchQuery"'
            : 'Aucune demande publiée',
      );
    }
    return Column(children: items.map(_buildDemandeCard).toList());
  }

  String _getNatureLabel(String nature) {
    const natureLabels = {
      'emploi': 'Recherche d\'emploi',
      'service': 'Recherche de service',
      'logement': 'Recherche de logement',
      'produit': 'Recherche de produit',
      'formation': 'Recherche de formation',
      'collaboration': 'Collaboration',
      'autre': 'Autre demande',
    };
    return natureLabels[nature.toLowerCase()] ?? nature;
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

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
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
    final nationwide =
        nationwideRaw == true ||
        nationwideRaw == 1 ||
        nationwideRaw?.toString() == '1' ||
        nationwideRaw?.toString().toLowerCase() == 'true';
    final locationRaw =
        demande['location']?.toString() ?? demande['city']?.toString() ?? '';
    final location = nationwide
        ? 'Toute la France'
        : (locationRaw.isNotEmpty ? locationRaw : 'Non spécifié');

    // Media
    final postImage = _extractMediaUrl(demande);

    final demandeId = demande['id']?.toString() ?? '';

    // Check if already favorited by current user
    bool isFavorited = demande['is_favorited'] == true;

    print("isFavorited: ${demande['is_favorited']}");

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoadingFavorite = false;
        bool localIsFavorited = isFavorited;

        Future<void> toggleFavorite() async {
          if (isLoadingFavorite || demandeId.isEmpty) return;

          setState(() => isLoadingFavorite = true);

          try {
            if (localIsFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/demandes/$demandeId/favorite',
              );
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/demandes/$demandeId/favorite',
              );
            }

            setState(() {
              localIsFavorited = !localIsFavorited;
              isLoadingFavorite = false;
              isFavorited = !isFavorited;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            setState(() => isLoadingFavorite = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

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
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
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
          isFavorited: localIsFavorited,
          isLoadingFavorite: isLoadingFavorite,
          onFavoriteToggle: toggleFavorite,
          reactionBar: demandeId.isNotEmpty
              ? () {
                  _seedReactionFromResource('demandes', demandeId, demande);
                  return _buildReactionBar(
                    'demandes',
                    demandeId,
                    acceptedMessages: demande['accept_messages'] == true,
                    authorData: demande['user'],
                  );
                }()
              : null,
        );
      },
    );
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> d) async {
    final demandeId = d['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette demande')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/$demandeId',
      );

      print("Response: ${response['data']['user']}");

      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final nature = data['nature']?.toString();
      final type = data['type']?.toString();
      final username = response['data']['user']['pro_profile'] != null
          ? response['data']['user']['pro_profile']['first_name']?.toString()
          : response['data']['user']['particulier_profile']['pseudo']
                ?.toString();
      final avatar = response['data']['user']['pro_profile'] != null
          ? response['data']['user']['pro_profile']['avatar_url']?.toString()
          : response['data']['user']['particulier_profile']['avatar_url']
                ?.toString();
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
          .map((m) => m['url']?.toString() ?? '')
          // .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      final categoryLabel = (type != null && type.isNotEmpty)
          ? type
          : (nature != null && nature.isNotEmpty ? nature : 'Demande');

      final tags = <PostTag>[
        PostTag(
          title: categoryLabel,
          icon: Icons.label_outline,
          color: Colors.grey,
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

      final subTagsCat = nature != null && nature.isNotEmpty
          ? nature
          : 'Demande';

      final subTag = PostTag(
        title: subTagsCat,
        icon: Icons.label_outline,
        color: Colors.orange,
      );

      final currentUserId = _currentUserId;
      final authorId = (data['user'] is Map)
          ? (data['user'] as Map)['id']?.toString()
          : data['user_id']?.toString();

      final isOwner =
          authorId != null && authorId.isNotEmpty && currentUserId == authorId;

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: avatar ?? 'assets/images/profil/Rectangle 195.png',
            username: username ?? 'Ma demande',
            demandeTitle: title,
            description: description,
            tags: tags,
            subtags: subTag,
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
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
            returnToListingOnEdit: true,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadDemandes();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Widget _buildTrainingsList() {
    if (_isLoadingTrainings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_trainingsError != null) {
      return _buildErrorState(_trainingsError!, onRetry: _loadTrainings);
    }
    final items = _filteredTrainings;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune formation trouvée pour "$_searchQuery"'
            : 'Aucune formation publiée',
      );
    }
    return Column(children: items.map(_buildTrainingCard).toList());
  }

  Widget _buildTrainingCard(Map<String, dynamic> tr) {
    final trainingId = tr['id']?.toString() ?? '';
    final title = tr['title']?.toString() ?? 'Formation';
    final description = _stripHtml(tr['description']?.toString() ?? '');
    final provider = tr['provider_name']?.toString() ?? 'Organisme';
    final duration = tr['duration_in_h'];
    final durationUnit = tr['duration_unit']?.toString();
    final price = tr['price'];
    final category = tr['training_category']?.toString() ?? '';
    final subCategory = tr['training_sub_category']?.toString() ?? '';
    final trainingType = tr['training_type']?.toString() ?? '';

    final addressCity = tr['address_city']?.toString() ?? '';

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
    final trainingStyleRaw = tr['training_style'];
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
    final trainingPublicRaw = tr['training_public'];
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

    final certification = _extractArrayValues(tr['certification']);

    // Check if CPF is in training_funding array
    final trainingFunding = tr['training_funding'];
    bool hasCpf = false;
    if (trainingFunding is List) {
      hasCpf = trainingFunding.any(
        (funding) =>
            funding.toString().toUpperCase() == 'CPF' ||
            (funding is Map &&
                funding['type']?.toString().toUpperCase() == 'CPF'),
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
        FormationTag(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Eligible CPF',
        ),
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
          final publicType = tr['public_type']?.toString() ?? '';
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

    final user = tr['user'] as Map<String, dynamic>?;
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
    final ownerName =
        proProfile?['company_name']?.toString() ??
        proProfile?['first_name']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        particulierProfile?['first_name']?.toString() ??
        tr['provider_name']?.toString() ??
        'Organisme';

    // Check if already favorited by current user
    bool isFavorited = tr['is_favorited'] == true;

    bool isLoading = false;

    Future<void> _toggleFavorite() async {
      if (isLoading || trainingId.isEmpty) return;

      setState(() => isLoading = true);

      try {
        if (isFavorited) {
          // Remove from favorites
          await ApiClient().authenticatedDelete(
            '/trainings/$trainingId/favorite',
          );
        } else {
          // Add to favorites
          await ApiClient().authenticatedPost(
            '/trainings/$trainingId/favorite',
          );
        }

        setState(() {
          isFavorited = !isFavorited;
          isLoading = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris',
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
      timeAgo: _buildTimeAgo(tr['created_at']?.toString()),
      isFavorited: isFavorited,
      isLoadingFavorite: isLoading,
      onFavoriteToggle: _toggleFavorite,
      onApply: () => _navigateToTrainingDetail(tr),
      onAvatarTap: () {
        if (user?['id'] != null) {
          final isProUser =
              user?['account_type']?.toString().toLowerCase() == 'pro';
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
          ? () {
              _seedReactionFromResource('trainings', trainingId, tr);
              return _buildReactionBar('trainings', trainingId);
            }()
          : null,
    );
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
      if (result == 'deleted' && mounted) _loadTrainings();
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Widget _buildBonPlansList() {
    if (_isLoadingBonPlans) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_bonPlansError != null) {
      return _buildErrorState(_bonPlansError!, onRetry: _loadBonPlans);
    }
    final items = _filteredBonPlans;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucun bon plan trouvé pour "$_searchQuery"'
            : 'Aucun bon plan publié',
      );
    }
    return Column(children: items.map((bp) => _buildBonPlanCard(bp)).toList());
  }

  Widget _buildJobOffersList() {
    if (_isLoadingJobOffers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_jobOffersError != null) {
      return _buildErrorState(_jobOffersError!, onRetry: _loadJobOffers);
    }
    final items = _filteredJobOffers;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune offre trouvée pour "$_searchQuery"'
            : "Aucune offre d'emploi publiée",
      );
    }
    return Column(children: items.map((jo) => _buildJobOfferCard(jo)).toList());
  }

  Widget _buildEventsList() {
    if (_isLoadingEvents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_eventsError != null) {
      return _buildErrorState(_eventsError!, onRetry: _loadEvents);
    }
    final items = _filteredEvents;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucun événement trouvé pour "$_searchQuery"'
            : 'Aucun événement publié',
      );
    }
    return Column(children: items.map((ev) => _buildEventCard(ev)).toList());
  }

  String get _defaultAvatar =>
      'assets/images/dashboard_particulier/Ellipse 10.png';

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('http')) return url;
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

  String _formatEventStatus(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || startDateStr.isEmpty) return 'À venir';
    try {
      final start = DateTime.parse(startDateStr);
      final now = DateTime.now();
      if (endDateStr != null && endDateStr.isNotEmpty) {
        final end = DateTime.parse(endDateStr);
        if (now.isAfter(end)) return 'Terminé';
      }
      if (now.isAfter(start)) return 'En cours';
      return 'À venir';
    } catch (_) {
      return 'À venir';
    }
  }

  String _formatEventDate(String? dateStr) {
    if (dateStr == null) return 'Date à confirmer';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? '';
    final description = _stripHtml(event['description']?.toString() ?? '');
    final location =
        event['location']?.toString() ?? event['city']?.toString() ?? '';
    final eventDate =
        event['event_date']?.toString() ?? event['start_date']?.toString();
    final endDate =
        event['end_date']?.toString() ?? event['event_end_date']?.toString();
    final createdAt = event['created_at']?.toString();
    final price =
        event['price']?.toString() ?? event['ticket_price']?.toString();
    final isPaid = event['is_paid'] == true || event['is_paid'] == 1;
    final category = event['category']?.toString() ?? '';
    final subCategory = event['sub_category']?.toString() ?? '';
    final tags = (event['tags'] as List? ?? [])
        .map((t) => t?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final eventId = event['id']?.toString() ?? '';

    // Media
    final mediaFiles = event['media'] as List? ?? [];
    final imageUrl = _extractMediaUrl(event);

    // User info
    final user = event['user'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final avatarUrl =
        particulierProfile?['avatar_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        proProfile?['logo_url']?.toString();
    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;
    final username =
        particulierProfile?['pseudo']?.toString() ??
        proProfile?['company_name']?.toString() ??
        user?['email']?.toString() ??
        'Organisateur';
    final accountType = user?['account_type']?.toString() ?? 'particulier';

    // Check if already favorited by current user
    bool isFavorited = event['is_favorited'] == true;

    // Prepare display values
    final allCategories = <String>[
      if (category.isNotEmpty) category,
      if (subCategory.isNotEmpty) subCategory,
      ...tags.take(2),
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoadingFavorite = false;
        bool localIsFavorited = isFavorited;

        Future<void> toggleFavorite() async {
          if (isLoadingFavorite || eventId.isEmpty) return;

          setState(() => isLoadingFavorite = true);

          try {
            if (localIsFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/events/$eventId/favorite',
              );
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/events/$eventId/favorite');
            }

            setState(() {
              localIsFavorited = !localIsFavorited;
              isLoadingFavorite = false;
              isFavorited = !isFavorited;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: const TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            setState(() => isLoadingFavorite = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return EvenementCard(
          profileImage: profileImage,
          username: username,
          userType: accountType == 'pro' ? 'Pro' : 'Particulier',
          eventTitle: title.isNotEmpty ? title : 'Évènement',
          eventImage:
              _buildStorageUrl(imageUrl) ??
              'assets/images/dashboard_particulier/Rectangle 12 (4).png',
          badge: _formatEventStatus(eventDate, endDate),
          categories: allCategories.isNotEmpty ? allCategories : ['Évènement'],
          eventDate: _formatEventDate(eventDate),
          location: location.isNotEmpty ? location : 'Lieu à confirmer',
          timeAgo: _buildTimeAgo(createdAt),
          price: isPaid && price != null && price.isNotEmpty
              ? '${price}€'
              : 'Gratuit',
          likesCount: _asInt(event['likes_count']),
          commentsCount: _asInt(event['comments_count']),
          isFavorite: localIsFavorited,
          onFavoriteToggle: toggleFavorite,
          onTapCTA: () => _navigateToEventDetail(event),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
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
              ? () {
                  _seedReactionFromResource('events', eventId, event);
                  return _buildReactionBar(
                    'events',
                    eventId,
                    acceptedMessages: event['accept_messages'] == true,
                    authorData: user,
                  );
                }()
              : null,
        );
      },
    );
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/events/$eventId');
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

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
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
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

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: 'assets/images/default_profile.png',
            username: isOrganizer
                ? 'Mon événement'
                : (organizerName ?? 'Organisateur'),
            userType: 'Évènement',
            eventTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
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
            isOwner: true,
            eventId: eventId,
            eventData: data,
            returnToListingOnEdit: true,
            authorData: data['user'] as Map<String, dynamic>?,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadEvents();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
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

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/$url';
  }

  Widget _buildBonPlanDescription(Map<String, dynamic> item) {
    final descriptionPlain = item['description']?.toString() ?? '';
    return Text(
      _stripHtml(descriptionPlain),
      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
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
    // Check if already favorited by current user
    bool _isFavorited = bp['is_favorited'] == true;

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || bpId.isEmpty) return;

          setState(() => _isLoading = true);

          try {
            if (_isFavorited) {
              // Remove from favorites
              await ApiClient().authenticatedDelete('/bonplans/$bpId/favorite');
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost('/bonplans/$bpId/favorite');
            }

            setState(() {
              _isFavorited = !_isFavorited;
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris',
                    style: const TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
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
                    _buildBonPlanImageCarousel(imageUrls),

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
                          bp['price'] != null &&
                                  bp['price'].toString().isNotEmpty
                              ? '${bp['price']}€'
                              : 'Gratuit',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E9B5B),
                          ),
                        ),
                        if (bp['original_price'] != null &&
                            bp['original_price'].toString().isNotEmpty) ...[
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
                        // Promo code as tag
                        if (bp['promo_code'] != null &&
                            bp['promo_code'].toString().isNotEmpty) ...[
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
                                    'Code promo: ${bp['promo_code']}',
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
                  if (bpId.isNotEmpty) ...[
                    Builder(builder: (context) {
                      _seedReactionFromResource('bon-plans', bpId, bp);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildReactionBar(
                          'bon-plans',
                          bpId,
                          acceptedMessages: bp['accept_messages'] == true,
                          authorData: bp['user'] as Map<String, dynamic>?,
                        ),
                      );
                    }),
                  ],
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
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
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

  String? _buildJobSalaryDisplay(Map<String, dynamic> job) {
    final min = job['salary_min'];
    final max = job['salary_max'];
    final exact = job['salary_exact'];
    final paymentType = job['salary_payment_type']?.toString(); // brut/net
    final period = job['salary_period']?.toString(); // horaire/mensuel/annuel

    // Build period label
    String periodLabel = '';
    if (period == 'horaire')
      periodLabel = '/h';
    else if (period == 'mensuel')
      periodLabel = '/mois';
    else if (period == 'annuel')
      periodLabel = '/an';

    // Build payment label (brut/net)
    String paymentLabel = paymentType == 'brut'
        ? ' brut'
        : (paymentType == 'net' ? ' net' : '');

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

  Widget _buildJobOfferCard(Map<String, dynamic> job) {
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
    final salary =
        job['salary_label']?.toString() ??
        _buildJobSalaryDisplay(job) ??
        job['salary']?.toString();

    // Check if already favorited by current user
    bool isFavorited = job['is_favorited'] == true;

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

    bool _isLoading = false;

    Future<void> _toggleFavorite() async {
      if (_isLoading || jobId.isEmpty) return;

      setState(() => _isLoading = true);

      try {
        if (isFavorited) {
          // Remove from favorites
          await ApiClient().authenticatedDelete('/job-offers/$jobId/favorite');
        } else {
          // Add to favorites
          await ApiClient().authenticatedPost('/job-offers/$jobId/favorite');
        }

        setState(() {
          isFavorited = !isFavorited;
          _isLoading = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorited ? 'Ajouté aux favoris' : 'Retiré des favoris',
                style: TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
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

    return StatefulBuilder(
      builder: (context, setState) {
        return JobAnnouncementCard(
          companyLogo: companyLogoUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isFavorited: isFavorited,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToJobOfferDetail(job),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
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
              ? () {
                  _seedReactionFromResource('job-offers', jobId, job);
                  return _buildReactionBar('job-offers', jobId);
                }()
              : null,
        );
      },
    );
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

  Future<void> _navigateToJobOfferDetail(Map<String, dynamic> job) async {
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
      if (result == 'deleted' && mounted) _loadJobOffers();
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) =>
      '${apiSlug}_$entityId';

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
    // Always update from resource data to ensure fresh counts
    _reactions[key] = _ReactionData(
      likesCount: _asInt(resource['likes_count']),
      commentsCount: _asInt(resource['comments_count']),
      userReaction: resource['user_reaction']?.toString(),
    );
  }

  Future<void> _refreshReactionFromApi(String apiSlug, String entityId) async {
    try {
      final response = await ApiClient().authenticatedGet('/$apiSlug/$entityId');
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
    final isLiked = data.userReaction == 'like';

    setState(() {
      if (isLiked) {
        data.userReaction = null;
        data.likesCount = (data.likesCount > 0) ? data.likesCount - 1 : 0;
      } else {
        data.userReaction = 'like';
        data.likesCount = data.likesCount + 1;
      }
    });

    try {
      if (isLiked) {
        await ApiClient().authenticatedDelete('/$apiSlug/$entityId/reactions');
      } else {
        await ApiClient().authenticatedPost(
          '/$apiSlug/$entityId/reactions',
          body: {'type': type},
        );
      }
      // Refresh to ensure counts are accurate
      await _refreshReactionFromApi(apiSlug, entityId);
    } catch (e) {
      debugPrint('Reaction toggle error: $e');
      setState(() {
        if (isLiked) {
          data.userReaction = 'like';
          data.likesCount = data.likesCount + 1;
        } else {
          data.userReaction = null;
          data.likesCount = (data.likesCount > 0) ? data.likesCount - 1 : 0;
        }
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

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
                  // Update local comments count
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
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

                  // Recharger le feed pour actualiser les commentaires
                  await _loadBonPlans();
                  await _loadDemandes();
                  await _loadEvents();
                  await _loadJobOffers();
                  await _loadTrainings();
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

                // Refresh reaction counts from API to ensure accuracy
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }
                await _refreshReactionFromApi(apiSlug, entityId);

                // Recharger le feed pour actualiser les commentaires
                await _loadBonPlans();
                await _loadDemandes();
                await _loadEvents();
                await _loadJobOffers();
                await _loadTrainings();

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
              // Get avatar URL from user data - check nested profiles
              final particulierProfile = user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl = particulierProfile?['avatar_url']?.toString()
                  ?? proProfile?['avatar_url']?.toString()
                  ?? proProfile?['logo_url']?.toString()
                  ?? user['avatar_url']?.toString();

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
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(ApiConfig.resolveMediaUrl(avatarUrl) ?? avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: isReply ? 11 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2A8143),
                                  ),
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

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';

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
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, {VoidCallback? onRetry}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(icon, width: 45, height: 45),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Map<String, dynamic> item) {
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
      descriptionPlain,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
