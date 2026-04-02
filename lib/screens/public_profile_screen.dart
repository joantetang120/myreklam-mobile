import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/screens/followers_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/profile_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initialData;

  const PublicProfileScreen({
    super.key,
    this.userId,
    this.initialData,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _profileService = ProfileService();
  final _conversationService = ConversationService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _selectedTab = 'Présentation';
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final String? targetId = widget.userId ?? widget.initialData?['id']?.toString();
      
      if (targetId == null) {
        // Fallback to current user if no ID provided
        final response = await _profileService.getProfile();
        setState(() {
          _userData = response['user'] ?? response;
          _isLoading = false;
        });
      } else {
        final response = await _profileService.getUserProfile(targetId);
        setState(() {
          _userData = response['user'] ?? response;
          _isFollowing = response['is_following'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du profil: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final targetId = _userData?['id']?.toString();
    if (targetId == null) return;

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(targetId);
      } else {
        await _profileService.followUser(targetId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _startConversation() async {
    final targetIdStr = _userData?['id']?.toString();
    final targetId = int.tryParse(targetIdStr ?? '');
    
    if (targetId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _conversationService.getOrCreateConversation(targetId);
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final displayName = _extractDisplayName(_userData);
      final avatar = _extractAvatar(_userData);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name: displayName,
            avatar: avatar,
            status: 'En ligne',
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer la conversation: $e')),
        );
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
                 pro?['logo_url']?.toString() ?? 
                 pro?['avatar_url']?.toString() ?? 
                 data['avatar']?.toString();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return url;
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      return '$serverBase/storage/$url';
    }
    
    return 'assets/images/dashboard_particulier/Ellipse 10.png';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName = _extractDisplayName(_userData);
    final avatar = _extractAvatar(_userData);
    final accountType = _userData?['pro_profile'] != null ? 'Professionnel' : 'Particulier';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3AAE5E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayName,
          style: const TextStyle(color: Color(0xFF616161), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E9B5B), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountType,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      
                      // Stats Row: Posts, Followers, Following
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                (_userData?['posts_count'] ?? 0).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text('Posts', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: () {
                              final String? uid = _userData?['id']?.toString();
                              if (uid != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersScreen(
                                      userId: uid,
                                      initialShowFollowers: true,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  (_userData?['followers_count'] ?? 0).toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text('Followers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: () {
                              final String? uid = _userData?['id']?.toString();
                              if (uid != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersScreen(
                                      userId: uid,
                                      initialShowFollowers: false,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  (_userData?['following_count'] ?? 0).toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Text('Suivi(s)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startConversation,
                              icon: const Icon(Icons.message_outlined, size: 18),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3AAE5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width:12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleFollow,
                              icon: Icon(_isFollowing ? Icons.check : Icons.person_add_outlined, size: 18),
                              label: Text(_isFollowing ? 'Suivi' : 'Suivre'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3AAE5E),
                                side: const BorderSide(color: Color(0xFF3AAE5E)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Avatar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Color(0xFF2E9B5B), shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        backgroundImage: avatar.startsWith('http') 
                          ? NetworkImage(avatar) as ImageProvider 
                          : avatar.startsWith('assets/')
                              ? AssetImage(avatar)
                              : NetworkImage(ApiConfig.resolveMediaUrl(avatar) ?? '') as ImageProvider,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildTabButton('Présentation'),
                  _buildTabButton('Annonces'),
                  _buildTabButton('Post'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Content
            _buildTabContent(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEF8A40) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'Annonces':
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucune annonce pour le moment'),
        );
      case 'Post':
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Aucun post pour le moment'),
        );
      default:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Présentation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Text(
                _userData?['bio'] ?? 'Aucune présentation disponible.',
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
            ],
          ),
        );
    }
  }
}
