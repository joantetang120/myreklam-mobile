import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/notifications_screen.dart';
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

class _OffresEmploiScreenState extends State<OffresEmploiScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _ensureCurrentUserId();
    _loadData();
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title']?.toString() ?? "Offre d'emploi";

    var description = _stripHtml(job['description']?.toString() ?? '');
    if (description.length > 150) {
      description = '${description.substring(0, 150)}...';
    }

    final createdAt = job['created_at']?.toString();

    final contractTypeRaw = job['contract_type'];
    final contractType = contractTypeRaw is Map
        ? (contractTypeRaw['name'] ?? contractTypeRaw.toString()).toString()
        : (contractTypeRaw?.toString() ?? '');

    final workTimeRaw = job['work_time'];
    final workTime = workTimeRaw is Map
        ? (workTimeRaw['name'] ?? workTimeRaw.toString()).toString()
        : (workTimeRaw?.toString() ?? '');

    final locationRaw = job['location'] ?? job['city'];
    final location = locationRaw is Map
        ? (locationRaw['city'] ?? locationRaw['name'] ?? locationRaw.toString())
              .toString()
        : (locationRaw?.toString() ?? 'Non spécifié');

    final categoryRaw = job['category'];
    final category = categoryRaw is Map
        ? (categoryRaw['name'] ?? categoryRaw.toString()).toString()
        : (categoryRaw?.toString() ?? '');

    final educationLevelRaw = job['education_level'];
    final educationLevel = educationLevelRaw is Map
        ? (educationLevelRaw['name'] ?? educationLevelRaw.toString()).toString()
        : educationLevelRaw?.toString();

    final experienceLevelRaw = job['experience_level'];
    final experienceLevel = experienceLevelRaw is Map
        ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
              .toString()
        : experienceLevelRaw?.toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    final advantagesRaw = job['advantages'];
    final advantages = advantagesRaw is List
        ? advantagesRaw
              .map((a) => a is Map ? (a['name'] ?? a.toString()) : a.toString())
              .toList()
        : <String>[];
    final advantagesList = advantages.take(3).map((a) => a.toString()).toList();

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

    final user = job['user'] is Map<String, dynamic>
        ? job['user'] as Map<String, dynamic>
        : null;

    String cardCompanyName =
        (job['company_name']?.toString().trim().isNotEmpty ?? false)
        ? job['company_name']!.toString()
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

    final resolvedLogo = _buildStorageUrl(cardCompanyLogo) ?? cardCompanyLogo;

    return JobAnnouncementCard(
      companyLogo: resolvedLogo,
      companyName: cardCompanyName,
      jobTitle: title,
      description: description,
      tags: tags,
      advantages: advantagesList.isNotEmpty ? advantagesList : ['Non spécifié'],
      timeAgo: _buildTimeAgo(createdAt),
      onApply: () => _navigateToJobOfferDetail(job),
    );
  }

  Future<void> _navigateToJobOfferDetail(Map<String, dynamic> jo) async {
    final jobId = jo['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir cette offre")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
          ? (contractTypeRaw['name'] ?? contractTypeRaw.toString()).toString()
          : (contractTypeRaw?.toString() ?? '');

      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map
          ? (workTimeRaw['name'] ?? workTimeRaw.toString()).toString()
          : (workTimeRaw?.toString() ?? '');

      final locationRaw = data['location'];
      final location = locationRaw is Map
          ? (locationRaw['city'] ??
                    locationRaw['name'] ??
                    locationRaw.toString())
                .toString()
          : (locationRaw?.toString() ?? '');

      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString()).toString()
          : (categoryRaw?.toString() ?? '');

      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final remoteWork = data['remote_work'] == true;

      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
                .toString()
          : educationLevelRaw?.toString();

      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
                .toString()
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
          .map((m) => _buildStorageUrl(m['url']?.toString() ?? '') ?? '')
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

      String avatar = '';
      if (authorData != null) {
        avatar =
            (authorData['avatar_url'] ??
                    (authorData['pro_profile'] is Map
                        ? ((authorData['pro_profile'] as Map)['avatar_url'] ??
                              (authorData['pro_profile'] as Map)['logo_url'])
                        : null) ??
                    (authorData['particulier_profile'] is Map
                        ? (authorData['particulier_profile']
                              as Map)['avatar_url']
                        : null))
                ?.toString() ??
            '';
      }
      final resolvedAvatar = _buildStorageUrl(avatar) ?? avatar;

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo: resolvedAvatar.isNotEmpty
                ? resolvedAvatar
                : 'assets/images/dashboard_particulier/Rectangle 13.png',
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
            timeAgo: _buildTimeAgo(createdAt),
            location: location,
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
}
