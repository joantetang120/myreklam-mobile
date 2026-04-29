import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
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

  List<Map<String, dynamic>> _demandes = [];
  bool _isLoadingDemandes = true;
  String? _demandesError;

  List<Map<String, dynamic>> _trainings = [];
  bool _isLoadingTrainings = true;
  String? _trainingsError;

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

  @override
  void initState() {
    super.initState();
    _ensureCurrentUserId();
    _loadFavorisBonPlans();
    _loadFavorisJobOffers();
    _loadFavorisEvents();
    _loadFavorisDemandes();
    _loadFavorisTrainings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorisBonPlans() async {
    setState(() {
      _isLoadingBonPlans = true;
      _bonPlansError = null;
    });
    try {
      debugPrint(
        'Pro: Favoris Fetching bon plans from: /bonplans/my-favorites',
      );
      final response = await ApiClient().authenticatedGet(
        '/bonplans/my-favorites',
      );
      debugPrint(
        'Pro: Favoris Bon plans response keys: ${response.keys.toList()}',
      );
      final data = response['data'];
      debugPrint('Pro: Favoris Bon plans data type: ${data.runtimeType}');
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

  Future<void> _loadFavorisJobOffers() async {
    setState(() {
      _isLoadingJobOffers = true;
      _jobOffersError = null;
    });
    try {
      debugPrint(
        'Pro: Favoris Fetching job offers from: /job-offers/my-favorites',
      );
      final response = await ApiClient().authenticatedGet(
        '/job-offers/my-favorites',
      );
      debugPrint(
        'Pro: Favoris Job offers response keys: ${response.keys.toList()}',
      );
      final data = response['data'];
      debugPrint('Pro: Favoris Job offers data type: ${data.runtimeType}');
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

  Future<void> _loadFavorisDemandes() async {
    setState(() {
      _isLoadingDemandes = true;
      _demandesError = null;
    });
    try {
      debugPrint('Pro: Favoris Fetching demandes from: /demandes/my-favorites');
      final response = await ApiClient().authenticatedGet(
        '/demandes/my-favorites',
      );
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

  Future<void> _loadFavorisEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });
    try {
      debugPrint('Pro: Favoris Fetching events from: /events/my-favorites');
      final response = await ApiClient().authenticatedGet(
        '/events/my-favorites',
      );
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

  Future<void> _loadFavorisTrainings() async {
    setState(() {
      _isLoadingTrainings = true;
      _trainingsError = null;
    });
    try {
      debugPrint(
        'Pro: Favoris Fetching trainings from: /trainings/my-favorites',
      );
      final response = await ApiClient().authenticatedGet(
        '/trainings/my-favorites',
      );
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

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes Favoris',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manjari',
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadFavorisBonPlans(),
            _loadFavorisJobOffers(),
            _loadFavorisEvents(),
            _loadFavorisDemandes(),
            _loadFavorisTrainings(),
          ]);
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // light gray bg
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Faites une recherche...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none, // removes default border
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Filtre par categorie",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // TextButton(
                    //   onPressed: () {},
                    //   style: ButtonStyle(
                    //     backgroundColor: WidgetStateProperty.all(Colors.orange),
                    //     padding: WidgetStateProperty.all(
                    //       const EdgeInsets.symmetric(
                    //         horizontal: 16,
                    //         vertical: 10,
                    //       ),
                    //     ),
                    //     minimumSize: WidgetStateProperty.all(Size.zero),
                    //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //     shape: WidgetStateProperty.all(
                    //       RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(6),
                    //       ),
                    //     ),
                    //   ),
                    //   child: const Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(
                    //         Icons.line_weight_sharp,
                    //         color: Colors.white,
                    //         size: 16,
                    //       ),
                    //       SizedBox(width: 8),
                    //       Text(
                    //         "Plus récents",
                    //         style: TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 13,
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //       SizedBox(width: 6),
                    //       Icon(
                    //         Icons.arrow_drop_down_outlined,
                    //         color: Colors.white,
                    //         size: 20,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        CategoriesIcon(
                          title: "Bons plans",
                          iconColor: const Color.fromARGB(255, 252, 116, 37),
                          bgColor: Color(0xFFFFE0B2).withOpacity(0.2),
                          icon: Icons.card_giftcard_outlined,
                          onTap: () =>
                              setState(() => selectedCategory = "Bons plans"),
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Offre d'emploi",
                          iconColor: Colors.lightBlueAccent,
                          bgColor: Color(0xFFB3E5FC).withOpacity(0.2),
                          iconAsset: 'assets/images/offres.png',
                          onTap: () => setState(
                            () => selectedCategory = "Offre d'emploi",
                          ),
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Formations",
                          iconColor: Colors.purple,
                          bgColor: Color(0xFFE1BEE7).withOpacity(0.1),
                          iconAsset: 'assets/images/Formation.png',
                          onTap: () =>
                              setState(() => selectedCategory = "Formations"),
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Evenements",
                          iconColor: Colors.green,
                          bgColor: Color(0xFFE6F7EF).withOpacity(0.5),
                          icon: Icons.event_outlined,
                          onTap: () =>
                              setState(() => selectedCategory = "Evenements"),
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
                          onTap: () =>
                              setState(() => selectedCategory = "Demandes"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Dynamic content
              _buildContent(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (selectedCategory == 'Bons plans') return _buildFavorisBonPlansList();
    if (selectedCategory == "Offre d'emploi")
      return _buildFavorisJobOffersList();
    if (selectedCategory == 'Formations') return _buildFavorisTrainingsList();
    if (selectedCategory == 'Evenements') return _buildFavorisEventsList();
    if (selectedCategory == 'Demandes') return _buildFavorisDemandesList();
    return _buildEmptyState('Bientôt disponible pour cette catégorie');
  }

  Widget _buildFavorisDemandesList() {
    if (_isLoadingDemandes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_demandesError != null) {
      return _buildErrorState(_demandesError!, onRetry: _loadFavorisDemandes);
    }
    final items = _filteredDemandes;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune demande trouvée pour "$_searchQuery"'
            : 'Aucun favoris sur les demandes',
      );
    }
    return Column(children: items.map(_buildDemandeCard).toList());
  }

  Widget _buildDemandeCard(Map<String, dynamic> d) {
    final title = d['title']?.toString() ?? '';
    final description = d['description']?.toString() ?? '';
    final nature = d['nature']?.toString() ?? '';
    final type = d['type']?.toString() ?? '';
    final location = d['location']?.toString() ?? '';
    final nationwide = d['nationwide'] == true;
    final createdAt = d['created_at']?.toString();
    final user = d['user'] is Map<String, dynamic>
        ? d['user'] as Map<String, dynamic>
        : null;
    final mediaFiles = d['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? _buildImageUrl(mediaFiles.first['url']?.toString() ?? '')
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
            ((p['first_name']?.toString() != null &&
                    p['last_name']?.toString() != null)
                ? '${p['first_name']} ${p['last_name']}'
                : user['email']?.toString().split('@').first) ??
            'Utilisateur';
      }
    }

    String profileImage = 'assets/images/default_profile.png';
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
      if (profileImage.isNotEmpty && !profileImage.startsWith('assets/')) {
        profileImage = _buildImageUrl(profileImage);
      }
    }

    final displayLocation = nationwide
        ? 'Toute la France'
        : (location.isNotEmpty ? location : 'Non spécifié');

    return DemandeCard(
      profileImage: profileImage,
      username: username,
      categoryLabel: nature.isNotEmpty ? _getNatureLabel(nature) : 'Demande',
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
      onTapCTA: () => _navigateToDemandeDetail(d),
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
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
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
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
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
      if (result == 'deleted' && mounted) _loadFavorisDemandes();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Widget _buildFavorisTrainingsList() {
    if (_isLoadingTrainings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_trainingsError != null) {
      return _buildErrorState(_trainingsError!, onRetry: _loadFavorisTrainings);
    }
    final items = _filteredTrainings;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune formation trouvée pour "$_searchQuery"'
            : 'Aucun favoris sur les formations',
      );
    }
    return Column(children: items.map(_buildTrainingCard).toList());
  }

  Widget _buildTrainingCard(Map<String, dynamic> tr) {
    final title = tr['title']?.toString() ?? '';
    final description = _stripHtml(tr['description']?.toString() ?? '');
    final createdAt = tr['created_at']?.toString();
    final price = tr['price'];
    final durationHours = tr['duration_in_h'];
    final durationUnit = tr['duration_unit']?.toString();
    final status = tr['status']?.toString() ?? '';
    final category = tr['training_category']?.toString() ?? '';
    final subCategory = tr['training_sub_category']?.toString() ?? '';
    final trainingType = tr['training_type']?.toString() ?? '';

    final companyName = tr['user']['pro_profile'] != null
        ? tr['user']['pro_profile']['company_name']?.toString()
        : tr['user']['particulier_profile']['pseudo']?.toString();

    final avatar = tr['user']['pro_profile'] != null
        ? tr['user']['pro_profile']['avatar_url']?.toString()
        : tr['user']['particulier_profile']['avatar_url']?.toString();

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

    final trId = tr['id']?.toString() ?? '';

    print("Traing: $trId");

    // Check initial favorite status
    final bool isFavorited = tr['is_favorited'];

    bool _isFavorited = isFavorited;
    bool _isLoading = false;

    Future<void> _toggleFavorite() async {
      if (_isLoading || trId.isEmpty) return;

      setState(() => _isLoading = true);

      try {
        if (_isFavorited) {
          // Remove from favorites
          await ApiClient().authenticatedDelete('/trainings/$trId/favorite');
          _loadFavorisTrainings();
        } else {
          // Add to favorites
          await ApiClient().authenticatedPost('/trainings/$trId/favorite');
          _loadFavorisTrainings();
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

    return FormationCard(
      companyLogo: avatar ?? 'assets/images/Formation.png',
      companyName: companyName ?? 'Ma formation',
      formationTitle: title,
      description: description.isNotEmpty
          ? description
          : 'Aucune description fournie.',
      tags: tags,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: () => _navigateToTrainingDetail(tr),
      isFavorited: isFavorited,
      onFavoriteToggle: _toggleFavorite,
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/trainings/$trainingId',
      );
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final companyName = data['company_name']?.toString() ?? 'Organisme';
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
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
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
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
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

      if (!mounted) return;
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
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            showLocation: showLocation,
            certification: certification,
            documents: documents,
            isOwner: true,
            trainingId: trainingId,
            trainingData: data,
            returnToListingOnEdit: true,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadFavorisTrainings();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Widget _buildFavorisBonPlansList() {
    if (_isLoadingBonPlans) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_bonPlansError != null) {
      return _buildErrorState(_bonPlansError!, onRetry: _loadFavorisBonPlans);
    }
    final items = _filteredBonPlans;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucun bon plan trouvé pour "$_searchQuery"'
            : 'Aucun favoris sur les bons plans',
      );
    }
    return Column(children: items.map((bp) => _buildBonPlanCard(bp)).toList());
  }

  Widget _buildFavorisJobOffersList() {
    if (_isLoadingJobOffers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_jobOffersError != null) {
      return _buildErrorState(_jobOffersError!, onRetry: _loadFavorisJobOffers);
    }
    final items = _filteredJobOffers;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucune offre trouvée pour "$_searchQuery"'
            : "Aucun favoris sur les offre d'emploi",
      );
    }
    return Column(children: items.map((jo) => _buildJobOfferCard(jo)).toList());
  }

  Widget _buildFavorisEventsList() {
    if (_isLoadingEvents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFEF8A40)),
        ),
      );
    }
    if (_eventsError != null) {
      return _buildErrorState(_eventsError!, onRetry: _loadFavorisEvents);
    }
    final items = _filteredEvents;
    if (items.isEmpty) {
      return _buildEmptyState(
        _searchQuery.isNotEmpty
            ? 'Aucun événement trouvé pour "$_searchQuery"'
            : 'Aucun favoris sur les événements',
      );
    }
    return Column(children: items.map((ev) => _buildEventCard(ev)).toList());
  }

  Widget _buildEventCard(Map<String, dynamic> ev) {
    final title = ev['title']?.toString() ?? '';
    final createdAt = ev['created_at']?.toString();
    final priceType = ev['price_type']?.toString() ?? 'gratuit';
    final priceAmount = ev['price_amount'];
    final isNationwide = ev['is_nationwide'] == true;
    final coverageArea = isNationwide
        ? 'Toute la France'
        : (ev['coverage_area']?.toString() ?? '');
    final eventDate = ev['event_date']?.toString();
    final startDate = ev['start_date']?.toString();
    final durationType = ev['duration_type']?.toString() ?? '';
    final categoryCode = ev['category_code']?.toString() ?? '';
    final subCategoryCode = ev['sub_category_code']?.toString() ?? '';
    final formatType = ev['format_type']?.toString() ?? '';

    final mediaFiles = ev['media_files'] as List? ?? [];
    final eventImage = mediaFiles.isNotEmpty
        ? _buildImageUrl(mediaFiles.first['url']?.toString() ?? '')
        : 'assets/images/default_event.png';

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

    final categories = <String>[
      if (categoryCode.isNotEmpty) categoryCode,
      if (subCategoryCode.isNotEmpty) subCategoryCode,
      if (formatType.isNotEmpty) formatType,
    ];

    // Extract user data for event card
    final eventUser = ev['user'] is Map<String, dynamic>
        ? ev['user'] as Map<String, dynamic>
        : null;
    String eventUsername = 'Mon événement';
    String eventAvatar = '';
    if (eventUser != null) {
      if (eventUser['pro_profile'] is Map) {
        final p = eventUser['pro_profile'] as Map;
        final n = p['company_name']?.toString() ?? '';
        if (n.isNotEmpty) eventUsername = n;
        final logo =
            p['avatar_url']?.toString() ?? p['logo_url']?.toString() ?? '';
        if (logo.isNotEmpty) eventAvatar = _buildImageUrl(logo);
      } else if (eventUser['particulier_profile'] is Map) {
        final p = eventUser['particulier_profile'] as Map;
        final n = p['pseudo']?.toString() ?? '';
        if (n.isNotEmpty) eventUsername = n;
        final logo = p['avatar_url']?.toString() ?? '';
        if (logo.isNotEmpty) eventAvatar = _buildImageUrl(logo);
      }
    }

    final evId = ev['id'];

    final bool isFavorited = ev['is_favorited'];

    bool _isFavorited = isFavorited;
    bool _isLoading = false;

    Future<void> _toggleFavorite() async {
      if (_isLoading || evId.isEmpty) return;

      setState(() => _isLoading = true);

      try {
        if (_isFavorited) {
          // Remove from favorites
          await ApiClient().authenticatedDelete('/events/$evId/favorite');
          _loadFavorisEvents();
        } else {
          // Add to favorites
          await ApiClient().authenticatedPost('/events/$evId/favorite');
          _loadFavorisEvents();
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

    return EvenementCard(
      profileImage: eventAvatar.isNotEmpty
          ? eventAvatar
          : 'assets/images/default_profile.png',
      username: eventUsername,
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
      onTapCTA: () => _navigateToEventDetail(ev),
      isFavorite: isFavorited,
      onFavoriteToggle: _toggleFavorite,
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
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();
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
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
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
      if (result == 'deleted' && mounted) _loadFavorisEvents();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
  }

  Widget _buildBonPlanCard(Map<String, dynamic> bp) {
    final title = bp['title'] ?? '';
    final category = bp['category'] ?? '';
    final subCategory = bp['sub_category'] ?? '';
    final type = bp['type'] ?? '';
    final status = bp['status']?.toString() ?? '';
    final merchantName = bp['available_at_name'] ?? '';
    final locationType = bp['available_location_type'] ?? '';
    final createdAt = bp['created_at']?.toString();
    final mediaFiles = bp['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? mediaFiles.first['url']?.toString()
        : null;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
          // Header with status badge
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
          // Description
          _buildDescription(bp),
          // Image
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _buildImageUrl(imageUrl),
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, error, ___) {
                  debugPrint('Image load error: $error');
                  return Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Category & type tags
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
          // Merchant + time
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToBonPlanDetail(bp),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('VOIR LE BON PLAN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF8A40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobOfferCard(Map<String, dynamic> jo) {
    final title = jo['title'] ?? '';
    final contractType = jo['contract_type'] ?? '';
    final workTime = jo['work_time'] ?? '';
    final companyRaw = jo['company'];
    final companyName = companyRaw is Map
        ? (companyRaw['name'] ?? '')
        : (companyRaw ?? '').toString();
    final city = jo['location'];
    final createdAt = jo['created_at']?.toString();
    final categoryRaw = jo['category'];
    final categoryName = categoryRaw is Map
        ? (categoryRaw['name'] ?? '')
        : (categoryRaw ?? '').toString();
    final advantages = jo['advantages'] as List? ?? [];
    final salaryMin = jo['salary_min'];
    final salaryMax = jo['salary_max'];
    final educationLevel = jo['education_level'];
    final experienceLevel = jo['experience_level'];

    // Extract description
    String description = '';
    final descriptionDelta = jo['description_delta'];
    if (descriptionDelta != null) {
      try {
        List opsList;
        if (descriptionDelta is List) {
          opsList = descriptionDelta;
        } else if (descriptionDelta is Map && descriptionDelta['ops'] is List) {
          opsList = descriptionDelta['ops'] as List;
        } else if (descriptionDelta is String && descriptionDelta.isNotEmpty) {
          final decoded = jsonDecode(descriptionDelta);
          opsList = decoded is List ? decoded : (decoded['ops'] as List);
        } else {
          throw Exception('Unsupported type');
        }
        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();
        if (filteredOps.isNotEmpty) {
          final lastInsert = filteredOps.last['insert'];
          if (lastInsert is String && !lastInsert.endsWith('\n')) {
            filteredOps.add({'insert': '\n'});
          }
          final doc = quill.Document.fromJson(filteredOps);
          description = doc.toPlainText().trim();
          if (description.length > 150) {
            description = '${description.substring(0, 150)}...';
          }
        }
      } catch (e) {
        description = jo['description']?.toString() ?? '';
      }
    } else {
      description = jo['description']?.toString() ?? '';
    }

    // Build tags
    final tags = <JobDetailTag>[
      if (contractType.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contractType),
      if (workTime.isNotEmpty)
        JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
      if (city.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: city),
      if (categoryName.isNotEmpty)
        JobDetailTag(icon: Icons.category_outlined, text: categoryName),
      if (educationLevel.isNotEmpty)
        JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
      if (experienceLevel.isNotEmpty)
        JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
      if (salaryMin != null || salaryMax != null)
        JobDetailTag(
          icon: Icons.euro,
          text: _formatSalary(salaryMin, salaryMax),
          isSpecial: true,
        ),
    ];

    // Build advantages list
    final advantagesList = advantages.take(3).map((a) => a.toString()).toList();

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

    final jobId = jo['id']?.toString() ?? '';

    // Check initial favorite status
    final bool isFavorited = jo['is_favorited'];

    bool _isFavorited = isFavorited;
    bool _isLoading = false;

    Future<void> _toggleFavorite() async {
      if (_isLoading || jobId.isEmpty) return;

      setState(() => _isLoading = true);

      try {
        if (_isFavorited) {
          // Remove from favorites
          await ApiClient().authenticatedDelete('/job-offers/$jobId/favorite');
          _loadFavorisJobOffers();
        } else {
          // Add to favorites
          await ApiClient().authenticatedPost('/job-offers/$jobId/favorite');
          _loadFavorisJobOffers();
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

    return JobAnnouncementCard(
      companyLogo: cardCompanyLogo,
      companyName: cardCompanyName,
      jobTitle: title,
      description: description,
      tags: tags,
      advantages: advantagesList,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: () => _navigateToJobOfferDetail(jo),
      isFavorited: _isFavorited,
      onFavoriteToggle: _toggleFavorite,
    );
  }

  Future<void> _navigateToJobOfferDetail(Map<String, dynamic> jo) async {
    final jobId = jo['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette offre')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/job-offers/$jobId');
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

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
      final locationCity = data['location_city']?.toString();
      final locationPostalCode = data['location_postal_code']?.toString();

      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString())
          : (categoryRaw?.toString() ?? '');

      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];

      final remoteWork = data['remote_work'] == true;

      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
          : educationLevelRaw?.toString();

      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
          : experienceLevelRaw?.toString();

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

      final images = mediaRaw
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      if (images.isEmpty) {
        images.add('assets/images/dashboard_particulier/Rectangle 13.png');
      }

      final tags = <JobDetailTag>[
        if (contractType.isNotEmpty)
          JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime.isNotEmpty)
          JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (educationLevel != null && educationLevel.isNotEmpty)
          JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      final advantagesList = advantages
          .take(3)
          .map((a) => a.toString())
          .toList();

      final currentUserId = await _ensureCurrentUserId();
      final jobUserId =
          data['user_id']?.toString() ?? jo['user_id']?.toString();
      final isOwner =
          currentUserId != null &&
          jobUserId != null &&
          currentUserId == jobUserId;

      final authorData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;
      final acceptMessages = data['accept_messages'] == true;

      final avatar = data['user']['avatar_url'];

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo:
                avatar ??
                'assets/images/dashboard_particulier/Rectangle 13.png',
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
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
            location: location,
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobId,
            jobOfferData: data,
            acceptMessages: acceptMessages,
            authorData: authorData,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadFavorisJobOffers();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
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
            locationCity: locationCity,
            locationPostalCode: locationPostalCode,
            link: link,
            isOwner: true,
            bonPlanId: bonPlanId,
            bonPlanData: data,
            acceptMessages: acceptMessages,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadFavorisBonPlans();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      debugPrint('Error fetching bon plan detail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement: $e')));
    }
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

  String _getNatureLabel(String nature) {
    switch (nature.toLowerCase()) {
      // Main categories from the new table
      case 'searchjob':
        return 'Recherche d\'emploi';
      case 'training':
        return 'Formation';
      case 'realestate':
        return 'Immobilier';
      case 'servicehelp':
        return 'Services / Aide';
      case 'promaterial':
        return 'Matériel pro';
      case 'house':
        return 'Maison';
      case 'fashion':
        return 'Mode';
      case 'vehicle':
        return 'Véhicules';
      case 'holiday':
        return 'Vacances';
      case 'multimedia':
        return 'Multimédia';
      case 'hobbies':
        return 'Loisirs';
      case 'animals':
        return 'Animaux';
      case 'various':
        return 'Divers';
      // Legacy mappings for backward compatibility
      case 'emploi':
        return 'Recherche d\'emploi';
      case 'service':
        return 'Services / Aide';
      case 'logement':
        return 'Immobilier';
      case 'formation':
        return 'Formation';
      case 'internship':
      case 'stage':
        return 'Recherche de stage / alternance';
      case 'product':
      case 'produit':
        return 'Recherche de produit';
      case 'collaboration':
        return 'Collaboration';
      default:
        return nature;
    }
  }
}
