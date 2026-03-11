import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/avatars_story.dart';
import 'package:myreklam/widgets/categories_icon.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/screens/favorite_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';
import 'package:myreklam/screens/bons_plans_screen.dart';
import 'package:myreklam/screens/offres_emploi_screen.dart';
import 'package:myreklam/screens/formation_screen.dart';
import 'package:myreklam/screens/evenements_screen.dart';
import 'package:myreklam/screens/demandes_screen.dart';
import 'package:myreklam/screens/categories_screen.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/screens/add_story_screen.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/screens/my_stories_screen.dart';
import 'package:myreklam/services/story_store.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';

class ParticulierDashboardScreen extends StatefulWidget {
  const ParticulierDashboardScreen({super.key});

  @override
  State<ParticulierDashboardScreen> createState() =>
      _ParticulierDashboardScreenState();
}

class _PostAuthorInfo {
  const _PostAuthorInfo({
    required this.id,
    required this.displayName,
    required this.accountType,
    required this.avatar,
  });

  final String? id;
  final String displayName;
  final String accountType;
  final String avatar;
}

class _ReactionData {
  int likesCount;
  int dislikesCount;
  String? userReaction; // 'like', 'dislike', or null

  _ReactionData({
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userReaction,
  });
}

class _ParticulierDashboardScreenState
    extends State<ParticulierDashboardScreen> {
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A8143), Color(0xFF3AAE5E)],
  );

  final StoryStore _storyStore = StoryStore();
  final ScrollController _scrollController = ScrollController();
  static const _defaultAvatar = 'assets/images/dashboard_particulier/Ellipse 10.png';

  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  bool _feedHasMore = true;
  String? _feedError;
  int _feedPage = 1;
  final int _feedLimit = 20;
  final int _feedPerTypeLimit = 4;
  String? _currentUserId;

  // Reaction state per entity: key = "entityType:entityId"
  final Map<String, _ReactionData> _reactions = {};

  static const Map<String, String> _feedTypeToApiSlug = {
    'post': 'posts',
    'bon_plan': 'bon-plans',
    'job_offer': 'job-offers',
    'training': 'trainings',
    'event': 'events',
    'demande': 'demandes',
  };

  void _openStory(BuildContext context, String name, String avatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          name: name,
          avatar: avatar,
          stories: [
            {
              'image': 'assets/images/story/Rectangle 113.png',
              'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum. Excepteur sint occaecat cupidatat non',
              'time': 'Aujourd\'hui 10 : 30',
            },
            {
              'image': 'assets/images/story/Rectangle 113.png',
              'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.',
              'time': 'Aujourd\'hui 11 : 00',
            },
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onFeedScroll);
    _prefetchCurrentUser();
    _loadUnifiedFeed(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onFeedScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleStoryEntryTap() async {
    if (_storyStore.stories.isEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddStoryScreen(),
        ),
      );
      if (result is StoryModel) {
        _storyStore.addStory(result);
      }
    } else {
      final updatedStories = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyStoriesScreen(
            stories: _storyStore.stories,
            userName: 'Vous',
            userAvatar: 'assets/images/dashboard_particulier/Ellipse 10.png',
          ),
        ),
      );
      if (updatedStories is List<StoryModel>) {
        _storyStore.replaceStories(updatedStories);
      }
    }
  }

  void _prefetchCurrentUser() {
    _getCurrentUserId();
  }

  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserId != null) {
      return _currentUserId;
    }
    try {
      final response = await ApiClient().authenticatedGet('/user/profile');
      final data = response['data'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();
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

  Future<void> _loadUnifiedFeed({bool reset = false}) async {
    if (_isLoadingMoreFeed || (!_feedHasMore && !reset)) return;

    if (reset) {
      _feedPage = 1;
      _feedHasMore = true;
      setState(() {
        _isLoadingFeed = true;
        _feedError = null;
      });
    } else {
      setState(() {
        _isLoadingMoreFeed = true;
        _feedError = null;
      });
    }

    try {
      final params =
          '?page=$_feedPage&limit=$_feedLimit&per_type_limit=$_feedPerTypeLimit';
      final response = await ApiClient().get('/feed/latest$params');
      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is Map<String, dynamic> && data['items'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['items'] as List);
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _feedItems = fetched;
          } else {
            _feedItems.addAll(fetched);
          }
          _feedHasMore = fetched.length >= _feedLimit;
          if (_feedHasMore) {
            _feedPage += 1;
          }
          if (fetched.isEmpty) {
            _feedHasMore = false;
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _feedError = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _feedError = 'Impossible de charger le flux.');
      }
    } finally {
      if (mounted) {
        setState(() {
          if (reset) {
            _isLoadingFeed = false;
          } else {
            _isLoadingMoreFeed = false;
          }
        });
      }
    }
  }

  void _onFeedScroll() {
    if (!_scrollController.hasClients || _isLoadingMoreFeed || !_feedHasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels + 200 >= position.maxScrollExtent) {
      _loadUnifiedFeed();
    }
  }

  Widget _buildFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Fil d'actualités"),
        const SizedBox(height: 12),
        if (_isLoadingFeed)
          _buildStatusPlaceholder(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_feedError != null)
          _buildStatusPlaceholder(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildErrorState(
                _feedError!,
                onRetry: () => _loadUnifiedFeed(reset: true),
              ),
            ),
          )
        else ...[
          Builder(
            builder: (_) {
              final items =
                  _feedItems.where((item) => item['feed_type'] != 'post').toList();
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEmptyState('Aucun contenu disponible pour le moment.'),
                );
              }
              return Column(children: items.map(_buildFeedItemCard).toList());
            },
          ),
          if (_isLoadingMoreFeed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ],
    );
  }

  Widget _buildFeedItemCard(Map<String, dynamic> item) {
    final feedType = item['feed_type']?.toString() ?? '';
    final resource = item['resource'];
    if (resource is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final apiSlug = _feedTypeToApiSlug[feedType];
    final entityId = resource['id']?.toString() ?? '';
    if (apiSlug != null && entityId.isNotEmpty) {
      _seedReactionFromFeed(apiSlug, entityId, resource);
    }

    switch (feedType) {
      case 'post':
        return _buildPostCard(resource);
      case 'bon_plan':
        return _buildBonPlanFeedCard(resource);
      case 'job_offer':
        return _buildJobOfferFeedCard(resource);
      case 'training':
        return _buildTrainingFeedCard(resource);
      case 'event':
        return _buildEventFeedCard(resource);
      case 'demande':
        return _buildDemandeFeedCard(resource);
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildUnknownFeedCard(feedType),
        );
    }
  }

  Widget _buildBonPlanFeedCard(Map<String, dynamic> bp) {
    final bpId = bp['id']?.toString() ?? '';
    final title = bp['title']?.toString() ?? '';
    final category = bp['category']?.toString() ?? '';
    final subCategory = bp['sub_category']?.toString() ?? '';
    final type = bp['type']?.toString() ?? '';
    final merchantName = bp['available_at_name']?.toString() ?? '';
    final locationType = bp['available_location_type']?.toString() ?? '';
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
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Description
          _buildBonPlanDescription(bp),
          // Image
          if (imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _buildStorageUrl(imageUrl) ?? '',
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
              if (category.isNotEmpty) _buildBonPlanTag(category, Icons.local_offer_outlined),
              if (subCategory.isNotEmpty) _buildBonPlanTag(subCategory, Icons.subdirectory_arrow_right),
              if (type.isNotEmpty) _buildBonPlanTag(type, Icons.label_outline),
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
                  _buildTimeAgo(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (bpId.isNotEmpty) _buildReactionBar('bon-plans', bpId),
          const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Widget _buildJobOfferFeedCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final companyName = job['company_name']?.toString() ?? 'Entreprise';
    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location = job['location']?.toString() ??
        job['city']?.toString() ??
        'Non spécifié';
    final contract = job['contract_type']?.toString() ?? '';
    final experience = job['experience_level']?.toString() ?? '';
    final salary = job['salary_label']?.toString() ?? job['salary']?.toString();

    final tags = <JobDetailTag>[
      if (contract.isNotEmpty)
        JobDetailTag(
          icon: Icons.description_outlined,
          text: contract,
        ),
      if (location.isNotEmpty)
        JobDetailTag(
          icon: Icons.location_on_outlined,
          text: location,
        ),
      if (experience.isNotEmpty)
        JobDetailTag(
          icon: Icons.work_history_outlined,
          text: experience,
        ),
      if (salary != null && salary.isNotEmpty)
        JobDetailTag(
          icon: Icons.euro,
          text: salary,
          isSpecial: true,
        ),
    ];

    final advantages = <String>[];
    if (job['advantages'] is List) {
      advantages.addAll(
        (job['advantages'] as List)
            .whereType<String>()
            .where((element) => element.isNotEmpty),
      );
    }
    if (advantages.isEmpty) {
      advantages.add('Avantages non précisés');
    }

    return Column(
      children: [
        JobAnnouncementCard(
          companyLogo: 'assets/images/dashboard_particulier/Rectangle 13.png',
          companyName: companyName,
          jobTitle: jobTitle,
          description:
              description.isNotEmpty ? description : 'Description non disponible.',
          tags: tags,
          advantages: advantages,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          onApply: () => _navigateToJobDetail(job),
        ),
        if (jobId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: _buildReactionBar('job-offers', jobId),
          ),
      ],
    );
  }

  Widget _buildTrainingFeedCard(Map<String, dynamic> training) {
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

    final tags = <FormationTag>[
      if (category.isNotEmpty)
        FormationTag(icon: Icons.category_outlined, text: category),
      if (subCategory.isNotEmpty)
        FormationTag(icon: Icons.subdirectory_arrow_right, text: subCategory),
      if (trainingType.isNotEmpty)
        FormationTag(icon: Icons.school_outlined, text: trainingType),
      if (duration != null)
        FormationTag(
          icon: Icons.timer_outlined,
          text: '$duration h${durationUnit != null ? ' / $durationUnit' : ''}',
        ),
      if (price != null)
        FormationTag(
          icon: Icons.euro,
          text: '$price €',
          isSpecial: true,
        ),
    ];

    return Column(
      children: [
        FormationCard(
          companyLogo: 'assets/images/Formation.png',
          companyName: provider,
          formationTitle: title,
          description:
              description.isNotEmpty ? description : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(training['created_at']?.toString()),
          onApply: () => _navigateToTrainingDetail(training),
        ),
        if (trainingId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: _buildReactionBar('trainings', trainingId),
          ),
      ],
    );
  }

  Widget _buildEventFeedCard(Map<String, dynamic> event) {
    final user = event['user'] as Map<String, dynamic>?;
    final profileImage =
        _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
    final username = user?['name']?.toString() ?? 'Organisateur';
    final eventTitle = event['title']?.toString() ?? 'Évènement';
    final eventImage =
        _extractMediaUrl(event) ?? 'assets/images/default_event.png';
    final categories = <String>[
      if (event['category_label']?.toString().isNotEmpty ?? false)
        event['category_label'].toString(),
      if (event['sub_category_label']?.toString().isNotEmpty ?? false)
        event['sub_category_label'].toString(),
    ];
    final price = _formatPrice(event['price_amount'] ?? event['price_label']);
    final coverageArea = event['coverage_area']?.toString() ??
        event['location']?.toString() ??
        'Non spécifié';

    final eventId = event['id']?.toString() ?? '';

    return Column(
      children: [
        EvenementCard(
          profileImage: profileImage,
          username: username,
          userType: 'Évènement',
          eventTitle: eventTitle,
          eventImage: eventImage,
          badge: event['status']?.toString(),
          categories: categories.isNotEmpty ? categories : ['Général'],
          eventDate: _formatEventDate(event),
          location: coverageArea,
          timeAgo: _buildTimeAgo(event['created_at']?.toString()),
          price: price,
          likesCount: _asInt(event['likes_count']),
          commentsCount: _asInt(event['comments_count']),
          onTapCTA: () => _navigateToEventDetail(event),
        ),
        if (eventId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: _buildReactionBar('events', eventId),
          ),
      ],
    );
  }

  Widget _buildDemandeFeedCard(Map<String, dynamic> demande) {
    final user = demande['user'] as Map<String, dynamic>?;
    final profileImage =
        _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
    final username = user?['name']?.toString() ?? 'Utilisateur';
    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');
    final categoryLabel = demande['category_label']?.toString() ??
        demande['category']?.toString() ??
        'Demande';
    final location = demande['location_label']?.toString() ??
        demande['city']?.toString() ??
        'Non spécifié';
    final postImage = _extractMediaUrl(demande);

    final demandeId = demande['id']?.toString() ?? '';

    return Column(
      children: [
        DemandeCard(
          profileImage: profileImage,
          username: username,
          categoryLabel: categoryLabel,
          categoryColor: _categoryColor(categoryLabel),
          title: title,
          description:
              description.isNotEmpty ? description : 'Description non disponible.',
          location: location,
          postImage: postImage,
          likesCount: _asInt(demande['likes_count']),
          commentsCount: _asInt(demande['comments_count']),
          timeAgo: _buildTimeAgo(demande['created_at']?.toString()),
          onTapCTA: () => _navigateToDemandeDetail(demande),
        ),
        if (demandeId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: _buildReactionBar('demandes', demandeId),
          ),
      ],
    );
  }

  Widget _buildUnknownFeedCard(String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Text('Type de contenu "$type" non supporté'),
    );
  }

  String _formatPrice(dynamic value) {
    if (value == null) return 'Gratuit';
    final text = value.toString();
    if (text.isEmpty) return 'Gratuit';
    if (text.contains('€')) return text;
    return '$text €';
  }

  String _formatEventDate(Map<String, dynamic> event) {
    final durationType = event['duration_type']?.toString();
    final eventDate = event['event_date']?.toString();
    final startDate = event['start_date']?.toString();

    String formatDate(String? iso) {
      if (iso == null) return '';
      try {
        final date = DateTime.parse(iso);
        return '${date.day}/${date.month}/${date.year}';
      } catch (_) {
        return iso;
      }
    }

    if (durationType == 'permanent') return 'Permanent';
    if (durationType == 'multi_day') {
      final formatted = formatDate(startDate);
      return formatted.isNotEmpty ? 'À partir du $formatted' : 'À partir de bientôt';
    }
    final formatted = formatDate(eventDate);
    return formatted.isNotEmpty ? formatted : 'Date annoncée prochainement';
  }

  Color _categoryColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('urgent')) return Colors.redAccent;
    if (lower.contains('emploi')) return const Color(0xFF3AAE5E);
    if (lower.contains('service')) return const Color(0xFFFF9800);
    return const Color(0xFF3AAE5E);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _stripHtml(String text) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return text.replaceAll(exp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return _buildStorageUrl(url);
        }
      }
    }
    final cover = resource['cover_url']?.toString();
    if (cover != null && cover.isNotEmpty) {
      return _buildStorageUrl(cover);
    }
    return null;
  }

  Widget _buildStatusPlaceholder(Widget child) {
    return child;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {VoidCallback? onRetry}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Text(
      message,
      style: const TextStyle(color: Color(0xFF9E9E9E)),
    );
  }

  // ── Reaction helpers ──────────────────────────────────────────────

  String _reactionKey(String apiSlug, String entityId) => '$apiSlug:$entityId';

  _ReactionData _getReaction(String apiSlug, String entityId) {
    final key = _reactionKey(apiSlug, entityId);
    return _reactions.putIfAbsent(key, () => _ReactionData());
  }

  void _seedReactionFromFeed(String apiSlug, String entityId, Map<String, dynamic> resource) {
    final key = _reactionKey(apiSlug, entityId);
    if (_reactions.containsKey(key)) return;
    _reactions[key] = _ReactionData(
      likesCount: _asInt(resource['likes_count']),
      dislikesCount: _asInt(resource['dislikes_count']),
      userReaction: resource['user_reaction']?.toString(),
    );
  }

  Future<void> _toggleReaction(String apiSlug, String entityId, String type) async {
    final data = _getReaction(apiSlug, entityId);

    // Optimistic update
    final oldReaction = data.userReaction;
    final oldLikes = data.likesCount;
    final oldDislikes = data.dislikesCount;

    setState(() {
      if (oldReaction == type) {
        data.userReaction = null;
        if (type == 'like') data.likesCount--;
        if (type == 'dislike') data.dislikesCount--;
      } else {
        if (oldReaction == 'like') data.likesCount--;
        if (oldReaction == 'dislike') data.dislikesCount--;
        data.userReaction = type;
        if (type == 'like') data.likesCount++;
        if (type == 'dislike') data.dislikesCount++;
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
          data.dislikesCount = _asInt(respData['dislikes_count']);
          data.userReaction = respData['user_reaction']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
      if (mounted) {
        setState(() {
          data.likesCount = oldLikes;
          data.dislikesCount = oldDislikes;
          data.userReaction = oldReaction;
        });
      }
    }
  }

  Widget _buildReactionBar(String apiSlug, String entityId) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isDisliked = data.userReaction == 'dislike';

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
        // Dislike
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'dislike'),
          child: Row(
            children: [
              Icon(
                isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                size: 18,
                color: isDisliked ? Colors.redAccent : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.dislikesCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDisliked ? Colors.redAccent : Colors.grey[600],
                  fontWeight: isDisliked ? FontWeight.w600 : FontWeight.normal,
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
              Icon(Icons.chat_bubble_outline, size: 17, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Commenter',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
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
                  fetched = List<Map<String, dynamic>>.from(data['data'] as List);
                } else if (data is List) {
                  fetched = List<Map<String, dynamic>>.from(data);
                }
                modalSetState(() {
                  comments = fetched;
                  isLoading = false;
                });
              }).catchError((e) {
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
                }
                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
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
                    comment['dislikes_count'] = respData['dislikes_count'];
                    comment['user_reaction'] = respData['user_reaction'];
                  });
                }
              } catch (e) {
                debugPrint('Comment reaction error: $e');
              }
            }

            Widget buildCommentItem(Map<String, dynamic> comment, {bool isReply = false}) {
              final user = comment['user'] as Map<String, dynamic>? ?? {};
              final userId = user['id']?.toString();
              final email = user['email']?.toString() ?? '';
              final displayName = (userId != null && userId == _currentUserId)
                  ? 'Vous'
                  : (user['display_name']?.toString() ??
                      user['name']?.toString() ??
                      email.split('@').first);
              final body = comment['body']?.toString() ?? '';
              final createdAt = comment['created_at']?.toString();
              final likes = _asInt(comment['likes_count']);
              final dislikes = _asInt(comment['dislikes_count']);
              final userReaction = comment['user_reaction']?.toString();
              final replies = (comment['replies'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [];

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
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: isReply ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A8143),
                            ),
                          ),
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
                                    onTap: () => toggleCommentReaction(comment, 'like'),
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
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    onTap: () => toggleCommentReaction(comment, 'dislike'),
                                    child: Row(
                                      children: [
                                        Icon(
                                          userReaction == 'dislike'
                                              ? Icons.thumb_down_alt
                                              : Icons.thumb_down_alt_outlined,
                                          size: 14,
                                          color: userReaction == 'dislike'
                                              ? Colors.redAccent
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$dislikes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: userReaction == 'dislike'
                                                ? Colors.redAccent
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
                                        FocusScope.of(ctx).requestFocus(FocusNode());
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
                      ...replies.map((r) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: buildCommentItem(r, isReply: true),
                          )),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            child: const Icon(Icons.close, color: Colors.grey, size: 22),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            Text(
                              'Répondre à $replyingToName',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  border: InputBorder.none,
                                  hintText: 'Écrire un commentaire...',
                                  hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
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
                              child: const Icon(Icons.send, size: 18, color: Colors.white),
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

  Widget _buildPostsCarousel() {
    final posts = _feedItems
        .where((item) => item['feed_type'] == 'post' && item['resource'] is Map<String, dynamic>)
        .map((item) => item['resource'] as Map<String, dynamic>)
        .toList();

    if (posts.isEmpty || _isLoadingFeed) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Publications'),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final raw = posts[index];
              final postId = raw['id']?.toString() ?? '';
              _seedReactionFromFeed('posts', postId, raw);
              final author = _extractPostAuthorInfo(raw);
              final content = raw['content']?.toString() ?? '';
              final createdAt = raw['created_at']?.toString();
              final timeAgo = _buildTimeAgo(createdAt);
              final postImageUrl = _extractMediaUrl(raw);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: author.avatar.startsWith('http')
                              ? NetworkImage(author.avatar) as ImageProvider
                              : AssetImage(author.avatar),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                author.accountType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text(
                              timeAgo,
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (postImageUrl != null && postImageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          postImageUrl,
                          width: double.infinity,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: Text(
                        content.isNotEmpty ? content : 'Post sans contenu',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                          height: 1.4,
                        ),
                        maxLines: postImageUrl != null ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (postId.isNotEmpty)
                      _buildReactionBar('posts', postId),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> raw) {
    final postId = raw['id']?.toString() ?? '';
    final author = _extractPostAuthorInfo(raw);
    final content = raw['content']?.toString() ?? '';
    final createdAt = raw['created_at']?.toString();
    final timeAgo = _buildTimeAgo(createdAt);
    final postImageUrl = _extractMediaUrl(raw);

    final tags = <PostTag>[
      PostTag(
        title: author.accountType,
        icon: author.accountType == 'Professionnel' ? Icons.business : Icons.person,
        color: author.accountType == 'Professionnel'
            ? const Color(0xFF2E9B5B)
            : const Color(0xFF3AAE5E),
      ),
    ];

    return Column(
      children: [
        PostContentCard(
          tags: tags,
          title: content.isNotEmpty
              ? content
              : '${author.displayName} a partagé une publication',
          time: timeAgo,
          imageUrl: postImageUrl,
          onLike: postId.isNotEmpty
              ? () => _toggleReaction('posts', postId, 'like')
              : null,
          onShare: () {},
        ),
        if (postId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: _buildReactionBar('posts', postId),
          ),
      ],
    );
  }

  _PostAuthorInfo _extractPostAuthorInfo(Map<String, dynamic> raw) {
    final authorMap = (raw['author'] ?? raw['user']) as Map<String, dynamic>?;
    final authorId = authorMap?['id']?.toString() ?? raw['author_id']?.toString() ?? raw['user_id']?.toString();

    final nameCandidates = [
      authorMap?['display_name'],
      raw['display_name'],
      raw['author_display_name'],
      authorMap?['pseudo'],
      authorMap?['nomsociete'],
      _joinNames(authorMap?['first_name'], authorMap?['last_name']),
      authorMap?['name'],
      raw['author_name'],
      raw['authorName'],
    ];

    String resolvedName = 'Utilisateur';
    for (final candidate in nameCandidates) {
      if (candidate == null) continue;
      final value = candidate.toString().trim();
      if (value.isNotEmpty) {
        resolvedName = value;
        break;
      }
    }

    if (_currentUserId != null && authorId != null && authorId == _currentUserId) {
      resolvedName = 'Vous';
    }

    final rawType = (authorMap?['account_type'] ?? authorMap?['profiletype'] ?? raw['author_account_type'])
            ?.toString()
            .toLowerCase() ??
        '';
    final accountType = rawType.contains('pro') || rawType.contains('professionnel')
        ? 'Professionnel'
        : 'Particulier';

    final avatarCandidates = [
      authorMap?['avatar_url'],
      authorMap?['avatar'],
      authorMap?['photo'],
      authorMap?['photoprofilurl'],
      raw['author_avatar'],
      raw['authorAvatar'],
    ];
    String avatar = _defaultAvatar;
    for (final candidate in avatarCandidates) {
      if (candidate == null) continue;
      final resolved = _buildStorageUrl(candidate.toString());
      if (resolved != null && resolved.isNotEmpty) {
        avatar = resolved;
        break;
      }
    }

    return _PostAuthorInfo(
      id: authorId,
      displayName: resolvedName,
      accountType: accountType,
      avatar: avatar,
    );
  }

  String? _joinNames(dynamic first, dynamic last) {
    final firstName = first?.toString().trim();
    final lastName = last?.toString().trim();
    if ((firstName == null || firstName.isEmpty) && (lastName == null || lastName.isEmpty)) {
      return null;
    }
    if (firstName != null && firstName.isNotEmpty && lastName != null && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName?.isNotEmpty == true ? firstName : lastName;
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
      final profileImage = _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
      final username = user?['name']?.toString() ?? 'Utilisateur';
      final userType = user?['account_type']?.toString() ?? 'Particulier';
      final title = data['title']?.toString() ?? 'Bon plan';
      
      // Check if current user is the owner by comparing user_id from feed data
      final bonPlanUserId = bp['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner = bonPlanUserId != null && currentUserId != null && bonPlanUserId == currentUserId;
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
            time: _buildTimeAgo(data['created_at']?.toString()),
            availability: availableAt,
            validityType: validityType,
            validFrom: validFrom,
            validUntil: validUntil,
            deliveryInfo: deliveryInfo,
            location: location,
            link: link,
            isOwner: isOwner,
            bonPlanId: bonPlanId,
            bonPlanData: data,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
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

  Future<void> _navigateToJobDetail(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette offre d\'emploi')),
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
      debugPrint('JOB DETAIL description type: ${data['description']?.runtimeType}');
      debugPrint('JOB DETAIL description value: ${data['description']}');
      debugPrint('JOB DETAIL description_delta: ${data['description_delta']}');
      // Check all keys that contain 'desc'
      data.forEach((key, value) {
        if (key.toLowerCase().contains('desc') || key.toLowerCase().contains('delta')) {
          debugPrint('JOB DETAIL key=$key type=${value?.runtimeType} value=$value');
        }
      });

      // Extract job offer details
      final title = data['title']?.toString() ?? '';
      final descriptionRaw = data['description'];
      final description = descriptionRaw?.toString() ?? '';
      final descriptionDelta = data['description_delta'] ?? (descriptionRaw is List ? descriptionRaw : null);
      final profileDescription = data['profile_description']?.toString();
      final companyName = data['company_name']?.toString() ?? 'Entreprise';
      final companyWebsite = data['company_website']?.toString() ?? '';
      final contractTypeRaw = data['contract_type'];
      final contractType = contractTypeRaw is Map ? (contractTypeRaw['name'] ?? contractTypeRaw.toString()) : (contractTypeRaw?.toString() ?? '');
      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map ? (workTimeRaw['name'] ?? workTimeRaw.toString()) : (workTimeRaw?.toString() ?? '');
      final locationRaw = data['location'];
      final location = locationRaw is Map ? (locationRaw['city'] ?? locationRaw['name'] ?? locationRaw.toString()) : (locationRaw?.toString() ?? '');
      final categoryRaw = data['category'];
      final category = categoryRaw is Map ? (categoryRaw['name'] ?? categoryRaw.toString()) : (categoryRaw?.toString() ?? '');
      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final advantagesRaw = data['advantages'];
      final advantages = advantagesRaw is List
          ? advantagesRaw.map((a) => a is Map ? (a['name'] ?? a.toString()) : a.toString()).toList()
          : <String>[];
      final createdAt = data['created_at']?.toString();
      final mediaRaw = data['media'] as List? ?? data['media_files'] as List? ?? [];
      final remoteWork = data['remote_work'] == true;
      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map ? (educationLevelRaw['name'] ?? educationLevelRaw.toString()) : educationLevelRaw?.toString();
      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString()) : experienceLevelRaw?.toString();

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
          JobDetailTag(icon: Icons.access_time, text: workTime),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatJobSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      // Build advantages list
      final advantagesList = advantages.take(3).map((a) => a.toString()).toList();

      // Check ownership
      final jobUserId = job['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner = jobUserId != null && currentUserId != null && jobUserId == currentUserId;

      // Navigate to detail screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo: 'assets/images/dashboard_particulier/Rectangle 13.png',
            companyName: companyName,
            companyWebsite: companyWebsite,
            jobTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            profileDescription: profileDescription,
            tags: tags,
            advantages: advantagesList,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            location: location,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobId,
            jobOfferData: data,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
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
      final response = await ApiClient().authenticatedGet('/trainings/$trainingId');
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final description = _stripHtml(data['description']?.toString() ?? '');
      final descriptionDelta = data['description_delta'];
      final companyName = data['company_name']?.toString() ?? data['provider_name']?.toString() ?? 'Organisme';
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
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
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

      // Check ownership
      final trainingUserId = tr['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner = trainingUserId != null && currentUserId != null && trainingUserId == currentUserId;

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
            isOwner: isOwner,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching training detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
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

      final user = ev['user'] as Map<String, dynamic>?;
      final profileImage = _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
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
      final priceAmount = data['price_amount']?.toString();
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
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
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

      // Check ownership
      final eventUserId = ev['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner = eventUserId != null && currentUserId != null && eventUserId == currentUserId;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(
            images: images,
            avatar: profileImage,
            username: isOrganizer ? userName : (organizerName ?? 'Organisateur'),
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
            priceAmount: priceAmount,
            reservationMode: reservationMode,
            coverageArea: coverageArea,
            isNationwide: isNationwide,
            organizerName: organizerName,
            isOrganizer: isOrganizer,
            websiteUrl: websiteUrl,
            landingUrl: landingUrl,
            acceptMessages: acceptMessages,
            isOwner: isOwner,
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching event detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> demande) async {
    final demandeId = demande['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette demande')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/demandes/$demandeId');
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final user = demande['user'] as Map<String, dynamic>?;
      final profileImage = _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
      final userName = user?['name']?.toString() ?? 'Utilisateur';

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
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
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

      // Check ownership
      final demandeUserId = demande['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner = demandeUserId != null && currentUserId != null && demandeUserId == currentUserId;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: profileImage,
            username: userName,
            userType: categoryLabel,
            demandeTitle: title,
            description: description,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
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
          ),
        ),
      );
      if (result == 'deleted' && mounted) _loadUnifiedFeed(reset: true);
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  String _formatJobSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Non spécifié';
  }

  List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null || mediaFiles.isEmpty) {
      return ['assets/images/details_bon_plans/Rectangle 35.png'];
    }
    final images = mediaFiles
        .where((m) => m is Map && m['url'] != null)
        .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    
    // Ensure we always have at least one image
    if (images.isEmpty) {
      return ['assets/images/details_bon_plans/Rectangle 35.png'];
    }
    return images;
  }

  Widget _buildBonPlanDescription(Map<String, dynamic> item) {
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
      _stripHtml(descriptionPlain.toString()),
      style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBonPlanTag(String text, IconData icon) {
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

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) {
      return url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
    }
    return '$serverBase$url';
  }

  Future<void> _refreshFeed() {
    return _loadUnifiedFeed(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
  expandedHeight: 100,
  floating: false,
  pinned: true,
  snap: false,
  stretch: true,
  backgroundColor: const Color(0xFF2A8143),
  automaticallyImplyLeading: false,
  elevation: 0,
  collapsedHeight: kToolbarHeight,
  flexibleSpace: LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double appBarHeight = constraints.maxHeight;
      final double opacity = (appBarHeight - kToolbarHeight) / (100 - kToolbarHeight);
      final double clampedOpacity = opacity.clamp(0.0, 1.0);
      final double titleOpacity = 1 - clampedOpacity;
      final double dynamicRadius = 40 * clampedOpacity;
      final bool showExpandedElements = clampedOpacity > 0.01;
      final bool showCollapsedElements = titleOpacity > 0.01;
      
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: greenGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(dynamicRadius),
                bottomRight: Radius.circular(dynamicRadius),
              ),
            ),
          ),
          if (showExpandedElements)
            Positioned(
              bottom: 20,
              left: 20,
              child: Opacity(
                opacity: clampedOpacity,
                child: Image.asset(
                  'assets/images/LOGO VERT.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          if (showExpandedElements)
            Positioned(
              bottom: 20,
              right: 20,
              child: Opacity(
                opacity: clampedOpacity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF8FDF0).withOpacity(0.3),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF8FDF0).withOpacity(0.3),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                '10',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
            ),
          if (showCollapsedElements)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: titleOpacity,
                child: Container(
                  height: kToolbarHeight,
                  decoration: const BoxDecoration(
                    gradient: greenGradient,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
    ),
  ),
),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),

                //story
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ValueListenableBuilder<List<StoryModel>>(
                    valueListenable: _storyStore.storiesNotifier,
                    builder: (_, userStories, __) {
                      final hasStories = userStories.isNotEmpty;
                      return SingleChildScrollView(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _handleStoryEntryTap,
                              child: Column(
                                spacing: 5,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      GestureDetector(
                                        onTap: _handleStoryEntryTap,
                                        child: Container(
                                          padding: EdgeInsets.all(hasStories ? 2 : 10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFE6F7EF),
                                            border: Border.all(
                                              color: const Color(0xFF3AAE5E),
                                              width: hasStories ? 2.5 : 1,
                                            ),
                                          ),
                                          child: hasStories
                                              ? const CircleAvatar(
                                                  radius: 22,
                                                  backgroundImage: AssetImage(
                                                    'assets/images/dashboard_particulier/Ellipse 10.png',
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    color: Color(0xFF3AAE5E),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (hasStories)
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const AddStoryScreen(),
                                                ),
                                              );
                                              if (result is StoryModel) {
                                                _storyStore.addStory(result);
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3AAE5E),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Text(
                                    "Votre story",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),

                            // avatars
                            AvatarsStory(
                              name: "Selena",
                              imageName:
                                  'assets/images/dashboard_particulier/Ellipse 10.png',
                              onTap: () => _openStory(
                                context,
                                'Selena',
                                'assets/images/dashboard_particulier/Ellipse 10.png',
                              ),
                            ),
                            AvatarsStory(
                              name: "Slime",
                              imageName:
                                  'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                              onTap: () => _openStory(
                                context,
                                'Slime',
                                'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                              ),
                            ),
                            AvatarsStory(
                              name: "Joe",
                              imageName:
                                  'assets/images/dashboard_particulier/Ellipse 10 (2).png',
                              onTap: () => _openStory(
                                context,
                                'Joe',
                                'assets/images/dashboard_particulier/Ellipse 10 (2).png',
                              ),
                            ),
                            AvatarsStory(
                              name: "Joe",
                              imageName:
                                  'assets/images/dashboard_particulier/Ellipse 10 (3).png',
                              onTap: () => _openStory(
                                context,
                                'Joe',
                                'assets/images/dashboard_particulier/Ellipse 10 (3).png',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ), // space on sides
                  child: Container(
                    height: 1, // thin line
                    color: Colors.grey[300], // light gray
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Catégories"),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoriesScreen(),
                            ),
                          );
                        },
                        child: const Text("voir tout"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        CategoriesIcon(
                          title: "Bons plans",
                          iconColor: const Color.fromARGB(255, 252, 116, 37),
                          bgColor: Color(0xFFFFE0B2).withOpacity(0.2),
                          icon: Icons.card_giftcard_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BonsPlansScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Offre d'emploi",
                          iconColor: Colors.lightBlueAccent,
                          bgColor: Color(0xFFB3E5FC).withOpacity(0.2),
                          iconAsset: 'assets/images/offres.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OffresEmploiScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Formations",
                          iconColor: Colors.purple,
                          bgColor: Color(0xFFE1BEE7).withOpacity(0.1),
                          iconAsset: 'assets/images/Formation.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FormationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Evenements",
                          iconColor: Colors.green,
                          bgColor: Color(0xFFE6F7EF).withOpacity(0.5),
                          icon: Icons.event_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EvenementsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        CategoriesIcon(
                          title: "Demandes",
                          iconColor: const Color.fromARGB(255, 252, 231, 49),
                          bgColor: Color.fromARGB(255, 255, 250, 178).withOpacity(0.2),
                          icon: Icons.chat_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DemandesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildPostsCarousel(),

                _buildFeedSection(),

              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
