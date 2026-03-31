import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/conversation_service.dart';

class JobDetailScreen extends StatefulWidget {
  final List<String> images;
  final String companyLogo;
  final String companyName;
  final String companyWebsite;
  final String jobTitle;
  final String description;
  final dynamic descriptionDelta;
  final String? profileDescription;
  final List<JobDetailTag> tags;
  final List<PostTag> postTags;
  final PostTag? subtags;
  final List<String> advantages;
  final String timeAgo;
  final String location;
  final bool remoteWork;
  final String? educationLevel;
  final String? experienceLevel;
  final bool isOwner;
  final String? jobOfferId;
  final Map<String, dynamic>? jobOfferData;
  final bool acceptMessages;
  final Map<String, dynamic>? authorData;
  final int applyButtonFlex;
  final int websiteButtonFlex;

  const JobDetailScreen({
    super.key,
    this.images = const [
      'assets/images/dashboard_particulier/Rectangle 13.png',
      'assets/images/dashboard_particulier/Rectangle 13.png',
    ],
    required this.companyLogo,
    required this.companyName,
    this.companyWebsite = '',
    required this.jobTitle,
    required this.description,
    this.descriptionDelta,
    this.profileDescription,
    required this.tags,
    this.postTags = const <PostTag>[],
    this.subtags,
    required this.advantages,
    required this.timeAgo,
    this.location = '',
    this.remoteWork = false,
    this.educationLevel,
    this.experienceLevel,
    this.isOwner = false,
    this.jobOfferId,
    this.jobOfferData,
    this.acceptMessages = false,
    this.authorData,
    this.applyButtonFlex = 1,
    this.websiteButtonFlex = 2,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
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
    if (widget.jobOfferId == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final response = await ApiClient().authenticatedGet(
        '/job-offers/${widget.jobOfferId}/comments?per_page=50',
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
    if (widget.jobOfferId == null) return;

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
                    '/job-offers/${widget.jobOfferId}/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/job-offers/${widget.jobOfferId}/comments',
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
    if (widget.authorData != null) return widget.authorData;
    final user = widget.jobOfferData?['user'];
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

  @override
  Widget build(BuildContext context) {
    Future<void> applyToJobOffer() async {
      if (widget.isOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vous ne pouvez pas postuler à votre propre offre."),
          ),
        );
        return;
      }

      final id = widget.jobOfferId?.toString();
      if (id == null || id.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Offre invalide.")));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF3AAE5E)),
        ),
      );

      try {
        // final profile = await ProfileService().getProfile();
        // final user = profile['user'] is Map<String, dynamic>
        //     ? profile['user'] as Map<String, dynamic>
        //     : null;

        // final accountType = (user?['account_type'] ?? user?['type'] ?? '')
        //     .toString()
        //     .toLowerCase();
        // final hasParticulierProfile =
        //     user?['particulier_profile'] != null ||
        //     profile['particulier_profile'] != null;

        // final isParticulier =
        //     accountType.contains('particulier') || hasParticulierProfile;

        // if (!isParticulier) {
        //   if (context.mounted) Navigator.pop(context);
        //   if (!context.mounted) return;
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text(
        //         "Seuls les profils particulier peuvent postuler à une offre d'emploi.",
        //       ),
        //     ),
        //   );
        //   return;
        // }

        final response = await ApiClient().authenticatedPost(
          '/job-offers/$id/apply',
          body: const <String, dynamic>{},
        );

        if (context.mounted) Navigator.pop(context);
        if (!context.mounted) return;

        final message =
            response['message']?.toString() ??
            'Candidature envoyée avec succès.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );
      } on ApiException catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }

    // Debug: Check contact button conditions
    debugPrint('=== JOB CONTACT BUTTON DEBUG ===');
    debugPrint('isOwner: ${widget.isOwner}');
    debugPrint('acceptMessages: ${widget.acceptMessages}');
    debugPrint('authorData: ${widget.authorData}');
    debugPrint('authorData != null: ${widget.authorData != null}');

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
          'Detail de l\'offre',
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
                    if (widget.jobOfferId != null &&
                        widget.jobOfferData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreerOffreEmploiScreen(
                            jobOfferId: widget.jobOfferId,
                            initialData: widget.jobOfferData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de modifier cette offre'),
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
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications activées')),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE6F7EF),
                    border: Border.all(
                      color: const Color(0xFF2A8143),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF2A8143),
                    size: 18,
                  ),
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
                avatar: widget.companyLogo,
                name: widget.companyName,
                userType: 'Pro',
                onSubscribe: _toggleFollow,
                isOwner: widget.isOwner,
                isFollowing: _isFollowing,
                isLoading: _isLoadingFollow,
              ),
              const SizedBox(height: 16),

              PostContentCard(
                tags: widget.postTags,
                subtags: widget.subtags,
                title: widget.jobTitle,
                time: widget.timeAgo,
                onLike: () {},
                onShare: () {},
              ),
              const SizedBox(height: 16),

              // 3. Qui sommes nous Section
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(color: Colors.grey.withOpacity(0.15)),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.05),
              //         blurRadius: 10,
              //         offset: const Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         children: [
              //           Icon(
              //             Icons.business_outlined,
              //             color: Colors.grey[600],
              //             size: 20,
              //           ),
              //           const SizedBox(width: 8),
              //           Text(
              //             'Qui sommes nous',
              //             style: TextStyle(
              //               fontSize: 15,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.grey[700],
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 12),
              //       Text(
              //         profileDescription ?? companyName,
              //         style: TextStyle(
              //           fontSize: 13,
              //           color: Colors.grey[600],
              //           height: 1.6,
              //         ),
              //       ),
              //       if (companyWebsite.isNotEmpty) ...[
              //         const SizedBox(height: 8),
              //         Row(
              //           children: [
              //             Icon(
              //               Icons.language,
              //               size: 16,
              //               color: Colors.blue[600],
              //             ),
              //             const SizedBox(width: 4),
              //             Expanded(
              //               child: Text(
              //                 companyWebsite,
              //                 style: TextStyle(
              //                   fontSize: 13,
              //                   color: Colors.blue[600],
              //                   fontWeight: FontWeight.w500,
              //                 ),
              //                 overflow: TextOverflow.ellipsis,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ],
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                ),
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
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (widget.educationLevel != null ||
                  widget.experienceLevel != null ||
                  widget.remoteWork)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profil recherché',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.educationLevel != null) ...[
                        _buildInfoRow(
                          null,
                          'Niveau d\'études requis',
                          widget.educationLevel!,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.experienceLevel != null) ...[
                        _buildInfoRow(
                          null,
                          'Expérience professionnelle',
                          widget.experienceLevel!,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.profileDescription != null) ...[
                        _buildInfoRow(
                          null,
                          'Description du profil',
                          widget.profileDescription!,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Job Specific Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informations supplementaires',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final tiles = _buildInfoTiles();

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: tiles
                              .map(
                                (t) => SizedBox(
                                  width: constraints.maxWidth,
                                  child: _buildInfoTile(t),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Divider(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Avantages',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.advantages
                          .map((adv) => _buildAdvantageTag(adv))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        !widget.isOwner
                            ? Expanded(
                                flex: widget.applyButtonFlex,
                                child: ElevatedButton(
                                  onPressed: applyToJobOffer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF9800),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text('Postuler'),
                                ),
                              )
                            : const SizedBox.shrink(),
                        !widget.isOwner
                            ? const SizedBox(width: 12)
                            : const SizedBox.shrink(),
                        Expanded(
                          flex: widget.websiteButtonFlex,
                          child: OutlinedButton.icon(
                            onPressed: widget.companyWebsite.isNotEmpty
                                ? () => _openCompanyWebsite(context)
                                : null,
                            icon: const Icon(Icons.language, size: 18),
                            label: const Text("Le site de l'entreprise"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF9800),
                              side: const BorderSide(color: Color(0xFFFF9800)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact button - only if not owner and acceptMessages is true
              if (!widget.isOwner &&
                  widget.acceptMessages &&
                  widget.authorData != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _startConversation(context, widget.authorData!),
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      label: const Text('Contacter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              if (!widget.isOwner &&
                  widget.acceptMessages &&
                  widget.authorData != null)
                const SizedBox(height: 16),

              // Localisation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF3AAE5E),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/details_bon_plans/Rectangle 128 (1).png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.location.isNotEmpty
                          ? widget.location
                          : 'Localisation non spécifiée',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                ),
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

              const Center(
                child: Text(
                  "offres d'emplois similaires",
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
                ), // space on sides
                child: Container(
                  height: 1, // thin line
                  color: Colors.grey[300], // light gray
                ),
              ),

              SizedBox(height: 15),

              JobAnnouncementCard(
                companyLogo:
                    'assets/images/dashboard_particulier/Rectangle 13.png',
                companyName: 'The North Face Sarl',
                jobTitle: 'Développeur Fullstack PHP',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                tags: const [
                  JobDetailTag(
                    icon: Icons.description_outlined,
                    text: 'Contrat à durée indéterminée',
                  ),
                  JobDetailTag(
                    icon: Icons.location_on_outlined,
                    text: 'Luxembourg',
                  ),
                  JobDetailTag(
                    icon: Icons.school_outlined,
                    text: 'Bac+2 / autre diplôme equivalent',
                  ),
                  JobDetailTag(
                    icon: Icons.work_history_outlined,
                    text: "intermédiaire : 1 an d'expérience",
                  ),
                  JobDetailTag(icon: Icons.access_time, text: 'Temps plein'),
                  JobDetailTag(
                    icon: Icons.home_work_outlined,
                    text: 'Présentiel uniquement',
                  ),
                  JobDetailTag(
                    icon: Icons.monetization_on_outlined,
                    text: 'Selon le profil',
                    isSpecial: true,
                  ),
                ],
                advantages: const ['Primes', 'Heures supplementaires'],
                timeAgo: 'il y a 2 jours',
                onApply: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobDetailScreen(
                        companyLogo:
                            'assets/images/dashboard_particulier/Rectangle 13.png',
                        companyName: 'Dyson Sarl',
                        jobTitle: 'Développeur Fullstack PHP',
                        description:
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                        tags: [
                          JobDetailTag(
                            icon: Icons.description_outlined,
                            text: 'Contrat à durée indéterminée',
                          ),
                          JobDetailTag(
                            icon: Icons.location_on_outlined,
                            text: 'Luxembourg',
                          ),
                          JobDetailTag(
                            icon: Icons.school_outlined,
                            text: 'Bac+2 / autre diplôme equivalent',
                          ),
                          JobDetailTag(
                            icon: Icons.work_history_outlined,
                            text: "intermédiaire : 1 an d'expérience",
                          ),
                          JobDetailTag(
                            icon: Icons.access_time,
                            text: 'Temps plein',
                          ),
                          JobDetailTag(
                            icon: Icons.home_work_outlined,
                            text: 'Présentiel uniquement',
                          ),
                          JobDetailTag(
                            icon: Icons.monetization_on_outlined,
                            text: 'Selon le profil',
                            isSpecial: true,
                          ),
                        ],
                        advantages: ['Primes', 'Heures supplementaires'],
                        timeAgo: 'il y a 2 jours',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              JobAnnouncementCard(
                companyLogo:
                    'assets/images/dashboard_particulier/Rectangle 13.png',
                companyName: 'The North Face Sarl',
                jobTitle: 'Développeur Fullstack PHP',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                tags: const [
                  JobDetailTag(
                    icon: Icons.description_outlined,
                    text: 'Contrat à durée indéterminée',
                  ),
                  JobDetailTag(
                    icon: Icons.location_on_outlined,
                    text: 'Luxembourg',
                  ),
                  JobDetailTag(
                    icon: Icons.school_outlined,
                    text: 'Bac+2 / autre diplôme equivalent',
                  ),
                  JobDetailTag(
                    icon: Icons.work_history_outlined,
                    text: "intermédiaire : 1 an d'expérience",
                  ),
                  JobDetailTag(icon: Icons.access_time, text: 'Temps plein'),
                  JobDetailTag(
                    icon: Icons.home_work_outlined,
                    text: 'Présentiel uniquement',
                  ),
                  JobDetailTag(
                    icon: Icons.monetization_on_outlined,
                    text: 'Selon le profil',
                    isSpecial: true,
                  ),
                ],
                advantages: const ['Primes', 'Heures supplementaires'],
                timeAgo: 'il y a 2 jours',
                onApply: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobDetailScreen(
                        companyLogo:
                            'assets/images/dashboard_particulier/Rectangle 13.png',
                        companyName: 'Dyson Sarl',
                        jobTitle: 'Développeur Fullstack PHP',
                        description:
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                        tags: [
                          JobDetailTag(
                            icon: Icons.description_outlined,
                            text: 'Contrat à durée indéterminée',
                          ),
                          JobDetailTag(
                            icon: Icons.location_on_outlined,
                            text: 'Luxembourg',
                          ),
                          JobDetailTag(
                            icon: Icons.school_outlined,
                            text: 'Bac+2 / autre diplôme equivalent',
                          ),
                          JobDetailTag(
                            icon: Icons.work_history_outlined,
                            text: "intermédiaire : 1 an d'expérience",
                          ),
                          JobDetailTag(
                            icon: Icons.access_time,
                            text: 'Temps plein',
                          ),
                          JobDetailTag(
                            icon: Icons.home_work_outlined,
                            text: 'Présentiel uniquement',
                          ),
                          JobDetailTag(
                            icon: Icons.monetization_on_outlined,
                            text: 'Selon le profil',
                            isSpecial: true,
                          ),
                        ],
                        advantages: ['Primes', 'Heures supplementaires'],
                        timeAgo: 'il y a 2 jours',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _startConversation(
    BuildContext context,
    Map<String, dynamic> authorData,
  ) async {
    try {
      final authorIdStr = authorData['id']?.toString();
      if (authorIdStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de contacter cet utilisateur'),
          ),
        );
        return;
      }

      final authorId = int.tryParse(authorIdStr);
      if (authorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID utilisateur invalide')),
        );
        return;
      }

      final conversationId = await ConversationService()
          .getOrCreateConversation(authorId);
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversationId.toString(),
            name:
                authorData['display_name']?.toString() ??
                authorData['name']?.toString() ??
                'Utilisateur',
            avatar:
                authorData['avatar_url']?.toString() ??
                authorData['avatar']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Widget _buildDescription() {
    debugPrint(
      'JOB DETAIL _buildDescription: descriptionDelta type=${widget.descriptionDelta?.runtimeType}, value=$widget.descriptionDelta',
    );
    if (widget.descriptionDelta != null) {
      try {
        List opsList;

        if (widget.descriptionDelta is List) {
          // Already a List<dynamic> from the API — best case
          opsList = widget.descriptionDelta as List;
        } else if (widget.descriptionDelta is Map &&
            (widget.descriptionDelta as Map)['ops'] is List) {
          opsList = (widget.descriptionDelta as Map)['ops'] as List;
        } else if (widget.descriptionDelta is String &&
            (widget.descriptionDelta as String).isNotEmpty) {
          String jsonString = widget.descriptionDelta as String;
          // Fix unquoted keys
          jsonString = jsonString.replaceAllMapped(
            RegExp(r'(\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
            (match) => '${match.group(1)}"${match.group(2)}":',
          );
          // Fix unquoted string values
          jsonString = jsonString.replaceAllMapped(
            RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s]*?)(\s*[,\}\]])'),
            (match) {
              final value = match.group(1)!.trim();
              if (value == 'true' || value == 'false' || value == 'null') {
                return ': $value${match.group(2)}';
              }
              return ': "$value"${match.group(2)}';
            },
          );
          dynamic rawData = jsonDecode(jsonString);
          if (rawData is String) rawData = jsonDecode(rawData);
          if (rawData is List) {
            opsList = rawData;
          } else if (rawData is Map && rawData['ops'] is List) {
            opsList = rawData['ops'] as List;
          } else {
            throw Exception('Unknown delta format: ${rawData.runtimeType}');
          }
        } else {
          throw Exception(
            'Unsupported descriptionDelta type: ${widget.descriptionDelta.runtimeType}',
          );
        }

        // Filter out operations with null insert values
        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isEmpty) throw Exception('No valid ops');

        // Ensure last op ends with newline (Quill requirement)
        final lastInsert = filteredOps.last['insert'];
        if (lastInsert is String && !lastInsert.endsWith('\n')) {
          filteredOps.add({'insert': '\n'});
        }

        final doc = quill.Document.fromJson(filteredOps);
        final controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        return quill.QuillEditor.basic(
          controller: controller,
          config: quill.QuillEditorConfig(
            padding: EdgeInsets.zero,
            onLaunchUrl: (url) async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      } catch (e) {
        debugPrint('Error rendering rich text in job detail: $e');
      }
    }

    return Text(
      widget.description,
      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.jobOfferId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer cette offre d\'emploi'),
        ),
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
              'Supprimer l\'offre d\'emploi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette offre d\'emploi ? Cette action est irréversible.',
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
                              '${ApiConfig.baseUrl}/job-offers/${widget.jobOfferId}',
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
                                content: Text(
                                  'Offre d\'emploi supprimée avec succès',
                                ),
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

  Widget _buildInfoRow(IconData? icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon != null
            ? Icon(icon, size: 18, color: Colors.grey[600])
            : SizedBox.shrink(),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  List<_InfoTileData> _buildInfoTiles() {
    String firstTagText(bool Function(JobDetailTag) test) {
      return widget.tags
          .where(test)
          .map((t) => t.text)
          .firstWhere((t) => t.trim().isNotEmpty, orElse: () => '');
    }

    final salaryText = firstTagText(
      (t) =>
          t.icon == Icons.euro ||
          t.icon == Icons.monetization_on_outlined ||
          t.icon == Icons.monetization_on,
    );
    final educationText = widget.educationLevel?.trim().isNotEmpty == true
        ? widget.educationLevel!
        : firstTagText(
            (t) => t.icon == Icons.school_outlined || t.icon == Icons.school,
          );
    final experienceText = widget.experienceLevel?.trim().isNotEmpty == true
        ? widget.experienceLevel!
        : firstTagText(
            (t) =>
                t.icon == Icons.trending_up_outlined ||
                t.icon == Icons.work_history_outlined ||
                t.icon == Icons.work_history,
          );
    final locationText = widget.location.trim().isNotEmpty
        ? widget.location
        : firstTagText((t) => t.icon == Icons.location_on_outlined);

    final workPolicyText = widget.remoteWork
        ? 'Télétravail possible'
        : 'Pas de télétravail';

    final tiles = <_InfoTileData>[];
    if (educationText.isNotEmpty) {
      tiles.add(
        _InfoTileData(
          icon: Icons.school_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Formation',
          subtitle: educationText,
        ),
      );
    }
    if (locationText.isNotEmpty) {
      tiles.add(
        _InfoTileData(
          icon: Icons.public,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Localisation',
          subtitle: locationText,
        ),
      );
    }
    // if (availabilityText.isNotEmpty) {
    //   tiles.add(
    //     _InfoTileData(
    //       icon: Icons.calendar_month,
    //       iconBg: const Color(0xFFE3F2FD),
    //       iconColor: const Color(0xFF27A5FF),
    //       title: 'Offre à pourvoir',
    //       subtitle: availabilityText,
    //     ),
    //   );
    // }
    if (experienceText.isNotEmpty) {
      tiles.add(
        _InfoTileData(
          icon: Icons.work_outline,
          iconBg: const Color(0xFFF3E5F5),
          iconColor: const Color(0xFF9C27B0),
          title: 'Expérience',
          subtitle: experienceText,
        ),
      );
    }

    tiles.add(
      _InfoTileData(
        icon: Icons.groups_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE91E63),
        title: 'Politique de travail',
        subtitle: workPolicyText,
      ),
    );
    if (salaryText.isNotEmpty) {
      tiles.add(
        _InfoTileData(
          icon: Icons.euro,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFFF3B30),
          title: 'Salaire',
          subtitle: salaryText,
        ),
      );
    }

    return tiles;
  }

  Widget _buildInfoTile(_InfoTileData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCompanyWebsite(BuildContext context) async {
    final uri = Uri.tryParse(widget.companyWebsite);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le site")),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le site")),
      );
    }
  }

  Widget _buildAdvantageTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3AAE5E).withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3AAE5E),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoTileData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTileData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}
