import 'package:flutter/material.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/widgets/post_content_card.dart';

// Helper class for reaction data
class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction;

  _ReactionData({this.likesCount = 0, this.commentsCount = 0, this.userReaction});
}

class EvenementsScreen extends StatefulWidget {
  const EvenementsScreen({super.key});

  @override
  State<EvenementsScreen> createState() => _EvenementsScreenState();
}

class _EvenementsScreenState extends State<EvenementsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    ReactionCacheService.init().then((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient().get(
        '/feed/latest?type=event&limit=20',
      );
      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['items'] as List);
      }
      if (mounted) {
        // Seed reactions BEFORE setState to prevent _getReaction pre-populating with empty data
        for (final item in fetched) {
          final itemId = item['id']?.toString() ?? '';
          if (itemId.isNotEmpty) {
            _seedReactionFromResource('events', itemId, item);
          }
        }
        setState(() {
          _items = fetched;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les évènements.';
          _isLoading = false;
        });
      }
    }
  }

  String? _buildStorageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return ApiConfig.resolveMediaUrl(path);
  }

  String _buildTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return 'il y a ${diff.inDays ~/ 7} semaine(s)';
      if (diff.inDays > 0) return 'il y a ${diff.inDays} jour(s)';
      if (diff.inHours > 0) return 'il y a ${diff.inHours} heure(s)';
      return 'il y a ${diff.inMinutes} min';
    } catch (_) {
      return '';
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

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildNotifBubble() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE6F7EF),
          border: Border.all(color: const Color(0xFF2A8143), width: 1.5),
        ),
        child: const Icon(
          Icons.notifications,
          color: Color(0xFF2A8143),
          size: 18,
        ),
      ),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: const Color(0xFF2A8143),
            automaticallyImplyLeading: false,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double appBarHeight = constraints.maxHeight;
                final double expandRatio =
                    ((appBarHeight - kToolbarHeight) / (120 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                final bool isCollapsed = expandRatio < 0.1;

                return FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A8143), Color(0xFF3AAE5E)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                right: 6,
                              ),
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const Text(
                              'Evènements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'Manjari',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  titlePadding: EdgeInsets.zero,
                  title: isCollapsed
                      ? SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                _buildNotifBubble(),
                              ],
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/profil_pro/reward.png',
                      width: 12,
                      height: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      UserSession().mys.toString(),
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'My\'s',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildNotifBubble(),
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[400], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rechercher un emploi, une entreprise, un lieu...',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[500], size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Event cards
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Aucun évènement disponible pour le moment.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _items[index];
                final resource =
                    item['resource'] as Map<String, dynamic>? ?? {};
                return _buildEventCard(resource);
              }, childCount: _items.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  /// Translates English sub-category codes to French labels
  String _translateSubCategory(String code) {
    const Map<String, String> translations = {
      'AfterworkTeamBuilding': 'Afterwork / Team Building',
      'ConferenceCongressSeminars': 'Conférence / Congrès / Séminaires',
      'SeminarOutings': 'Séminaire / Sorties',
      'TradeShowForumExhibition': 'Salon / Forum / Exposition',
      'OpenDay': 'Journée Portes Ouvertes',
      'EntrepreneurialNetworking': 'Réseautage entrepreneurial',
      'Music': 'Musique',
      'CreativeHobbies': 'Loisir créatifs',
      'MoviesSeries': 'Films & Séries',
      'BooksMagazines': 'Livres & Magazines',
      'ShowsTickets': 'Spectacles & Billeterie',
      'GamblingBetting': 'Jeux de hasard & paris',
      'SportsEvents': 'Événements Sportifs',
      'AutoMotoBoatPlane': 'Auto / Moto / Bateau / Avion',
      'TourismHikingGourmetWalk':
          'Tourisme / Visite / Randonnée / Marche Gourmande',
      'EsportsGamingEvents': 'Événements e-sport / Gaming',
      'WorkshopsInternshipsCourses': 'Ateliers / Stage / Cours',
      'ConferencesProfessionalTraining':
          'Conférences et formations professionnelles',
      'Associative': 'Associatifs',
      'AuctionsCharity': 'Enchères / Charité',
      'SolidarityEvents': 'Manifestations solidaires',
      'ChildrenMuseums': 'Enfants / Musées',
      'AnimalEvents': 'Manifestation Animalière',
      'WorkshopsShowsForChildren': 'Ateliers et spectacles pour enfants',
      'MarketFleaMarketCarBootSale':
          'Marché / Bourse / Brocante / Vide Grenier',
      'TradeFairs': 'Foires commerciales',
      'GamesContestsLottery': 'Jeux / Concours / Loterie',
      'BoardGameTournaments': 'Tournois de jeux de société',
      'TastingsWineCheeseChocolate': 'Dégustations (vin, fromage, chocolat...)',
      'CulinaryFestivals': 'Festivals culinaires',
      'CookingWorkshops': 'Ateliers cuisine',
      'MeditationYogaWellnessRetreats': 'Méditation, yoga, retraites bien-être',
      'ConferencesWorkshopsPersonalDevelopment':
          'Conférences et ateliers sur le développement personnel',
      'AlternativeHealingTherapies': 'Soins et thérapies alternatives',
      'Hackathons': 'Hackathons',
      'TechConferencesStartups': 'Conférences tech & start-up',
      'GamingEsportsEvents': 'Événements gaming & e-sport',
      'FashionShows': 'Défilés de mode',
      'BeautyExhibitionsFairs': 'Salons et foires de la beauté',
      'MakeupSkincareWorkshops': 'Ateliers maquillage et soins',
    };

    return translations[code] ?? code;
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
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/events/$eventId');
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;
      debugPrint('DASHBOARD NAV: data.keys = ${data.keys.toList()}');
      debugPrint('DASHBOARD NAV: data[user] = ${data['user']}');
      debugPrint(
        'DASHBOARD NAV: data[user] runtimeType = ${data['user']?.runtimeType}',
      );

      final user = data['user'] as Map<String, dynamic>?;
      final profileImage = _defaultAvatar;
      final userName = user?['name']?.toString() ?? 'Organisateur';

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
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
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
            title: _translateSubCategory(subCategoryCode),
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

      // Check ownership
      final eventUserId =
          ev['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          eventUserId != null &&
          currentUserId != null &&
          eventUserId == currentUserId;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: profileImage,
            username: isOrganizer
                ? userName
                : (organizerName ?? 'Organisateur'),
            userType: 'Évènement',
            eventTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
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
            isOwner: isOwner,
            eventId: eventId,
            eventData: data,
            returnToListingOnEdit: false,
            authorData: user,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadData();
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
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
    final favoris = event['event_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    bool isFavorited =
        currentUserId != null &&
        favoris.any(
          (f) =>
              f is Map &&
              (f['user_id']?.toString() == currentUserId ||
                  f['user']?['id']?.toString() == currentUserId),
        );

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
              ? _buildReactionBar(
                  'events',
                  eventId,
                  acceptedMessages: event['accept_messages'] == true,
                  authorData: user,
                )
              : null,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REACTION BAR & SUPPORTING METHODS (copied from dashboard)
  // ─────────────────────────────────────────────────────────────

  final Map<String, _ReactionData> _reactions = {};

  String _reactionKey(String apiSlug, String entityId) => '$apiSlug:$entityId';

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
    if (!_reactions.containsKey(key)) {
      final apiReaction = resource['user_reaction']?.toString();
      final userReaction = ReactionCacheService.isCached(apiSlug, entityId)
          ? ReactionCacheService.load(apiSlug, entityId)
          : apiReaction;
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      _reactions[key] = _ReactionData(
        likesCount: (cachedCount != null && cachedCount > apiCount) ? cachedCount : apiCount,
        commentsCount: _asInt(resource['comments_count']),
        userReaction: userReaction,
      );
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

  Future<void> _repostPost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Republier cette publication'),
        content: const Text(
          'Voulez-vous partager cette publication sur votre profil ?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Republier',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient().authenticatedPost('/posts/$postId/repost', body: {});

      // Recharger le feed pour afficher le repost
      await _loadData();

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

  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool acceptedMessages = false,
    Map<String, dynamic>? authorData,
  }) {
    final reaction = _getReaction(apiSlug, entityId);
    final userReaction = reaction.userReaction;
    final likesCount = reaction.likesCount;
    final isPost = apiSlug == 'posts';

    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            children: [
              Icon(
                userReaction == 'like'
                    ? Icons.thumb_up_alt
                    : Icons.thumb_up_alt_outlined,
                size: 18,
                color: userReaction == 'like'
                    ? const Color(0xFF3AAE5E)
                    : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '$likesCount',
                style: TextStyle(
                  fontSize: 12,
                  color: userReaction == 'like'
                      ? const Color(0xFF3AAE5E)
                      : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Comment button
        GestureDetector(
          onTap: () => _showEntityCommentsSheet(apiSlug, entityId),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                reaction.commentsCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Repost button
        if (isPost) ...[
          const SizedBox(width: 10),
          // Repost
          GestureDetector(
            onTap: () => _repostPost(entityId),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Republier',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showEntityCommentsSheet(String apiSlug, String entityId) {
    // Simplified comments sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Expanded(
                child: Center(
                  child: Text(
                    'Chargement des commentaires...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
