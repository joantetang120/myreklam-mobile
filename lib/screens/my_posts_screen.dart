import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/create_post_screen.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/widgets/post_content_card.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyPosts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoadingPosts = true;
        _postsError = null;
      });
    }

    try {
      final response = await ApiClient().authenticatedGet('/posts');
      final data = response['data'];
      List<Map<String, dynamic>> posts = [];
      if (data is List) {
        posts = List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data['data'] is List) {
        posts = List<Map<String, dynamic>>.from(data['data'] as List);
      }

      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _postsError = e.message;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = 'Impossible de charger vos posts.';
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() => _loadMyPosts(showLoader: false);

  bool _isRepost(Map<String, dynamic> post) {
    final originalPostId = post['original_post_id'];
    return originalPostId != null && originalPostId.toString().isNotEmpty;
  }

  Map<String, dynamic> _displayPostForCard(Map<String, dynamic> rawPost) {
    final original = rawPost['original_post'];
    if (_isRepost(rawPost) && original is Map<String, dynamic>) {
      return original;
    }
    return rawPost;
  }

  @override
  Widget build(BuildContext context) {
    final myPostsOnly = _myPosts.where((p) => !_isRepost(p)).toList();
    final repostsOnly = _myPosts.where(_isRepost).toList();

    return AppLayout(
      currentIndex: 4,
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ParticulierMainScreen(initialIndex: 4),
              ),
            );
          },
        ),
        title: const Text(
          'Mes posts',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF616161),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3AAE5E),
          tabs: [
            Tab(text: 'Posts (${myPostsOnly.length})'),
            Tab(text: 'Republier (${repostsOnly.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBody(postsOverride: myPostsOnly),
          _buildBody(postsOverride: repostsOnly),
        ],
      ),
    );
  }

  Widget _buildBody({required List<Map<String, dynamic>> postsOverride}) {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_postsError != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildErrorState(_postsError!),
        ),
      );
    }

    if (postsOverride.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Aucun post disponible',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: postsOverride.length,
        itemBuilder: (context, index) {
          return _buildPostCard(postsOverride[index]);
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        TextButton(onPressed: _loadMyPosts, child: const Text('Réessayer')),
      ],
    );
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase$url';
  }

  List<String> _extractPostMediaUrls(Map<String, dynamic> post) {
    final media = post['media_files'] as List? ?? post['media'] as List? ?? [];
    if (media.isEmpty) return [];
    return media
        .whereType<Map<String, dynamic>>()
        .map((m) => _buildStorageUrl(m['url']?.toString() ?? ''))
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }

  void _showPostMenu(Map<String, dynamic> post) {
    final postId = post['id']?.toString();
    if (postId == null) return;

    final isRepost = _isRepost(post);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!isRepost)
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFFFF9800),
                ),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost(post);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(postId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final postId = post['id']?.toString();
    if (postId == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(postId: postId, initialData: post),
      ),
    );
    if (result == 'updated' && mounted) {
      _loadMyPosts();
    }
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce post ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePost(postId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await ApiClient().authenticatedDelete('/posts/$postId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post supprimé avec succès'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
        _loadMyPosts();
      }
    } catch (e) {
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

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final user = rawPost['user'] as Map<String, dynamic>?;
    final userType = user?['account_type']?.toString() ?? 'Particulier';
    final createdAt = rawPost['created_at']?.toString();

    final displayPost = _displayPostForCard(rawPost);
    final postText = displayPost['content']?.toString() ?? '';
    final mediaUrls = _extractPostMediaUrls(displayPost);

    final tags = <PostTag>[
      PostTag(
        title: userType,
        icon: userType.toUpperCase() == 'PRO' ? Icons.business : Icons.person,
        color: userType.toUpperCase() == 'PRO'
            ? const Color(0xFF2E9B5B)
            : const Color(0xFF3AAE5E),
      ),
    ];

    return PostContentCard(
      tags: tags,
      title: postText.isNotEmpty ? postText : 'Post sans contenu',
      time: _buildTimeAgo(createdAt),
      imageUrls: mediaUrls,
      onLike: () {},
      onShare: () {},
      onMorePressed: () => _showPostMenu(rawPost),
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
}
