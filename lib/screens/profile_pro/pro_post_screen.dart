import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/create_post_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/widgets/post_content_card.dart';

class ProPostScreen extends StatefulWidget {
  const ProPostScreen({super.key});

  @override
  State<ProPostScreen> createState() => _ProPostScreenState();
}

class _ProPostScreenState extends State<ProPostScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = true;
  String? _error;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
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
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Impossible de charger vos posts.';
          _isLoading = false;
        });
    }
  }

  Future<void> _refreshPosts() => _loadPosts(showLoader: false);

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase$url';
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
      _loadPosts();
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
        _loadPosts();
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

  @override
  Widget build(BuildContext context) {
    final myPostsOnly = _myPosts.where((p) => !_isRepost(p)).toList();
    final repostsOnly = _myPosts.where(_isRepost).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes posts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3AAE5E),
          tabs: [
            Tab(text: 'Posts(${myPostsOnly.length})'),
            Tab(text: 'Republications(${repostsOnly.length})'),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3AAE5E),
        onPressed: _createNewPost,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody({required List<Map<String, dynamic>> postsOverride}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3AAE5E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AAE5E),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (postsOverride.isEmpty) {
      return const Center(
        child: Text(
          'Vous n\'avez aucun post/republication pour l\'instant',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF3AAE5E),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: postsOverride.length,
        itemBuilder: (context, index) {
          final post = postsOverride[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPostCard(post),
          );
        },
      ),
    );
  }

  Future<void> _createNewPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (result == 'updated' && mounted) {
      _loadPosts();
    }
  }

  List<String> _extractPostMediaUrls(Map<String, dynamic> post) {
    final media = post['media_files'] as List? ?? post['media'] as List? ?? [];
    if (media.isEmpty) return [];
    return media
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final url = m['url']?.toString() ?? '';
          return _buildStorageUrl(url);
        })
        .whereNotNull()
        .where((url) => url.isNotEmpty)
        .toList();
  }

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

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final user = rawPost['user'] as Map<String, dynamic>?;
    final userType = user?['account_type']?.toString() ?? 'Professionnel';
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
}
