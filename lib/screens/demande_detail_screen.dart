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
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';

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
  List<Map<String, dynamic>> _similarDemandes = [];
  bool _isLoadingSimilar = false;

  static const _natureLabels = {
    'emploi': 'Recherche d\'emploi',
    'searchjob': 'Recherche d\'emploi',
    'service': 'Recherche de service',
    'logement': 'Recherche de logement',
    'immobilier': 'Recherche de logement',
    'produit': 'Recherche de produit',
    'formation': 'Recherche de formation',
    'collaboration': 'Collaboration',
    'stage': 'Recherche de stage',
    'internship': 'Recherche de stage',
    'alternance': 'Recherche d\'alternance',
    'alternance_search': 'Recherche d\'alternance',
    'jobsearch': 'Recherche d\'emploi',
    'autre': 'Autre demande',
  };

  String _getNatureLabel(String? nature) {
    if (nature == null || nature.isEmpty) return 'Demande';
    return _natureLabels[nature.toLowerCase()] ?? nature;
  }

  /// Resolves display name from demandeData['user'], falling back to widget.username.
  String _resolveOwnerName() {
    final user = widget.demandeData?['user'];
    if (user is! Map) return widget.username;
    // particulier pseudo
    if (user['particulier_profile'] is Map) {
      final pseudo = (user['particulier_profile'] as Map)['pseudo']?.toString() ?? '';
      if (pseudo.isNotEmpty) return pseudo;
    }
    // pro company name
    if (user['pro_profile'] is Map) {
      final company = (user['pro_profile'] as Map)['company_name']?.toString() ?? '';
      if (company.isNotEmpty) return company;
    }
    // generic name / email
    final name = user['name']?.toString() ?? '';
    if (name.isNotEmpty && name != 'Utilisateur') return name;
    final email = user['email']?.toString() ?? '';
    if (email.contains('@')) return email.split('@').first;
    return widget.username;
  }

  /// Resolves avatar URL from demandeData['user'], falling back to widget.avatar.
  String _resolveOwnerAvatar() {
    final user = widget.demandeData?['user'];
    if (user is! Map) return widget.avatar;
    final candidates = [
      if (user['particulier_profile'] is Map)
        (user['particulier_profile'] as Map)['avatar_url'],
      if (user['pro_profile'] is Map) ...[
        (user['pro_profile'] as Map)['avatar_url'],
        (user['pro_profile'] as Map)['logo_url'],
      ],
      user['avatar_url'],
      user['avatar'],
      user['profile_picture'],
    ];
    for (final c in candidates) {
      final s = c?.toString() ?? '';
      if (s.isEmpty) continue;
      final resolved = ApiConfig.resolveMediaUrl(s);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return widget.avatar;
  }

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _fetchComments();
    _fetchSimilarDemandes();
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

  Future<void> _fetchSimilarDemandes() async {
    setState(() => _isLoadingSimilar = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/feed/latest?type=demande&per_type_limit=30',
      );
      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = (body['data']?['items'] as List?) ?? [];
        final nature = (widget.nature ?? '').toLowerCase();

        // Score similarity
        final scored = <Map<String, dynamic>>[];
        for (final item in items) {
          final resource = item['resource'] as Map<String, dynamic>?;
          if (resource == null) continue;
          final id = resource['id']?.toString() ?? item['id']?.toString();
          if (id == widget.demandeId) continue;

          int score = 0;
          final rNature = (resource['nature'] ?? '').toString().toLowerCase();
          if (rNature == nature) score += 3;
          final rLocation = (resource['location'] ?? '').toString().toLowerCase();
          final myLocation = (widget.location ?? '').toLowerCase();
          if (myLocation.isNotEmpty && rLocation.contains(myLocation)) score += 1;

          scored.add({'resource': resource, 'score': score});
        }
        scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        final top = scored.take(5).map((e) => e['resource'] as Map<String, dynamic>).toList();

        if (!mounted) return;
        setState(() => _similarDemandes = top);
      }
    } catch (e) {
      debugPrint('Error fetching similar demandes: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSimilar = false);
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
                
                // Award 1 My for posting a comment (silently, no modal)
                try {
                  final mysResponse = await MysEarningService().awardMys(
                    actionType: 'comment',
                    referenceId: newComment?['id']?.toString(),
                  );
                  if (mysResponse['success'] == true) {
                    final newBalance = mysResponse['earning']?['new_balance'];
                    if (newBalance != null) {
                      UserSession().updateMys(newBalance);
                    }
                  }
                } catch (e) {
                  debugPrint("Error awarding My's for comment: $e");
                }
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
                              fontFamily: 'Manjari',
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
                                  fontFamily: 'Manjari',
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
                              child: const Text('Annuler', style: TextStyle(fontFamily: 'Manjari')),
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
                                    fontFamily: 'Manjari',
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
                            fontFamily: 'Manjari',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: isReply ? 10 : 11,
                            color: Colors.grey[500],
                            fontFamily: 'Manjari',
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
                        fontFamily: 'Manjari',
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
                            fontFamily: 'Manjari',
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
          'Détail de la demande',
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
      body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Carousel - full width
              if (widget.images.isNotEmpty)
                ImageCarousel(images: widget.images),

              // 2. Tags + Title + Urgent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nature tag
                    if (widget.type != null && widget.type!.isNotEmpty)
                      _buildTag(
                        widget.type!,
                        Icons.description_outlined,
                        const Color(0xFF3AAE5E),
                      ),
                    if (widget.type != null && widget.type!.isNotEmpty)
                      const SizedBox(height: 10),
                    // Urgent badge
                    if (widget.urgent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Demande urgente',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Title
                    Text(
                      widget.demandeTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Manjari',
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // 3. Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Manjari',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : 'Aucune description fournie.',
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey[600], 
                        height: 1.6,
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Informations section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Manjari',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildDetailsGrid(),
                    // Lieu
                    if (_hasLocation()) ...[
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF3AAE5E),
                        bgColor: const Color(0xFFE6F7EF),
                        label: 'Zone de recherche',
                        value: widget.nationwide
                            ? 'Toute la France'
                            : (widget.location ?? 'Non spécifié'),
                      ),
                    ],
                    // Budget
                    if (widget.demandeData != null &&
                        (widget.demandeData!['budget_min'] != null ||
                            widget.demandeData!['budget_max'] != null)) ...[
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFF2A8143),
                        bgColor: const Color(0xFFE6F7EF),
                        label: 'Budget',
                        value: _buildBudgetText(),
                      ),
                    ],
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. CTA buttons
              if (!widget.isOwner)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Reply button
                      if (widget.acceptMessages)
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
                                  content: Text('Impossible de démarrer la conversation'),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      if (widget.acceptMessages)
                        const SizedBox(height: 12),

                      // Documents button
                      if (((formatBool(widget.demandeData?['use_candidate_documents'] ?? widget.demandeData?['doc_cand']) == 'Oui') ||
                          (widget.demandeData?['media_files'] as List? ?? widget.demandeData?['media'] as List? ?? []).isNotEmpty) &&
                          !(widget.nature?.toLowerCase().contains('immobilier') ?? false))
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ouverture des documents...')),
                              );
                            },
                            icon: const Icon(Icons.description_outlined, size: 20),
                            label: const Text('Voir les documents'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3AAE5E),
                              side: const BorderSide(color: Color(0xFF3AAE5E)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (((formatBool(widget.demandeData?['use_candidate_documents'] ?? widget.demandeData?['doc_cand']) == 'Oui') ||
                          (widget.demandeData?['media_files'] as List? ?? widget.demandeData?['media'] as List? ?? []).isNotEmpty) &&
                          !(widget.nature?.toLowerCase().contains('immobilier') ?? false))
                        const SizedBox(height: 16),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // 6. Action row (Favoris, Partager)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.favorite_outline, color: Colors.grey[600], size: 24),
                      ),
                      Text('Favoris', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Manjari')),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 24),
                      ),
                      Text('Partager', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Manjari')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7. Owner section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _resolveOwnerAvatar().startsWith('http')
                          ? NetworkImage(_resolveOwnerAvatar()) as ImageProvider
                          : const AssetImage('assets/images/dashboard_particulier/Ellipse 12.png'),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resolveOwnerName(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Manjari',
                            ),
                          ),
                         
                        ],
                      ),
                    ),
                    if (!widget.isOwner)
                      _isLoadingFollow
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _isFollowing ? Colors.grey : const Color(0xFF3AAE5E),
                                side: BorderSide(
                                  color: _isFollowing ? Colors.grey : const Color(0xFF3AAE5E),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                _isFollowing ? 'Suivi' : 'Suivre',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 8. Posted time (at bottom, like on events detail)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.timeAgo.isNotEmpty ? widget.timeAgo : 'Posté récemment',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontFamily: 'Manjari',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 9. Comments section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment_outlined, color: Color(0xFF616161), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Commentaires',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            fontFamily: 'Manjari',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_comments.length}',
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey[500],
                            fontFamily: 'Manjari',
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
                              fontFamily: 'Manjari',
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _comments.take(2)
                            .map((c) => _buildCommentItem(c, onReply: null))
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCommentsSheet(context),
                        icon: const Icon(Icons.chat_outlined, size: 18),
                        label: Text(_comments.isEmpty ? 'Ajouter un commentaire' : 'Voir tous les commentaires'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3AAE5E),
                          side: const BorderSide(color: Color(0xFF3AAE5E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 10. Demandes similaires
              const Center(
                child: Text(
                  'Demandes similaires',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                    fontFamily: 'Manjari',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(height: 1, color: Colors.grey[300]),
              ),
              if (_isLoadingSimilar)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_similarDemandes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text(
                      'Aucune demande similaire trouvée.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.grey[500],
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _similarDemandes
                        .map((d) => _buildSimilarDemandeCard(d))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Manjari',
              ),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette demande ? Cette action est irréversible.',
              style: TextStyle(fontFamily: 'Manjari'),
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
                    : const Text('Supprimer', style: TextStyle(fontFamily: 'Manjari')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Manjari',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13, 
                  color: Colors.grey[600],
                  fontFamily: 'Manjari',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Manjari',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasLocation() {
    return widget.nationwide ||
        (widget.location != null && widget.location!.isNotEmpty);
  }

  String _buildBudgetText() {
    final data = widget.demandeData ?? const <String, dynamic>{};
    final budgetMin = data['budget_min'];
    final budgetMax = data['budget_max'];
    
    String minStr = '-';
    if (budgetMin != null) {
      final minNum = double.tryParse(budgetMin.toString()) ?? 0;
      minStr = minNum.round().toString();
    }
    
    String maxStr = '-';
    if (budgetMax != null) {
      final maxNum = double.tryParse(budgetMax.toString()) ?? 0;
      maxStr = maxNum.round().toString();
    }
    
    return 'Min: $minStr € - Max: $maxStr €';
  }

  List<Widget> _buildDetailsGrid() {
    final tiles = _buildDetailTiles();
    if (tiles.isEmpty) return [];
    return tiles
        .map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: t))
        .toList();
  }

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

  List<Widget> _buildDetailTiles() {
    final data = widget.demandeData ?? const <String, dynamic>{};

    final n = (widget.nature ?? '').toString().trim().toLowerCase();
    final isFormation = n.contains('formation') || n.contains('training') || n.contains('searchtraining');
    final isImmobilier = n.contains('immobilier') || n.contains('realestate');
    final isStage = n.contains('stage') || n.contains('internship');
    final isEmploi = n.contains("emploi") || n.contains("searchjob") || n.contains("jobsearch");
    final isAlternance = n.contains('alternance');

    final tiles = <Widget>[];

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
        _buildDetailItem(
          icon: icon,
          bgColor: iconBg,
          iconColor: iconColor,
          label: title,
          value: v,
        ),
      );
    }

    if (isFormation) {
      const educationLabels = {
        'aucun': 'Aucun diplôme',
        'brevet': 'Brevet des collèges',
        'cap_bep': 'CAP / BEP',
        'bac': 'Baccalauréat',
        'bac_2': 'Bac +2 (BTS, DUT)',
        'bac_3_4': 'Bac +3/4 (Licence, Master 1)',
        'bac_5': 'Bac +5 (Master 2, Ingénieur)',
        'doctorat': 'Doctorat',
      };

      const experienceLabels = {
        'junior': 'Débutant (0-2 ans)',
        'intermediaire': 'Intermédiaire (2-5 ans)',
        'confirme': 'Confirmé (5-10 ans)',
        'senior': 'Sénior (+10 ans)',
      };

      final fCategory = data['training_category'] ?? data['category'] ?? data['category_label'] ?? data['training']?['category'] ?? data['details']?['category'];
      addTile(
        icon: Icons.school_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Catégorie de formation souhaité',
        value: str(fCategory),
      );

      final fType = data['training_type'] ?? data['type'] ?? data['type_label'] ?? data['training']?['type'] ?? data['details']?['type'];
      addTile(
        icon: Icons.auto_stories_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Type de formation souhaité',
        value: str(fType),
      );

      final fSector = data['training_sector'] ?? data['sector'] ?? data['sector_label'] ?? data['training']?['sector'] ?? data['details']?['sector'];
      addTile(
        icon: Icons.hub_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Secteur de formation',
        value: str(fSector),
      );

      const teachingLabels = {
        'tout': 'Tout',
        'entreprise': 'En entreprise',
        'alternance': 'En alternance',
        'centre': 'En centre',
        'distance': 'À distance',
      };

      const financingLabels = {
        'tout': 'Tout',
        'conseil_regional': 'Conseil régional',
        'opco': 'OPCO',
        'mission_locale': 'Mission Locale',
        'auto_financement': 'Auto-Financement',
        'agefiph': 'AGEFIPH',
        'pole_emploi': 'Pôle Emploi',
        'cpf': 'CPF',
      };

      final tRaw = data['teaching_types'] ?? data['teaching'] ?? data['teaching_type'] ?? data['training']?['teaching_types'] ?? data['details']?['teaching_types'];
      final teaching = listStr(tRaw)
          .map((c) => teachingLabels[c] ?? c)
          .toList();
      addTile(
        icon: Icons.cast_for_education_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Type d\'enseignement souhaité',
        value: teaching.isNotEmpty ? teaching.join(', ') : null,
      );

      final fRaw = data['financing_types'] ?? data['financing'] ?? data['financing_type'] ?? data['training']?['financing_types'] ?? data['details']?['financing_types'];
      final financing = listStr(fRaw)
          .map((c) => financingLabels[c] ?? c)
          .toList();
      addTile(
        icon: Icons.payments_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Financement possible',
        value: financing.isNotEmpty ? financing.join(', ') : null,
      );

      final immediate = formatBool(data['dans_immediat'] ?? data['immediate_availability']);
      if (immediate == 'Oui') {
        addTile(
          icon: Icons.flash_on_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Disponibilité',
          value: 'Immédiate',
        );
      } else {
        final start = formatDate(data['start_date'] ?? data['start'] ?? data['training']?['start_date']);
        final end = formatDate(data['end_date'] ?? data['end'] ?? data['training']?['end_date']);
        addTile(
          icon: Icons.event_available_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Dates de formation souhaitées',
          value: start != null
            ? (end != null ? 'Du $start au $end' : 'À partir du $start')
            : null,
        );
      }

      final roleStr = str(data['user_type']) ?? str(data['user_role']) ?? str(data['user']?['role']) ?? '';
      final isProUser = roleStr.contains('pro') || roleStr.contains('business');
      final hasProData = str(data['nb_personnes']) != null || str(data['nb_groupes']) != null;
      
      if (isProUser || hasProData) {
        final nbP = str(data['nb_personnes'] ?? data['training']?['nb_personnes'] ?? data['details']?['nb_personnes']);
        final nbG = str(data['nb_groupes'] ?? data['training']?['nb_groupes'] ?? data['details']?['nb_groupes']);
        String? targetValue;
        if (nbP != null && nbG != null) {
          targetValue = '$nbP personne(s) / $nbG groupe(s)';
        } else if (nbP != null) {
          targetValue = '$nbP personne(s)';
        } else if (nbG != null) {
          targetValue = '$nbG groupe(s)';
        }
        addTile(
          icon: Icons.people_outline,
          iconBg: const Color(0xFFF5F5F5),
          iconColor: const Color(0xFF616161),
          title: 'Public à former',
          value: targetValue,
        );
      } else {
        final edRaw = data['education_level'] ?? data['level_education'] ?? data['training']?['education_level'] ?? data['details']?['education_level'];
        addTile(
          icon: Icons.school_outlined,
          iconBg: Colors.orange.withValues(alpha: 0.1),
          iconColor: Colors.orange,
          title: 'Niveau d\'étude',
          value: educationLabels[str(edRaw)] ?? str(edRaw) ?? 'À définir',
        );
        final exRaw = data['experience_level'] ?? data['level_experience'] ?? data['training']?['experience_level'] ?? data['details']?['experience_level'];
        addTile(
          icon: Icons.work_history_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF3AAE5E),
          title: 'Niveau d\'expérience',
          value: experienceLabels[str(exRaw)] ?? str(exRaw) ?? 'À définir',
        );
      }
    } else if (isImmobilier) {
      final props = listStr(data['property_types']);
      addTile(
        icon: Icons.home_work_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Type de bien souhaiter',
        value: props.isNotEmpty ? props.join(', ') : null,
      );
      final shMin = str(data['surface_habitable_min']);
      final shMax = str(data['surface_habitable_max']);
      addTile(
        icon: Icons.square_foot_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Surface habitable',
        value: (shMin != null || shMax != null)
            ? '${shMin ?? '-'} - ${shMax ?? '-'} m²'
            : null,
      );
      final stMin = str(data['surface_terrain_min']);
      final stMax = str(data['surface_terrain_max']);
      // Only show Terrain if values exist and are not 0
      bool hasNonZeroTerrain = false;
      String? terrainValue;
      
      if (stMin != null || stMax != null) {
        final stMinNum = double.tryParse(stMin ?? '0') ?? 0;
        final stMaxNum = double.tryParse(stMax ?? '0') ?? 0;
        
        // Show if at least one value is non-zero
        if (stMinNum > 0 || stMaxNum > 0) {
          hasNonZeroTerrain = true;
          terrainValue = '${stMinNum > 0 ? stMinNum.toString() : '-'} - ${stMaxNum > 0 ? stMaxNum.toString() : '-'} m²';
        }
      }
      
      if (hasNonZeroTerrain && terrainValue != null) {
        addTile(
          icon: Icons.terrain_outlined,
          iconBg: const Color(0xFFEDE7F6),
          iconColor: const Color(0xFF673AB7),
          title: 'Terrain',
          value: terrainValue,
        );
      }
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
    } else if (isEmploi || isStage || isAlternance) {
      // Translation maps
      const educationLabels = {
        'sans_diplome': 'Sans diplome',
        'cap_bep': 'CAP/BEP',
        'bac_employe': 'BAC/Employé/Ouvrier spécialisé',
        'bac2_technicien': 'BAC+2/Technicien/Employé',
        'bac3_agent_maitrise': 'BAC+3/Agent de maîtrise',
        'bac5_ingenieur': 'BAC+5 ou plus/Ingénieur/Cadre',
      };

      const experienceLabels = {
        'debutant': 'Débutant : de 0 a 1 annee',
        'intermediaire': 'Intermédiaire : de 2 a 4 annee',
        'confirme': 'Confirme : de 5 a 9 annee',
        'senior': 'Senior : de 10 annee ou plus',
      };

      const contractLabels = {
        'cdi': 'CDI',
        'cdd': 'CDD',
        'interim': 'Intérim',
        'independant': 'Indépendant / Freelance',
        'benevolat': 'Bénévolat',
        'apprentissage': 'Apprentissage',
        'stage': 'Stage',
      };

      const sectorLabels = {
        'secteur_achats': 'Achats',
        'secteur_administratif': 'Administratif',
        'secteur_aeronautique': 'Aéronautique',
        'secteur_agriculture': 'Agriculture',
        'secteur_agroalimentaire': 'Agroalimentaire',
        'secteur_architecture': 'Architecture',
        'secteur_artisanat': 'Artisanat',
        'secteur_assurances': 'Assurances',
        'secteur_audiovisuel': 'Audiovisuel',
        'secteur_audit': 'Audit',
        'secteur_automobile': 'Automobile',
        'secteur_banque': 'Banque',
        'secteur_batiment': 'Bâtiment',
        'secteur_beaute': 'Beauté',
        'secteur_bois': 'Bois',
        'secteur_chimie': 'Chimie',
        'secteur_commerce': 'Commerce',
        'secteur_communication': 'Communication',
        'secteur_comptabilite': 'Comptabilité',
        'secteur_conseil': 'Conseil',
        'secteur_construction': 'Construction',
        'secteur_culture': 'Culture',
        'secteur_defense': 'Défense',
        'secteur_design': 'Design',
        'secteur_distribution': 'Distribution',
        'secteur_droit': 'Droit',
        'secteur_edition': 'Édition',
        'secteur_education': 'Éducation',
        'secteur_electronique': 'Électronique',
        'secteur_energie': 'Énergie',
        'secteur_enseignement': 'Enseignement',
        'secteur_environnement': 'Environnement',
        'secteur_evenementiel': 'Événementiel',
        'secteur_finance': 'Finance',
        'secteur_fonction_publique': 'Fonction publique',
        'secteur_hotellerie': 'Hôtellerie',
        'secteur_immobilier': 'Immobilier',
        'secteur_industrie': 'Industrie',
        'secteur_informatique': 'Informatique',
        'secteur_ingenierie': 'Ingénierie',
        'secteur_internet': 'Internet',
        'secteur_journalisme': 'Journalisme',
        'secteur_juridique': 'Juridique',
        'secteur_logistique': 'Logistique',
        'secteur_luxe': 'Luxe',
        'secteur_marketing': 'Marketing',
        'secteur_mecanique': 'Mécanique',
        'secteur_medical': 'Médical',
        'secteur_mode': 'Mode',
        'secteur_multimedia': 'Multimédia',
        'secteur_naval': 'Naval',
        'secteur_pharmaceutique': 'Pharmaceutique',
        'secteur_production': 'Production',
        'secteur_publicite': 'Publicité',
        'secteur_qualite': 'Qualité',
        'secteur_recherche': 'Recherche',
        'secteur_restauration': 'Restauration',
        'secteur_ressources_humaines': 'Ressources humaines',
        'secteur_sante': 'Santé',
        'secteur_securite': 'Sécurité',
        'secteur_services': 'Services',
        'secteur_social': 'Social',
        'secteur_sport': 'Sport',
        'secteur_telecommunication': 'Télécommunication',
        'secteur_textile': 'Textile',
        'secteur_tourisme': 'Tourisme',
        'secteur_transport': 'Transport',
        'secteur_travail_temporaire': 'Travail temporaire',
        'secteur_vente': 'Vente',
      };

      const functionLabels = {
        'administratif': 'Agent de bureau',
        'aeronautique': 'Agent de liaison',
        'agriculture': 'Adjoint DAF',
      };

      const workTypeLabels = {
        'temps_plein': 'Temps plein',
        'temps_partiel': 'Temps partiel',
      };

      final sectorKey = str(data['activity_sector']);
      addTile(
        icon: Icons.work_outline,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Secteur d\'activité',
        value: sectorLabels[sectorKey] ?? sectorKey,
      );
      final functionKey = str(data['function']);
      addTile(
        icon: Icons.badge_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Fonction recherchée',
        value: functionLabels[functionKey] ?? functionKey,
      );
      final contracts = listStr(data['contract_types']).map((c) => contractLabels[c] ?? c).toList();
      addTile(
        icon: Icons.assignment_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Type de contrat souhaité',
        value: contracts.isNotEmpty ? contracts.join(', ') : null,
      );
      final workTypeKey = str(data['work_type']);
      addTile(
        icon: Icons.schedule_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Temps de travail souhaité',
        value: workTypeKey != null ? (workTypeLabels[workTypeKey] ?? workTypeKey) : null,
      );

      addTile(
        icon: Icons.school_outlined,
        iconBg: Colors.orange.withValues(alpha: 0.1),
        iconColor: Colors.orange,
        title: 'Niveau d\'étude',
        value: educationLabels[str(data['education_level'])] ?? str(data['education_level']),
      );

      addTile(
        icon: Icons.work_history_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF3AAE5E),
        title: 'Niveau d\'expérience',
        value: experienceLabels[str(data['experience_level'])] ?? str(data['experience_level']),
      );

      addTile(
        icon: Icons.home_work_outlined,
        iconBg: Colors.blue.withValues(alpha: 0.1),
        iconColor: Colors.blue,
        title: 'Télétravail souhaité',
        value: formatBool(data['accept_remote_work']),
      );

      final immediate = formatBool(data['immediate_availability']);
      if (immediate == 'Oui') {
        addTile(
          icon: Icons.flash_on_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Disponibilité',
          value: 'Immédiate',
        );
      }

      if (immediate == 'Non') {
        addTile(
          icon: Icons.event_available_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Date de début souhaité',
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

      final salaryRange = str(data['salary_range']);
      final sMin = str(data['salary_min']);
      final sMax = str(data['salary_max']);
      final netOrBrut = str(data['salary_net_or_brut']);
      final indice = str(data['salary_indice_temporel'] ?? data['salary_period'] ?? data['period']);

      String? salaryText() {
        final hasMinMax =
            (sMin != null && sMin.isNotEmpty) ||
            (sMax != null && sMax.isNotEmpty);
            
        String suffix = '';
        if (indice == 'annees' || indice == 'annee' || indice == 'an' || indice == 'annuel') {
          suffix = ' / An';
        } else if (indice == 'mois' || indice == 'mensuel' || indice == 'mensualite') {
          suffix = ' / Mois';
        } else if (indice == 'heures' || indice == 'heure' || indice == 'horaire') {
          suffix = ' / Heure';
        } else if (indice == 'jours' || indice == 'jour' || indice == 'journalier') {
          suffix = ' / Jour';
        }

        if (hasMinMax) {
          var t = '${sMin ?? '-'} - ${sMax ?? '-'} €';
          if (netOrBrut == 'Net' || netOrBrut == 'net') t += ' (Net)';
          if (netOrBrut == 'Brut' || netOrBrut == 'brut') t += ' (Brut)';
          t += suffix;
          return t;
        }

        if (salaryRange != null &&
            salaryRange.toLowerCase() != 'aucune' &&
            salaryRange.toLowerCase() != 'none') {
          return salaryRange + suffix;
        }
        return null;
      }

      addTile(
        icon: Icons.euro,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Prétention salariale',
        value: salaryText(),
      );
    }

    return tiles;
  }

  String _timeAgo(String? dateStr) {
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

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  Widget _buildSimilarDemandeCard(Map<String, dynamic> d) {
    final title = d['title']?.toString() ?? 'Demande';
    final description = _stripHtml(d['description']?.toString() ?? '');
    final nature = d['nature']?.toString() ?? '';
    final urgent = d['urgent'] == true || d['urgent'] == 1;
    final nationwide = d['nationwide'] == true;
    final locationRaw = d['location']?.toString() ?? d['city']?.toString() ?? '';
    final location = nationwide
        ? 'Toute la France'
        : (locationRaw.isNotEmpty ? locationRaw : 'Non spécifié');

    final user = d['user'] is Map<String, dynamic>
        ? d['user'] as Map<String, dynamic>
        : null;

    // Resolve username same way as demandes_screen
    String username = user?['name']?.toString() ??
        user?['email']?.toString().split('@').first ??
        'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] is Map) {
        final pseudo =
            (user['particulier_profile'] as Map)['pseudo']?.toString() ?? '';
        if (pseudo.isNotEmpty) username = pseudo;
      } else if (user['pro_profile'] is Map) {
        final company =
            (user['pro_profile'] as Map)['company_name']?.toString() ?? '';
        if (company.isNotEmpty) username = company;
      }
    }

    // Resolve avatar
    final avatarCandidates = <dynamic>[
      user?['avatar_url'],
      if (user?['particulier_profile'] is Map)
        (user!['particulier_profile'] as Map)['avatar_url'],
      if (user?['pro_profile'] is Map) ...[
        (user!['pro_profile'] as Map)['avatar_url'],
        (user['pro_profile'] as Map)['logo_url'],
      ],
      user?['avatar'],
    ];
    String profileImage = 'assets/images/dashboard_particulier/Ellipse 10.png';
    for (final c in avatarCandidates) {
      final resolved = ApiConfig.resolveMediaUrl(c?.toString());
      if (resolved != null && resolved.isNotEmpty) {
        profileImage = resolved;
        break;
      }
    }

    final categoryLabel = nature.isNotEmpty
        ? _getNatureLabel(nature)
        : 'Demande';

    return DemandeCard(
      profileImage: profileImage,
      username: username,
      categoryLabel: urgent ? '$categoryLabel • Urgent' : categoryLabel,
      categoryColor: const Color(0xFF3AAE5E),
      title: title,
      description: description,
      location: location,
      likesCount: (d['likes_count'] is int)
          ? d['likes_count'] as int
          : int.tryParse(d['likes_count']?.toString() ?? '') ?? 0,
      commentsCount: (d['comments_count'] is int)
          ? d['comments_count'] as int
          : int.tryParse(d['comments_count']?.toString() ?? '') ?? 0,
      timeAgo: _timeAgo(d['created_at']?.toString()),
      onTapCTA: () {
        final id = d['id']?.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DemandeDetailScreen(
              avatar: profileImage,
              username: username,
              demandeTitle: title,
              description: description,
              nature: nature,
              location: locationRaw,
              nationwide: nationwide,
              urgent: urgent,
              demandeId: id,
              demandeData: d,
              acceptMessages:
                  d['accept_messages'] == true || d['accept_messages'] == 1,
            ),
          ),
        );
      },
    );
  }
}
