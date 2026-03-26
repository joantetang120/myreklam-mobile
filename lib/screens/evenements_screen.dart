import 'package:flutter/material.dart';
import 'package:myreklam/screens/notifications_screen.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/evenement_card.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/config/api_config.dart';

class EvenementsScreen extends StatefulWidget {
  const EvenementsScreen({super.key});

  @override
  State<EvenementsScreen> createState() => _EvenementsScreenState();
}

class _EvenementsScreenState extends State<EvenementsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

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
        '/feed/latest?type=event&limit=20',
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
                      '145',
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

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? 'Évènement';
    final location =
        event['location']?.toString() ?? event['city']?.toString() ?? '';
    final eventDate =
        event['event_date']?.toString() ?? event['start_date']?.toString();
    final createdAt = event['created_at']?.toString();
    final price =
        event['price']?.toString() ?? event['ticket_price']?.toString();
    final category = event['category']?.toString() ?? '';
    final subCategory = event['sub_category']?.toString() ?? '';
    final mediaFiles = event['media'] as List? ?? [];
    final imageUrl = mediaFiles.isNotEmpty
        ? mediaFiles.first['url']?.toString()
        : null;
    final username =
        event['user']?['email']?.toString().split('@').first ?? 'Organisateur';

    final categories = <String>[
      if (category.isNotEmpty) category,
      if (subCategory.isNotEmpty) subCategory,
    ];

    return EvenementCard(
      profileImage: 'assets/images/dashboard_particulier/Ellipse 12.png',
      username: username,
      userType: 'Pro',
      eventTitle: title,
      eventImage:
          _buildStorageUrl(imageUrl) ??
          'assets/images/dashboard_particulier/Rectangle 12 (4).png',
      badge: 'A venir',
      categories: categories.isNotEmpty ? categories : ['Évènement'],
      eventDate: _formatEventDate(eventDate),
      location: location.isNotEmpty ? location : 'Lieu à confirmer',
      timeAgo: _buildTimeAgo(createdAt),
      price: price != null && price.isNotEmpty ? '${price}€' : 'Gratuit',
      likesCount: event['likes_count'] ?? 0,
      commentsCount: event['comments_count'] ?? 0,
      onTapCTA: () {},
    );
  }
}
