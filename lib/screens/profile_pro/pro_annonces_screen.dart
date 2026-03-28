import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/formation_card.dart';

class ProAnnoncesScreen extends StatefulWidget {
  const ProAnnoncesScreen({super.key});

  @override
  State<ProAnnoncesScreen> createState() => _ProAnnoncesScreenState();
}

class _ProAnnoncesScreenState extends State<ProAnnoncesScreen> {
  String selectedCategory = 'Bons plans';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  void initState() {
    super.initState();
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
    setState(() { _isLoadingBonPlans = true; _bonPlansError = null; });
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
    setState(() { _isLoadingJobOffers = true; _jobOffersError = null; });
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
    setState(() { _isLoadingDemandes = true; _demandesError = null; });
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
    setState(() { _isLoadingEvents = true; _eventsError = null; });
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
    setState(() { _isLoadingTrainings = true; _trainingsError = null; });
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
      return title.contains(q) || desc.contains(q) || nature.contains(q) || type.contains(q);
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
    return value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int get _totalCount => _bonPlans.length + _jobOffers.length + _events.length + _demandes.length + _trainings.length;

  int get _activeCount {
    final activeBp = _bonPlans.where((bp) =>
        bp['status'] == 'published' || bp['status'] == 'PUBLISHED').length;
    final activeJo = _jobOffers.where((jo) =>
        jo['status'] == 'PUBLISHED' || jo['status'] == 'published').length;
    final activeEvents = _events.where((ev) =>
        (ev['status'] ?? '').toString().toUpperCase() == 'PUBLISHED').length;
    final activeDemandes = _demandes.where((d) =>
        (d['status'] ?? '').toString().toUpperCase() == 'PUBLISHED').length;
    return activeBp + activeJo + activeEvents + activeDemandes;
  }

  int get _expiredCount {
    final expBp = _bonPlans.where((bp) =>
        bp['status'] == 'rejected' || bp['status'] == 'REJECTED' ||
        bp['status'] == 'ARCHIVED' || bp['status'] == 'archived').length;
    final expJo = _jobOffers.where((jo) =>
        jo['status'] == 'REJECTED' || jo['status'] == 'rejected' ||
        jo['status'] == 'ARCHIVED' || jo['status'] == 'archived').length;
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
      final response = await ApiClient().authenticatedGet('/bonplans/$bonPlanId');
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
      final username = user?['display_name']?.toString() ?? 
          user?['name']?.toString() ?? 
          'Mon bon plan';
      final userType = user?['account_type']?.toString() ?? 'Professionnel';
      final title = data['title']?.toString() ?? 'Bon plan';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final category = data['category']?.toString() ?? '';
      final subCategory = data['sub_category']?.toString() ?? '';
      final type = data['type']?.toString() ?? '';
      final availableAt = data['available_at_name']?.toString() ?? 'Non spécifié';
      final validityType = data['validity_type']?.toString() ?? 'permanent';
      final validFrom = data['valid_from']?.toString();
      final validUntil = data['valid_until']?.toString();
      final link = data['link']?.toString();
      final pickupMethods = data['pickup_methods'] as Map<String, dynamic>?;
      final deliveryInfo = _buildDeliveryInfo(pickupMethods);
      final location = data['location_search']?.toString();
      final mediaFiles = data['media_files'] as List?;
      final images = _extractImages(mediaFiles);
      final reductionLabel = data['reduction_label']?.toString();

      final tags = <PostTag>[
        if (category.isNotEmpty)
          PostTag(title: category, icon: Icons.local_offer_outlined, color: Colors.orange),
        if (subCategory.isNotEmpty)
          PostTag(title: subCategory, icon: Icons.grid_view_outlined, color: Colors.grey),
        if (type.isNotEmpty)
          PostTag(title: type, icon: Icons.check_circle_outline, color: Colors.green),
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
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadBonPlans();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      debugPrint('Error fetching bon plan detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
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
    return images.isNotEmpty ? images : ['assets/images/details_bon_plans/Rectangle 35.png'];
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
      case 'PUBLISHED': return 'Publié';
      case 'PENDING_REVIEW': return 'En attente';
      case 'DRAFT': return 'Brouillon';
      case 'REJECTED': return 'Rejeté';
      case 'ARCHIVED': return 'Archivé';
      default: return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PUBLISHED': return const Color(0xFF4CAF50);
      case 'PENDING_REVIEW': return const Color(0xFFFF9800);
      case 'DRAFT': return Colors.grey;
      case 'REJECTED': return const Color(0xFFF44336);
      case 'ARCHIVED': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String _buildImageUrl(String? url) {
    if (url == null) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    String fullUrl = url;
    if (url.startsWith('http')) {
      fullUrl = url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
    } else {
      fullUrl = '$serverBase$url';
    }
    debugPrint('Image URL: $fullUrl');
    return fullUrl;
  }

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME': return 'Temps plein';
      case 'PART_TIME': return 'Temps partiel';
      default: return val;
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
          await Future.wait([_loadBonPlans(), _loadJobOffers(), _loadEvents(), _loadDemandes()]);
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
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                          borderSide: const BorderSide(color: Color(0xFF2E9B5B)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                                builder: (context) => const PublishOptionsScreen(),
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
                            onTap: () => setState(() => selectedCategory = 'Bons plans'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: "Offre d'emploi",
                            iconColor: Colors.lightBlueAccent,
                            bgColor: const Color(0xFFB3E5FC).withOpacity(0.2),
                            iconAsset: 'assets/images/offres.png',
                            onTap: () => setState(() => selectedCategory = "Offre d'emploi"),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Formations',
                            iconColor: Colors.purple,
                            bgColor: const Color(0xFFE1BEE7).withOpacity(0.1),
                            iconAsset: 'assets/images/Formation.png',
                            onTap: () => setState(() => selectedCategory = 'Formations'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Evenements',
                            iconColor: Colors.green,
                            bgColor: const Color(0xFFE6F7EF).withOpacity(0.5),
                            icon: Icons.event_outlined,
                            onTap: () => setState(() => selectedCategory = 'Événement'),
                          ),
                          const SizedBox(width: 15),
                          CategoriesIcon(
                            title: 'Demandes',
                            iconColor: const Color.fromARGB(255, 252, 231, 49),
                            bgColor: const Color.fromARGB(255, 255, 250, 178).withOpacity(0.2),
                            icon: Icons.chat_outlined,
                            onTap: () => setState(() => selectedCategory = 'Demandes'),
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
    return Column(
      children: items.map(_buildDemandeCard).toList(),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> d) {
    final title = d['title']?.toString() ?? '';
    final description = d['description']?.toString() ?? '';
    final nature = d['nature']?.toString() ?? '';
    final type = d['type']?.toString() ?? '';
    final location = d['location']?.toString() ?? '';
    final nationwide = d['nationwide'] == true;
    final createdAt = d['created_at']?.toString();
    final mediaFiles = d['media_files'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? _buildImageUrl(mediaFiles.first['url']?.toString() ?? '')
        : null;

    final categoryLabel = type.isNotEmpty ? type : (nature.isNotEmpty ? nature : 'Demande');
    final displayLocation = nationwide
        ? 'Toute la France'
        : (location.isNotEmpty ? location : 'Non spécifié');

    return DemandeCard(
      profileImage: 'assets/images/default_profile.png',
      username: 'Ma demande',
      categoryLabel: categoryLabel,
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
      final response = await ApiClient().authenticatedGet('/demandes/$demandeId');
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final nature = data['nature']?.toString();
      final type = data['type']?.toString();
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
      final mediaFiles = data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      final categoryLabel = (type != null && type.isNotEmpty)
          ? type
          : (nature != null && nature.isNotEmpty ? nature : 'Demande');

      final tags = <PostTag>[
        PostTag(title: categoryLabel, icon: Icons.label_outline, color: Colors.orange),
        if (urgent)
          PostTag(title: 'Urgent', icon: Icons.warning_amber_rounded, color: Colors.red),
        if (nationwide)
          PostTag(title: 'Toute la France', icon: Icons.public, color: Colors.blue),
      ];

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: 'assets/images/default_profile.png',
            username: 'Ma demande',
            userType: categoryLabel,
            demandeTitle: title,
            description: description,
            tags: tags,
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
            isOwner: true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
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
    return Column(
      children: items.map(_buildTrainingCard).toList(),
    );
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
          text: '$durationHours h${durationUnit != null ? ' / $durationUnit' : ''}',
        ),
      if (status.isNotEmpty)
        FormationTag(icon: Icons.flag_outlined, text: _statusLabel(status)),
    ];

    return FormationCard(
      companyLogo: 'assets/images/Formation.png',
      companyName: 'Ma formation',
      formationTitle: title,
      description: description.isNotEmpty ? description : 'Aucune description fournie.',
      tags: tags,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: () => _navigateToTrainingDetail(tr),
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
      final response = await ApiClient().authenticatedGet('/trainings/$trainingId');
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
      final showLocation = data['show_location'] == true;
      final certificationRaw = data['certification'];
      final certification = certificationRaw is List
          ? certificationRaw.map((e) => e.toString()).toList()
          : <String>[];
      final createdAt = data['created_at']?.toString();
      final mediaFiles = data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

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
            showLocation: showLocation,
            certification: certification,
            isOwner: true,
            trainingId: trainingId,
            trainingData: data,
            returnToListingOnEdit: true,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadTrainings();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
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
    return Column(
      children: items.map((bp) => _buildBonPlanCard(bp)).toList(),
    );
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
    return Column(
      children: items.map((jo) => _buildJobOfferCard(jo)).toList(),
    );
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
    return Column(
      children: items.map((ev) => _buildEventCard(ev)).toList(),
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

    return EvenementCard(
      profileImage: 'assets/images/default_profile.png',
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
      onTapCTA: () => _navigateToEventDetail(ev),
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
      final priceCategories = (data['price_categories'] as List?)
          ?.map<Map<String, dynamic>>((c) => Map<String, dynamic>.from(c as Map))
          .toList() ?? <Map<String, dynamic>>[];
      final reservationMode = data['reservation_mode']?.toString();
      final coverageArea = data['coverage_area']?.toString();
      final isNationwide = data['is_nationwide'] == true;
      final organizerName = data['organizer_name']?.toString();
      final isOrganizer = data['is_organizer'] != false;
      final websiteUrl = data['website_url']?.toString();
      final landingUrl = data['landing_url']?.toString();
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles = data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      final tags = <PostTag>[
        if (categoryCode != null && categoryCode.isNotEmpty)
          PostTag(title: categoryCode, icon: Icons.local_offer_outlined, color: Colors.green),
        if (subCategoryCode != null && subCategoryCode.isNotEmpty)
          PostTag(title: subCategoryCode, icon: Icons.grid_view_outlined, color: Colors.grey),
        if (formatType != null && formatType.isNotEmpty)
          PostTag(title: formatType, icon: Icons.videocam_outlined, color: Colors.blue),
      ];

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: 'assets/images/default_profile.png',
            username: isOrganizer ? 'Mon événement' : (organizerName ?? 'Organisateur'),
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
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadEvents();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
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
    final imageUrl = mediaFiles.isNotEmpty ? mediaFiles.first['url']?.toString() : null;

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
                  border: Border.all(color: _statusColor(status).withOpacity(0.5)),
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
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (_, error, ___) {
                  debugPrint('Image load error: $error');
                  return Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
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
              if (category.isNotEmpty) _buildTag(category, Icons.local_offer_outlined),
              if (subCategory.isNotEmpty) _buildTag(subCategory, Icons.subdirectory_arrow_right),
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
    final companyName = companyRaw is Map ? (companyRaw['name'] ?? '') : (companyRaw ?? '').toString();
    final locationRaw = jo['location'];
    final city = locationRaw is Map ? (locationRaw['city'] ?? '') : '';
    final createdAt = jo['created_at']?.toString();
    final categoryRaw = jo['category'];
    final categoryName = categoryRaw is Map ? (categoryRaw['name'] ?? '') : (categoryRaw ?? '').toString();
    final advantages = jo['advantages'] as List? ?? [];
    final salaryMin = jo['salary_min'];
    final salaryMax = jo['salary_max'];
    
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
      if (categoryName.isNotEmpty)
        JobDetailTag(icon: Icons.category_outlined, text: categoryName),
      if (city.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: city),
      if (salaryMin != null || salaryMax != null)
        JobDetailTag(
          icon: Icons.euro,
          text: _formatSalary(salaryMin, salaryMax),
          isSpecial: true,
        ),
    ];
    
    // Build advantages list
    final advantagesList = advantages.take(3).map((a) => a.toString()).toList();

    return JobAnnouncementCard(
      companyLogo: '',
      companyName: companyName.isNotEmpty ? companyName : 'Entreprise',
      jobTitle: title,
      description: description,
      tags: tags,
      advantages: advantagesList,
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      onApply: () {
        // Handle view job offer action
      },
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
              TextButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
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
      style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
