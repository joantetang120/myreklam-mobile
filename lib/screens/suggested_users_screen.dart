import 'package:flutter/material.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/screens/public_profile_screen.dart';
import 'package:myreklam/config/api_config.dart';

class SuggestedUsersScreen extends StatefulWidget {
  const SuggestedUsersScreen({super.key});

  @override
  State<SuggestedUsersScreen> createState() => _SuggestedUsersScreenState();
}

class _SuggestedUsersScreenState extends State<SuggestedUsersScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _profileService.getSuggestions(query: _query);
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearch(String value) {
    setState(() {
      _query = value;
    });
    _loadUsers();
  }

  Future<void> _toggleFollow(int index) async {
    final user = _users[index];
    try {
      await _profileService.followUser(user['id'].toString());
      if (mounted) {
        setState(() {
          _users.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous suivez maintenant ${user['particulier_profile']?['pseudo'] ?? user['pro_profile']?['company_name'] ?? 'cet utilisateur'}'),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$serverBase/storage/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profils suggérés',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Aucun utilisateur trouvé'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isPro = user['account_type'] == 'pro';
                          final profile = isPro ? user['pro_profile'] : user['particulier_profile'];
                          final name = isPro 
                              ? (profile?['company_name'] ?? 'Pro') 
                              : (profile?['pseudo'] ?? 'Utilisateur');
                          final avatar = profile?['avatar_url'] ?? profile?['logo_url'];
                          final avatarUrl = _buildStorageUrl(avatar) ?? 'assets/images/dashboard_particulier/Ellipse 10.png';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PublicProfileScreen(
                                          userId: user['id'].toString(),
                                        ),
                                      ),
                                    ).then((_) => _loadUsers());
                                  },
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundImage: avatarUrl.startsWith('http')
                                            ? NetworkImage(avatarUrl)
                                            : AssetImage(avatarUrl) as ImageProvider,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isPro ? 'Pro' : 'Particulier',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _toggleFollow(index),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF3AAE5E)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "S'abonner",
                                      style: TextStyle(
                                        color: Color(0xFF3AAE5E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
