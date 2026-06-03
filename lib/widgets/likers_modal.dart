import 'package:flutter/material.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

void showLikersSheet(BuildContext context, String apiSlug, String entityId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LikersSheet(apiSlug: apiSlug, entityId: entityId),
  );
}

class _LikersSheet extends StatefulWidget {
  final String apiSlug;
  final String entityId;
  const _LikersSheet({required this.apiSlug, required this.entityId});

  @override
  State<_LikersSheet> createState() => _LikersSheetState();
}

class _LikersSheetState extends State<_LikersSheet> {
  final _api = ApiClient();
  final _profileService = ProfileService();
  List<Map<String, dynamic>> _likers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikers();
  }

  Future<void> _fetchLikers() async {
    try {
      final response = await _api.authenticatedGet(
          '/${widget.apiSlug}/${widget.entityId}/reactions/likers');
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _likers = List<Map<String, dynamic>>.from(response['data']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _displayName(Map<String, dynamic> user) {
    if (user['account_type'] == 'pro' && user['pro_profile'] != null) {
      return user['pro_profile']['company_name'] ?? 'Pro';
    }
    if (user['particulier_profile'] != null) {
      return user['particulier_profile']['pseudo'] ?? 'Particulier';
    }
    return 'Utilisateur';
  }

  String _avatarUrl(Map<String, dynamic> user) {
    if (user['account_type'] == 'pro' && user['pro_profile'] != null) {
      return user['pro_profile']['logo_url'] ?? '';
    }
    if (user['particulier_profile'] != null) {
      return user['particulier_profile']['avatar_url'] ?? '';
    }
    return '';
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final userId = user['id'];
    final isFollowing = user['is_following'] == true;
    try {
      if (isFollowing) {
        await _profileService.unfollowUser(userId);
      } else {
        await _profileService.followUser(userId);
      }
      setState(() {
        user['is_following'] = !isFollowing;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Qui a liké ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_likers.length} like${_likers.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _likers.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun like pour le moment',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _likers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = _likers[index];
                              final name = _displayName(user);
                              final avatarUrl = _avatarUrl(user);
                              final isFollowing = user['is_following'] == true;

                              return ListTile(
                                leading: ReklamAvatar(
                                  radius: 20,
                                  avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                                  displayName: name,
                                  accountType: user['account_type'],
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () => _toggleFollow(user),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      backgroundColor: isFollowing
                                          ? Colors.grey[200]
                                          : const Color(0xFF3AAE5E),
                                      foregroundColor: isFollowing
                                          ? Colors.black87
                                          : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      isFollowing ? 'Suivi' : 'Suivre',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
