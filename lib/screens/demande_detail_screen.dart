import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/creer_demande_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';

class DemandeDetailScreen extends StatefulWidget {
  final List<String> images;
  final String avatar;
  final String username;
  final String demandeTitle;
  final String description;
  final List<PostTag> tags;
  final PostTag? subtags;
  final String timeAgo;
  // Demande-specific fields
  final String? nature;
  final String? type;
  final bool urgent;
  final String? budgetMax;
  final String? location;
  final bool nationwide;
  final int? searchRadiusKm;
  final bool showGoogleLocation;
  final bool acceptMessages;
  final bool isOwner;
  final String? demandeId;
  final Map<String, dynamic>? demandeData;
  final bool returnToListingOnEdit;

  const DemandeDetailScreen({
    super.key,
    this.images = const [],
    required this.avatar,
    required this.username,
    required this.demandeTitle,
    required this.description,
    this.tags = const [],
    this.subtags,
    this.timeAgo = '',
    this.nature,
    this.type,
    this.urgent = false,
    this.budgetMax,
    this.location,
    this.nationwide = false,
    this.searchRadiusKm,
    this.showGoogleLocation = false,
    this.acceptMessages = false,
    this.isOwner = false,
    this.demandeId,
    this.demandeData,
    this.returnToListingOnEdit = false,
  });

  @override
  State<DemandeDetailScreen> createState() => _DemandeDetailScreenState();
}

