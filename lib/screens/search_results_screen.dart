import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/search_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? category;
  final String location;
  final double radius;
  final bool allFrance;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.category,
    required this.location,
    this.radius = 0,
    this.allFrance = false,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String _selectedTab = 'annonces';
  bool _isLoading = true;
  List<Map<String, dynamic>> _annonceResults = [];
  List<Map<String, dynamic>> _userResults = [];
  int _annoncesTotal = 0;
  int _usersTotal = 0;
  String? _error;
  final TextEditingController _inlineSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inlineSearchController.text = widget.query;
    _fetchResults();
  }

  @override
  void dispose() {
    _inlineSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both annonces and users in parallel
      await Future.wait([
        _fetchAnnonces(),
        _fetchUsers(),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _fetchAnnonces() async {
    final queryParams = <String, String>{
      'type': 'annonces',
      'per_page': '50',
    };
    final q = _inlineSearchController.text.trim();
    if (q.isNotEmpty) queryParams['q'] = q;
    if (widget.category != null) queryParams['category'] = widget.category!;
    if (widget.location.isNotEmpty) queryParams['location'] = widget.location;
    if (widget.allFrance) queryParams['all_france'] = '1';

    final uri = Uri.parse('${ApiConfig.baseUrl}/search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _annonceResults = List<Map<String, dynamic>>.from(data['data']['items'] ?? []);
          _annoncesTotal = data['data']['meta']['total'] ?? 0;
        });
      }
    }
  }

  Future<void> _fetchUsers() async {
    final queryParams = <String, String>{
      'type': 'users',
      'per_page': '50',
    };
    final q = _inlineSearchController.text.trim();
    if (q.isNotEmpty) queryParams['q'] = q;

    final uri = Uri.parse('${ApiConfig.baseUrl}/search').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          _userResults = List<Map<String, dynamic>>.from(data['data']['users'] ?? []);
          _usersTotal = data['data']['meta']['total'] ?? 0;
        });
      }
    }
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return ApiConfig.resolveMediaUrl(url) ?? '';
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'à l\'instant';
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
      if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem';
      if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
      return 'il y a ${(diff.inDays / 365).floor()} an(s)';
    } catch (_) {
      return '';
    }
  }

  IconData _feedTypeIcon(String feedType) {
    switch (feedType) {
      case 'bon_plan':
        return Icons.local_offer_outlined;
      case 'job_offer':
        return Icons.work_outline;
      case 'training':
        return Icons.school_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'demande':
        return Icons.help_outline;
      case 'post':
        return Icons.article_outlined;
      default:
        return Icons.feed_outlined;
    }
  }

  String _feedTypeLabel(String feedType) {
    switch (feedType) {
      case 'bon_plan':
        return 'Bon plan';
      case 'job_offer':
        return 'Emploi';
      case 'training':
        return 'Formation';
      case 'event':
        return 'Événement';
      case 'demande':
        return 'Demande';
      case 'post':
        return 'Publication';
      default:
        return feedType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ParticulierMainScreen(initialIndex: 3),
              ),
            );
          },
        ),
        title: const Text(
          'Résultats de la recherche',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Inline search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inlineSearchController,
                    onSubmitted: (_) => _fetchResults(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[600], size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _buildFilterChip('Annonces ($_annoncesTotal)', _selectedTab == 'annonces', () {
                  setState(() => _selectedTab = 'annonces');
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Particuliers ($_usersTotal)', _selectedTab == 'users', () {
                  setState(() => _selectedTab = 'users');
                }),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3AAE5E)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Erreur lors de la recherche',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _fetchResults, child: const Text('Réessayer')),
                          ],
                        ),
                      )
                    : _selectedTab == 'annonces'
                        ? _buildAnnoncesList()
                        : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  /* ---------- ANNONCES LIST ---------- */
  Widget _buildAnnoncesList() {
    if (_annonceResults.isEmpty) {
      return _buildEmptyState('Aucun résultat trouvé', 'Essayez de modifier vos critères de recherche.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _annonceResults.length,
      itemBuilder: (context, index) {
        final item = _annonceResults[index];
        return _buildAnnonceCard(item);
      },
    );
  }

  Widget _buildAnnonceCard(Map<String, dynamic> item) {
    final feedType = item['feed_type'] ?? '';
    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final authorName = item['author_name']?.toString() ?? 'Anonyme';
    final authorType = item['author_type']?.toString() ?? 'Particulier';
    final authorAvatar = _resolveUrl(item['author_avatar']?.toString());
    final mediaUrl = _resolveUrl(item['media_url']?.toString());
    final categoryLabel = item['category_label']?.toString() ?? '';
    final merchantName = item['merchant_name']?.toString() ?? '';
    final price = item['price']?.toString();
    final discount = item['discount']?.toString();
    final likesCount = item['likes_count'] ?? 0;
    final commentsCount = item['comments_count'] ?? 0;
    final createdAt = item['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: authorAvatar.isNotEmpty ? NetworkImage(authorAvatar) : null,
                  child: authorAvatar.isEmpty
                      ? Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7EF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(authorType,
                                style: const TextStyle(fontSize: 9, color: Color(0xFF3AAE5E), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_feedTypeLabel(feedType),
                                style: const TextStyle(fontSize: 9, color: Color(0xFFFF9800), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(_timeAgo(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          // Title
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          // Description
          if (description.isNotEmpty && description != title)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          // Media
          if (mediaUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      mediaUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
                      ),
                    ),
                  ),
                  if (discount != null && discount.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(discount,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          // Category + Merchant
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(_feedTypeIcon(feedType), size: 14, color: Colors.grey[500]),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(categoryLabel, style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
                ),
                if (merchantName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.store_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(merchantName, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          // Price + stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                if (price != null && price.isNotEmpty)
                  Text(price,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF9800))),
                const Spacer(),
                Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('$likesCount', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 14),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('$commentsCount', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- USERS LIST ---------- */
  Widget _buildUsersList() {
    if (_userResults.isEmpty) {
      return _buildEmptyState('Aucun utilisateur trouvé', 'Essayez un autre nom ou pseudo.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'Anonyme';
    final avatar = _resolveUrl(user['avatar']?.toString());
    final accountType = user['account_type']?.toString() ?? 'particulier';
    final ville = user['ville']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey))
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accountType == 'pro' ? const Color(0xFFFFF3E0) : const Color(0xFFE6F7EF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                accountType == 'pro' ? 'Pro' : 'Particulier',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accountType == 'pro' ? const Color(0xFFFF9800) : const Color(0xFF3AAE5E),
                ),
              ),
            ),
            if (ville != null && ville.isNotEmpty) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text(ville, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  /* ---------- SHARED WIDGETS ---------- */
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
