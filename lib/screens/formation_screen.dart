import 'package:flutter/material.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/utils/user_session.dart';

// Helper class for reaction data
class _ReactionData {
  int likesCount;
  String? userReaction;

  _ReactionData({this.likesCount = 0, this.userReaction});
}

class FormationScreen extends StatefulWidget {
  const FormationScreen({super.key});

  @override
  State<FormationScreen> createState() => _FormationScreenState();
}

class _FormationScreenState extends State<FormationScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient().get(
        '/feed/latest?type=training&limit=20',
      );
      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['items'] as List);
      }
      if (mounted) {
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
          _error = 'Impossible de charger les formations.';
          _isLoading = false;
        });
      }
    }
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

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String? _buildStorageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('assets/')) return path;
    return "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/$path";
  }

  String get _defaultAvatar =>
      'assets/images/dashboard_particulier/Ellipse 10.png';

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
                              'Formation',
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
                              'Rechercher une formation, un domaine...',
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

          // Formation cards
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
                    'Aucune formation disponible pour le moment.',
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
                return _buildFormationCard(resource);
              }, childCount: _items.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildFormationCard(Map<String, dynamic> training) {
    final trainingId = training['id']?.toString() ?? '';
    final title = training['title']?.toString() ?? 'Formation';
    final description = _stripHtml(training['description']?.toString() ?? '');
    final provider = training['provider_name']?.toString() ?? 'Organisme';
    final duration = training['duration_in_h'];
    final durationUnit = training['duration_unit']?.toString();
    final price = training['price'];
    final category = training['training_category']?.toString() ?? '';
    final subCategory = training['training_sub_category']?.toString() ?? '';
    final trainingType = training['training_type']?.toString() ?? '';

    final addressCity = training['address_city']?.toString() ?? '';

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

    final certification = _extractArrayValues(training['certification']);

    // Check if CPF is in training_funding array
    final trainingFunding = training['training_funding'];
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
          final publicType = training['public_type']?.toString() ?? '';
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
        training['provider_name']?.toString() ??
        'Organisme';

    // Check if already favorited by current user
    final favoris = training['training_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    bool isFavorited =
        currentUserId != null &&
        favoris.any(
          (f) =>
              f is Map &&
              (f['user_id']?.toString() == currentUserId ||
                  f['user']?['id']?.toString() == currentUserId),
        );

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
      timeAgo: _buildTimeAgo(training['created_at']?.toString()),
      isFavorited: isFavorited,
      isLoadingFavorite: isLoading,
      onFavoriteToggle: _toggleFavorite,
      onApply: () => _navigateToTrainingDetail(training),
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
          ? _buildReactionBar('trainings', trainingId)
          : null,
    );
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
      if (result == 'deleted' && mounted) _loadData();
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
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
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = respData['user_reaction']?.toString();
        });
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
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';

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
                'Commenter',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
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