class _DemandeDetailScreenState extends State<DemandeDetailScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    if (widget.demandeId == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/${widget.demandeId}/comments?per_page=50',
      );

      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is List) {
        fetched = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['data']);
      }

      if (!mounted) return;
      setState(() {
        _comments = fetched;
      });
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  void _showCommentsSheet(BuildContext context) {
    if (widget.demandeId == null) return;

    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final commentCtrl = TextEditingController();

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/demandes/${widget.demandeId}/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/demandes/${widget.demandeId}/comments',
                    body: {'body': text},
                  );
                }

                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = _comments.firstWhere(
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
                      _comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  setState(() {});
                }

                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();
              } catch (e) {
                debugPrint('Error posting comment: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'envoi')),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Commentaires (${_comments.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (replyingToName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Réponse à $replyingToName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                modalSetState(() {
                                  replyingToId = null;
                                  replyingToName = null;
                                });
                              },
                              child: const Text('Annuler'),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: _isLoadingComments
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _comments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'Aucun commentaire. Soyez le premier !',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                return _buildCommentItem(
                                  _comments[index],
                                  onReply: (id, name) {
                                    modalSetState(() {
                                      replyingToId = id;
                                      replyingToName = name;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentCtrl,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Écrire un commentaire...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3AAE5E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            child: const Icon(Icons.send, size: 18),
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
    ).whenComplete(() {
      _fetchComments();
    });
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment, {
    bool isReply = false,
    void Function(int id, String name)? onReply,
  }) {
    final user = comment['user'] as Map<String, dynamic>?;

    String displayName = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        displayName =
            profile['pseudo']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        displayName =
            profile['company_name']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else {
        displayName = user['name']?.toString() ?? 'Utilisateur';
      }
    }

    String? rawAvatarUrl;
    if (user != null) {
      if (user['particulier_profile'] != null) {
        rawAvatarUrl = user['particulier_profile']['avatar_url']?.toString();
      } else if (user['pro_profile'] != null) {
        rawAvatarUrl = user['pro_profile']['avatar_url']?.toString();
      }
    }
    final avatarUrl = ApiConfig.resolveMediaUrl(rawAvatarUrl);

    final body = (comment['body'] ?? '').toString();
    final createdAt = comment['created_at'];
    String timeAgo = 'Il y a un moment';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = 'Il y a ${diff.inDays}j';
        } else if (diff.inHours > 0) {
          timeAgo = 'Il y a ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeAgo = 'Il y a ${diff.inMinutes}min';
        }
      } catch (_) {}
    }

    final replies = List<Map<String, dynamic>>.from(
      (comment['replies'] as List?) ?? [],
    );

    final id = comment['id'];
    final idInt = id is int ? id : int.tryParse(id?.toString() ?? '');

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : const AssetImage(
                            'assets/images/dashboard_particulier/Ellipse 10.png',
                          )
                          as ImageProvider,
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
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: isReply ? 10 : 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: isReply ? 12 : 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isReply && idInt != null && onReply != null)
                      GestureDetector(
                        onTap: () => onReply(idInt, displayName),
                        child: Text(
                          'Répondre',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isReply && replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...replies.map(
              (r) => _buildCommentItem(r, isReply: true, onReply: onReply),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _effectiveAuthorData() {
    final user = widget.demandeData?['user'];
    if (user is Map<String, dynamic>) return user;
    if (user is String) {
      try {
        final decoded = jsonDecode(user);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _checkFollowStatus() async {
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$authorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_following'] == true) {
          setState(() => _isFollowing = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de suivre cet utilisateur')),
      );
      return;
    }

    setState(() => _isLoadingFollow = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFollowing) {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/unfollow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous ne suivez plus cet utilisateur'),
            ),
          );
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/follow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous suivez maintenant cet utilisateur'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  Future<void> _startConversationWithAuthor(
    BuildContext context,
    Map<String, dynamic> authorData,
  ) async {
    final authorId = authorData['id']?.toString();

    String authorName = 'Utilisateur';
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorName =
          particulierProfile['pseudo']?.toString() ??
          authorData['email']?.toString().split('@').first ??
          'Utilisateur';
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorName =
          proProfile['company_name']?.toString() ??
          (proProfile['first_name']?.toString() != null &&
                  proProfile['last_name']?.toString() != null
              ? '${proProfile['first_name']} ${proProfile['last_name']}'
              : authorData['email']?.toString().split('@').first) ??
          'Utilisateur';
    }

    String? authorAvatar;
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorAvatar = particulierProfile['avatar_url']?.toString();
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorAvatar =
          proProfile['avatar_url']?.toString() ??
          proProfile['logo_url']?.toString();
    }

    if (authorId == null || authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de démarrer la conversation'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final otherUserId = int.tryParse(authorId);
    if (otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID utilisateur invalide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final conversationService = ConversationService();
      final conversation = await conversationService.getOrCreateConversation(
        otherUserId,
      );

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation.id.toString(),
              name: authorName,
              avatar:
                  authorAvatar ??
                  'assets/images/dashboard_particulier/Ellipse 10.png',
              status: 'En ligne',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        String errorMessage = 'Échec, veuillez réessayer';
        final exceptionString = e.toString();
        if (exceptionString.startsWith('Exception: ')) {
          errorMessage = exceptionString.substring('Exception: '.length);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
        title: const Text(
          'Details Demande',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF616161),
                  size: 24,
                ),
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    if (widget.demandeId != null &&
                        widget.demandeData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreerDemandeScreen(
                            demandeId: widget.demandeId,
                            initialData: widget.demandeData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de modifier cette demande'),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Color(0xFF616161),
                        ),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications activées')),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36,
              height: 36,
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Carousel
              if (widget.images.isNotEmpty) ...[
                ImageCarousel(images: widget.images),
                const SizedBox(height: 16),
              ],

              // 2. User Detail Card
              UserDetailCard(
                avatar: widget.avatar,
                name: widget.username,
                userType: widget.nature ?? 'Demande',
                onSubscribe: _toggleFollow,
                isOwner: widget.isOwner,
                isFollowing: _isFollowing,
                isLoading: _isLoadingFollow,
              ),
              const SizedBox(height: 16),

              // 3. Post Content Card (Tags & Title)
              PostContentCard(
                tags: widget.tags,
                subtags: widget.subtags,
                title: widget.demandeTitle,
                time: widget.timeAgo,
                onLike: () {},
                onShare: () {},
              ),
              const SizedBox(height: 16),

              // 4. Urgent badge
              if (widget.urgent)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Demande urgente',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.urgent) const SizedBox(height: 16),

              // 5. Description Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : 'Aucune description fournie.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 6. Details Section (Nature, Type, Budget, Radius)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Details de la demande',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildDetailsGrid(),

                    if (_hasLocation()) const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.location ?? 'Localisation non specifie',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!widget.isOwner && widget.acceptMessages)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final author = widget.demandeData?['user'];
                            if (author is Map<String, dynamic>) {
                              _startConversationWithAuthor(context, author);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Impossible de démarrer la conversation',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.reply_outlined, size: 20),
                          label: const Text('Répondre à la demande'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 8. Localisation Card
              if (_hasLocation())
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey[700],
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.showGoogleLocation)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/details_bon_plans/Rectangle 128 (1).png',
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.map,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      if (widget.showGoogleLocation) const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.place,
                            size: 16,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.nationwide
                                  ? 'Toute la France'
                                  : (widget.location ?? 'Non spécifié'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF616161),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // 9. Commentaires Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.comment_outlined,
                          color: Color(0xFF616161),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Commentaires',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_comments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Aucun commentaire. Soyez le premier !',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _comments
                            .take(2)
                            .map(
                              (comment) =>
                                  _buildCommentItem(comment, onReply: null),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCommentsSheet(context),
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: Text(
                          _comments.isEmpty
                              ? 'Ajouter un commentaire'
                              : 'Voir tous les commentaires',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3AAE5E),
                          side: const BorderSide(color: Color(0xFF3AAE5E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 10. Similar demandes header
              const Center(
                child: Text(
                  'Demandes similaires',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Container(height: 1, color: Colors.grey[300]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.demandeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cette demande')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Supprimer la demande',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette demande ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          final token = await TokenStorage.getAccessToken();
                          if (token == null) throw Exception('Session expirée');
                          final response = await http.delete(
                            Uri.parse(
                              '${ApiConfig.baseUrl}/demandes/$widget.demandeId',
                            ),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 &&
                              response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Demande supprimée avec succès'),
                                backgroundColor: Color(0xFF3AAE5E),
                              ),
                            );
                            Navigator.pop(context, 'deleted');
                          } else {
                            throw Exception('Erreur ${response.statusCode}');
                          }
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erreur: ${e.toString().replaceFirst("Exception: ", "")}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLocation() {
    return widget.nationwide ||
        (widget.location != null && widget.location!.isNotEmpty);
  }

  Widget _buildDetailsGrid() {
    final tiles = _buildDetailTiles();

    if (tiles.isEmpty) {
      return Text(
        'Aucune information disponible.',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tiles
              .map((t) => SizedBox(width: constraints.maxWidth, child: t))
              .toList(),
        );
      },
    );
  }

  List<Widget> _buildDetailTiles() {
    final data = widget.demandeData ?? const <String, dynamic>{};

    final n = (widget.nature ?? '').toString().trim().toLowerCase();
    final isFormation = n.contains('formation');
    final isImmobilier = n.contains('immobilier');
    final isStage = n.contains('stage');
    final isEmploi = n.contains("emploi");

    final tiles = <Widget>[];

    String? str(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    List<String> listStr(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    String? formatDate(dynamic v) {
      final raw = str(v);
      if (raw == null) return null;
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    }

    String? formatBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v ? 'Oui' : 'Non';
      final s = v.toString().toLowerCase();
      if (s == '1' || s == 'true') return 'Oui';
      if (s == '0' || s == 'false') return 'Non';
      return null;
    }

    void addTile({
      required IconData icon,
      required Color iconBg,
      required Color iconColor,
      required String title,
      String? value,
      String? subtitle,
    }) {
      final v = value ?? subtitle;
      if (v == null || v.trim().isEmpty) return;
      tiles.add(
        _buildDetailTile(
          icon: icon,
          iconBg: iconBg,
          iconColor: iconColor,
          title: title,
          value: value,
          subtitle: subtitle,
        ),
      );
    }

    if (isFormation) {
      addTile(
        icon: Icons.school_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Catégorie',
        value: str(data['training_category']),
      );
      addTile(
        icon: Icons.auto_stories_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Type',
        value: str(data['training_type']),
      );
      addTile(
        icon: Icons.hub_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Secteur',
        value: str(data['training_sector']),
      );
      final teaching = listStr(data['teaching_types']);
      addTile(
        icon: Icons.cast_for_education_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Enseignement',
        value: teaching.isNotEmpty ? teaching.join(', ') : null,
      );
      final financing = listStr(data['financing_types']);
      addTile(
        icon: Icons.payments_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Financement',
        value: financing.isNotEmpty ? financing.join(', ') : null,
      );
      addTile(
        icon: Icons.group_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Personnes',
        value: str(data['nb_personnes']),
      );
      addTile(
        icon: Icons.groups_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Groupes',
        value: str(data['nb_groupes']),
      );
      addTile(
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Docs',
        value: formatBool(data['use_candidate_documents']),
      );
    } else if (isImmobilier) {
      addTile(
        icon: Icons.apartment_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Type demande',
        value: str(data['real_estate_type']),
      );
      final props = listStr(data['property_types']);
      addTile(
        icon: Icons.home_work_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Type de bien',
        value: props.isNotEmpty ? props.join(', ') : null,
      );
      final shMin = str(data['surface_habitable_min']);
      final shMax = str(data['surface_habitable_max']);
      addTile(
        icon: Icons.square_foot_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Surface hab.',
        value: (shMin != null || shMax != null)
            ? '${shMin ?? '-'} - ${shMax ?? '-'} m²'
            : null,
      );
      final stMin = str(data['surface_terrain_min']);
      final stMax = str(data['surface_terrain_max']);
      addTile(
        icon: Icons.terrain_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Terrain',
        value: (stMin != null || stMax != null)
            ? '${stMin ?? '-'} - ${stMax ?? '-'} m²'
            : null,
      );
      addTile(
        icon: Icons.meeting_room_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Pièces',
        value: str(data['nb_pieces']),
      );
      addTile(
        icon: Icons.bed_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Chambres',
        value: str(data['nb_chambres']),
      );
      addTile(
        icon: Icons.weekend_outlined,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF8E24AA),
        title: 'Meublé',
        value: formatBool(data['meuble']),
      );
    } else if (isEmploi || isStage) {
      addTile(
        icon: Icons.work_outline,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Secteur',
        value: str(data['activity_sector']),
      );
      addTile(
        icon: Icons.badge_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Fonction',
        value: str(data['function']),
      );
      final contracts = listStr(data['contract_types']);
      addTile(
        icon: Icons.assignment_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Contrat',
        value: contracts.isNotEmpty ? contracts.join(', ') : null,
      );
      addTile(
        icon: Icons.schedule_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Temps',
        value: str(data['work_type']),
      );
      addTile(
        icon: Icons.school_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Études',
        value: str(data['education_level']),
      );
      addTile(
        icon: Icons.trending_up_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Expérience',
        value: str(data['experience_level']),
      );
      addTile(
        icon: Icons.laptop_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Télétravail',
        value: formatBool(data['accept_remote_work']),
      );

      final immediate = formatBool(data['immediate_availability']);
      if (immediate == 'Oui') {
        addTile(
          icon: Icons.flash_on_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Disponibilité',
          value: immediate,
        );
      }

      if (immediate == 'Non') {
        addTile(
          icon: Icons.event_available_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Début',
          value: formatDate(data['start_date']),
        );
        addTile(
          icon: Icons.event_outlined,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          title: 'Fin',
          value: formatDate(data['end_date']),
        );
      }

      addTile(
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Documents',
        value: formatBool(data['use_candidate_documents'] ?? data['doc_cand']),
      );

      final salaryRange = str(data['salary_range']);
      final sMin = str(data['salary_min']);
      final sMax = str(data['salary_max']);
      final netOrBrut = str(data['salary_net_or_brut']);
      final indice = str(data['salary_indice_temporel']);

      String? salaryText() {
        final hasMinMax =
            (sMin != null && sMin.isNotEmpty) ||
            (sMax != null && sMax.isNotEmpty);
        if (hasMinMax) {
          var t = '${sMin ?? '-'} - ${sMax ?? '-'} €';
          if (netOrBrut == 'net') t += ' (Net)';
          if (netOrBrut == 'brut') t += ' (Brut)';
          if (indice == 'annees') t += ' / Années';
          if (indice == 'heures') t += ' / Heures';
          return t;
        }

        if (salaryRange != null &&
            salaryRange.toLowerCase() != 'aucune' &&
            salaryRange.toLowerCase() != 'none') {
          return salaryRange;
        }
        return null;
      }

      addTile(
        icon: Icons.euro,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Salaire',
        value: salaryText(),
      );
    }

    return tiles;
  }

  Widget _buildDetailTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (value ?? subtitle ?? '').toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
