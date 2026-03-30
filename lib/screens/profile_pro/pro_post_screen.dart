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

class _ProPostScreenState extends State<ProPostScreen> {
  List<Map<String, dynamic>> _myPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
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

  String? _extractPostImageUrl(Map<String, dynamic> post) {
    final media = post['media_files'] as List? ?? post['media'] as List? ?? [];
    if (media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) return _buildStorageUrl(url);
      }
    }
    return null;
  }

  void _showPostMenu(Map<String, dynamic> post) {
    final postId = post['id']?.toString();
    if (postId == null) return;

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
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 16,
                  top: 16,
                  bottom: 6,
                ),
                child: Text(
                  'Mes posts (${_myPosts.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadPosts,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              else if (_myPosts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Text(
                    'Vous n\'avez pas encore publié de post.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                for (final post in _myPosts) ...[
                  _buildPostCard(post),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> rawPost) {
    final user = rawPost['user'] as Map<String, dynamic>?;
    final userType = user?['account_type']?.toString() ?? 'Professionnel';
    final postText = rawPost['content']?.toString() ?? '';
    final createdAt = rawPost['created_at']?.toString();
    final imageUrl = _extractPostImageUrl(rawPost);

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
      imageUrl: imageUrl,
      onLike: () {},
      onShare: () {},
      onMorePressed: () => _showPostMenu(rawPost),
    );
  }
}
