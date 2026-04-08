import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/services/profile_service.dart';

class FollowersScreen extends StatefulWidget {
  final bool initialShowFollowers;
  final String? userId;

  const FollowersScreen({
    super.key,
    this.initialShowFollowers = true,
    this.userId,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();

  bool _isLoading = true;
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  String _userName = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialShowFollowers ? 0 : 1,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final targetId = widget.userId;
      if (targetId == null) {
        // If no userId, we can't fetch. This shouldn't happen if coming from profile.
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Fetch name first from public profile if it's not the current user
      final profile = await _profileService.getUserProfile(targetId);
      if (!mounted) return;
      final user = profile['user'] ?? profile;
      _userName = _extractDisplayName(user);

      // Fetch lists
      final followers = await _profileService.getFollowers(targetId);
      if (!mounted) return;
      final following = await _profileService.getFollowing(targetId);
      if (!mounted) return;

      setState(() {
        _followers = followers;
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractDisplayName(Map<String, dynamic>? data) {
    if (data == null) return 'Utilisateur';
    final pro = data['pro_profile'] as Map?;
    final part = data['particulier_profile'] as Map?;
    
    if (part != null) return part['pseudo']?.toString() ?? 'Utilisateur';
    if (pro != null) return pro['company_name']?.toString() ?? '${pro['first_name'] ?? ''} ${pro['last_name'] ?? ''}'.trim();
    
    return data['name']?.toString() ?? 'Utilisateur';
  }

  String _extractAvatar(Map<String, dynamic>? data) {
    if (data == null) return 'assets/images/dashboard_particulier/Ellipse 10.png';
    final pro = data['pro_profile'] as Map?;
    final part = data['particulier_profile'] as Map?;
    
    String? url = part?['avatar_url']?.toString() ?? 
                 pro?['avatar_url']?.toString() ?? 
                 data['avatar']?.toString();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return url;
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      return '$serverBase/storage/$url';
    }
    return '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final userId = user['id']?.toString();
    if (userId == null) return;

    final isFollowing = user['is_following'] ?? false;

    try {
      if (isFollowing) {
        await _profileService.unfollowUser(userId);
      } else {
        await _profileService.followUser(userId);
      }
      // Refresh data
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
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
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _userName,
          style: const TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF757575),
              indicatorWeight: 3,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: '${_followers.length} Follower(s)'),
                Tab(text: '${_following.length} Suivie(s)'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_followers, 'followers'),
              _buildList(_following, 'following'),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> users, String type) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          type == 'followers' ? 'Aucun follower' : 'Aucun utilisateur suivi',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchField(),
        Divider(color: Colors.grey[300]),
        _buildSectionTitle(type == 'followers' ? 'Tous les followers' : 'Suivie(s)'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index] as Map<String, dynamic>;
              return _buildUserItem(user);
            },
          ),
        ),
      ],
    );
  }

  Padding _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  Padding _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Recherche',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final String name = _extractDisplayName(user);
    final String avatar = _extractAvatar(user);
    final bool isFollowing = user['is_following'] ?? false;
    final String userId = user['id']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(userId),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: avatar.startsWith('http') 
                ? NetworkImage(avatar) as ImageProvider
                : AssetImage('assets/images/dashboard_particulier/Ellipse 10.png'),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(userId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => _toggleFollow(user),
            style: OutlinedButton.styleFrom(
              backgroundColor: isFollowing 
                ? Colors.transparent 
                : const Color(0xFF04BC7B).withOpacity(0.1),
              foregroundColor: const Color(0xFF2E9B5B),
              side: const BorderSide(color: Color(0xFF2E9B5B)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isFollowing ? 'Suivi' : 'Suivre',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicProfileScreen(userId: userId),
      ),
    );
  }
}
