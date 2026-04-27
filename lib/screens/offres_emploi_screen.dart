import 'package:flutter/material.dart';
import 'package:myreklam/services/share_service.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/user_session.dart';

class OffresEmploiScreen extends StatefulWidget {
  const OffresEmploiScreen({super.key});

  @override
  State<OffresEmploiScreen> createState() => _OffresEmploiScreenState();
}

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction; // 'like' or null

  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userReaction,
  });
}

class _OffresEmploiScreenState extends State<OffresEmploiScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  // Reaction state per entity: key = "entityType:entityId"
  final Map<String, _ReactionData> _reactions = {};

  @override
  void initState() {
    super.initState();
    _ensureCurrentUserId();
    ReactionCacheService.init().then((_) => _loadData());
  }

  Future<String?> _ensureCurrentUserId() async {
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      return _currentUserId;
    }
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient().get(
        '/feed/latest?type=job_offer&limit=20',
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
            _seedReactionFromResource('job-offers', itemId, item, force: true);
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
          _error = "Impossible de charger les offres d'emploi.";
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
                              "Offres d'emploi",
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

          // Job cards
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
                    "Aucune offre d'emploi disponible pour le moment.",
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
                return _buildJobCard(resource);
              }, childCount: _items.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
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

    // Check initial favorite status
    final favoris = job['job_offer_favorites'] as List? ?? [];
    final bool initialIsFavorited = favoris.isNotEmpty;

    // Use ValueNotifier for state that persists across rebuilds
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

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

    // Extract display name: company_name for pros, pseudo for particuliers
    final String companyName =
        proProfile?['company_name']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        job['company_name']?.toString() ??
        'Entreprise';

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ??
        'assets/images/dashboard_particulier/Rectangle 13.png';

    return StatefulBuilder(
      builder: (context, setState) {
        bool _isLoading = false;

        Future<void> _toggleFavorite() async {
          if (_isLoading || jobId.isEmpty) return;

          // Toggle immediately for responsive UI
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => _isLoading = true);

          try {
            if (!isFavoritedNotifier.value) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (job['job_offer_favorites'] is List) {
                (job['job_offer_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == UserSession().id ||
                          f['user']?['id']?.toString() == UserSession().id),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (job['job_offer_favorites'] is! List) {
                job['job_offer_favorites'] = [];
              }
              (job['job_offer_favorites'] as List).add({
                'user_id': UserSession().id,
                'user': {'id': UserSession().id},
              });
            }

            setState(() {
              _isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavoritedNotifier.value
                        ? 'Ajouté aux favoris'
                        : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => _isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return JobAnnouncementCard(
          companyLogo: companyLogoUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: _isLoading,
          onFavoriteToggle: _toggleFavorite,
          onApply: () => _navigateToJobDetail(job),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isProUser
                      ? ProPublicViewScreen(userId: user!['id'].toString())
                      : ParticulierPublicViewScreen(
                          userId: user!['id'].toString(),
                        ),
                ),
              );
            }
          },
          reactionBar: jobId.isNotEmpty
              ? _buildReactionBar('job-offers', jobId)
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

  Future<void> _navigateToJobDetail(Map<String, dynamic> job) async {
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
      if (result == 'deleted' && mounted) _loadData();
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
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

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME':
        return 'Temps plein';
      case 'PART_TIME':
        return 'Temps partiel';
      case 'INTERIM':
        return 'Intérim';
      case 'FREELANCE':
        return 'Freelance';
      case 'ALTERNANCE':
        return 'Alternance';
      case 'STAGE':
        return 'Stage';
      default:
        return val;
    }
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/$url';
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

  // ── Real comments sheet ─────────────────────────────────────────

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
                  // Update local comments count in feed
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
                    ReactionCacheService.saveCommentsCount(
                      apiSlug,
                      entityId,
                      data.commentsCount,
                    );
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

                // Update local comments count in feed
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }

                // Refresh reaction counts from API to ensure accuracy
                await _refreshReactionFromApi(apiSlug, entityId);

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
                        (user['particulier_profile']
                                as Map<String, dynamic>?)?['pseudo']
                            ?.toString() ??
                        (user['pro_profile']
                                as Map<String, dynamic>?)?['company_name']
                            ?.toString() ??
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
              final particulierProfile =
                  user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl =
                  particulierProfile?['avatar_url']?.toString() ??
                  proProfile?['avatar_url']?.toString() ??
                  proProfile?['logo_url']?.toString() ??
                  user['avatar_url']?.toString();

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
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(
                                  ApiConfig.resolveMediaUrl(avatarUrl) ??
                                      avatarUrl,
                                )
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: isReply ? 12 : 16,
                                  color: Colors.grey[600],
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

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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

  // ── Reaction helpers ──────────────────────────────────────────────

  String _reactionKey(String apiSlug, String entityId) => '$apiSlug:$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromResource(
    String apiSlug,
    String entityId,
    Map<String, dynamic> resource, {
    bool force = false,
  }) {
    final key = _reactionKey(apiSlug, entityId);
    if (!_reactions.containsKey(key) || force) {
      final apiReaction = resource['user_reaction']?.toString();
      // Prefer API value over cache - cache is for offline fallback only
      final userReaction =
          apiReaction ??
          (ReactionCacheService.isCached(apiSlug, entityId)
              ? ReactionCacheService.load(apiSlug, entityId)
              : null);
      final apiCount = _asInt(resource['likes_count']);
      final cachedCount = ReactionCacheService.loadCount(apiSlug, entityId);
      final apiCommentsCount = _asInt(resource['comments_count']);
      final cachedCommentsCount = ReactionCacheService.loadCommentsCount(
        apiSlug,
        entityId,
      );
      _reactions[key] = _ReactionData(
        likesCount: (cachedCount != null && cachedCount > apiCount)
            ? cachedCount
            : apiCount,
        commentsCount:
            (cachedCommentsCount != null &&
                cachedCommentsCount > apiCommentsCount)
            ? cachedCommentsCount
            : apiCommentsCount,
        userReaction: userReaction,
      );
    }
  }

  Future<void> _refreshReactionFromApi(String apiSlug, String entityId) async {
    try {
      final response = await ApiClient().authenticatedGet(
        '/$apiSlug/$entityId',
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          final key = _reactionKey(apiSlug, entityId);
          final apiLikesCount = _asInt(data['likes_count']);
          final apiCommentsCount = _asInt(data['comments_count']);
          final apiReaction = data['user_reaction']?.toString();
          final currentData = _getReaction(apiSlug, entityId);
          final preservedLikesCount = apiLikesCount > currentData.likesCount
              ? apiLikesCount
              : currentData.likesCount;
          final preservedCommentsCount =
              apiCommentsCount > currentData.commentsCount
              ? apiCommentsCount
              : currentData.commentsCount;
          final cachedReaction = ReactionCacheService.load(apiSlug, entityId);
          final preservedReaction =
              currentData.userReaction ?? cachedReaction ?? apiReaction;
          _reactions[key] = _ReactionData(
            likesCount: preservedLikesCount,
            commentsCount: preservedCommentsCount,
            userReaction: preservedReaction,
          );
          ReactionCacheService.saveCount(
            apiSlug,
            entityId,
            preservedLikesCount,
          );
          ReactionCacheService.saveCommentsCount(
            apiSlug,
            entityId,
            preservedCommentsCount,
          );
          ReactionCacheService.save(apiSlug, entityId, preservedReaction);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing reaction: $e');
    }
  }

  Widget _buildAuthorInfo(Map<String, dynamic> authorData) {
    // Extract profile data based on account type
    final accountType = authorData['account_type']?.toString();
    final proProfile = authorData['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        authorData['particulier_profile'] as Map<String, dynamic>?;

    // Get the appropriate profile
    final profile = accountType == 'pro' ? proProfile : particulierProfile;

    // Extract name from profile or fallback to direct fields
    final name =
        profile?['company_name']?.toString() ??
        profile?['pseudo']?.toString() ??
        '${profile?['first_name']?.toString() ?? ''} ${profile?['last_name']?.toString() ?? ''}'
            .trim();

    // Extract avatar from profile or fallback to direct fields
    final avatarUrl =
        profile?['avatar_url']?.toString() ?? profile?['avatar']?.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            image:
                avatarUrl != null &&
                    avatarUrl.isNotEmpty &&
                    (avatarUrl.startsWith("https") ||
                        avatarUrl.startsWith("http"))
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : (avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            "${ApiConfig.baseUrl.replaceAll("/api", "")}/storage/$avatarUrl",
                          ),
                          fit: BoxFit.cover,
                        )
                      : null),
          ),
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, size: 16, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isNotEmpty ? name : 'Utilisateur',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (accountType == 'pro')
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
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
        // Share icon
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => ShareService.shareEntity(apiSlug, entityId),
          child: Icon(Icons.share_outlined, size: 18, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
