import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/utils/address_formatter.dart';
import 'package:myreklam/widgets/location_map.dart';
// Bouton partager masqué
// import 'package:myreklam/services/share_service.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart' show CustomBottomBar;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';
import 'package:myreklam/widgets/likers_modal.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/report_reason_dialog.dart';
import 'package:myreklam/widgets/post_content_card.dart' show PostTag;
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/utils/comment_sanitizer.dart';
import 'package:myreklam/utils/subscription_helper.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
// Bouton partager masqué
// import 'package:share_plus/share_plus.dart';

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction;
  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userReaction,
  });
}

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
  final String? locationCity;
  final String? locationPostalCode;
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
  final int? commentsCount;

  const JobDetailScreen({
    super.key,
    this.images = const [],
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
    this.locationCity,
    this.locationPostalCode,
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
    this.commentsCount,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _hasApplied = false;
  final bool _isLoadingApply = false;
  List<Map<String, dynamic>> _comments = [];
  int? _localCommentsCount;
  bool _isLoadingComments = false;
  List<Map<String, dynamic>> _similarJobOffers = [];
  bool _isLoadingSimilar = false;

  /// Check if edit option should be shown
  /// Hide edit if: 1) post is older than 2 hours OR 2) people have applied
  bool get _canEdit {
    return widget.isOwner;
  }

  @override
  void initState() {
    super.initState();
    _localCommentsCount = widget.commentsCount;
    _checkFollowStatus();
    _checkFavoriteStatus();
    _checkApplicationStatus();
    _fetchComments();
    _fetchSimilarJobOffers();
  }

  Future<void> _checkApplicationStatus() async {
    if (widget.isOwner || widget.jobOfferId == null) return;

    try {
      final response = await ApiClient().authenticatedGet(
        '/job-offers/my-applications',
      );

      final data = response['data'];
      if (data is List) {
        final applications = List<Map<String, dynamic>>.from(data);
        final hasApplied = applications.any((app) {
          final jobId =
              app['job_offer_id']?.toString() ??
              app['jobOfferId']?.toString() ??
              app['job_offer']?['id']?.toString();
          return jobId == widget.jobOfferId;
        });
        if (hasApplied) {
          setState(() => _hasApplied = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking application status: $e');
    }
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
      fetched = CommentSanitizer.forEntity(
        fetched,
        entityId: widget.jobOfferId!,
        entityCreatedAt: widget.jobOfferData?['created_at'],
      );

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

  void _showCommentsSheet(BuildContext context) async {
    if (widget.jobOfferId == null) return;
    await _getCurrentUserId();
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
              if (!SubscriptionHelper.canAccessFeature(
                ProFeature.commentAndReact,
              )) {
                if (context.mounted) {
                  SubscriptionHelper.showPremiumRequiredDialog(
                    context,
                    featureName: 'Commentaires et réactions',
                  );
                }
                return;
              }

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
                  setState(() {
                    _localCommentsCount =
                        (_localCommentsCount ?? _comments.length) + 1;
                  });
                }

                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();

                // Refresh comments from API to ensure count is accurate
                await _fetchComments();

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

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);
              final newText = await showDialog<String>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(dialogCtx, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (newText == null ||
                  newText.trim().isEmpty ||
                  newText == currentBody) {
                return;
              }
              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment =
                    response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  setState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });
                  modalSetState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la modification: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(
              Map<String, dynamic> comment,
              bool isReply,
            ) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');
                setState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = _comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    _comments.removeWhere((c) => c['id'] == commentId);
                    if (_localCommentsCount != null &&
                        _localCommentsCount! > 0) {
                      _localCommentsCount = _localCommentsCount! - 1;
                    }
                  }
                });
                modalSetState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom,
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
                                  onEdit: editComment,
                                  onDelete: deleteComment,
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
    void Function(Map<String, dynamic>)? onEdit,
    void Function(Map<String, dynamic>, bool)? onDelete,
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
    final userId = user?['id']?.toString();
    final isOwner = userId != null && userId == _currentUserId;

    final id = comment['id'];
    final idInt = id is int ? id : int.tryParse(id?.toString() ?? '');

    return reportableCommentGesture(
      context: context,
      comment: comment,
      currentUserId: _currentUserId,
      child: Padding(
        padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReklamAvatar(
                  avatarUrl: avatarUrl,
                  displayName: displayName,
                  radius: isReply ? 14 : 18,
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
                          if (isOwner &&
                              (onEdit != null || onDelete != null)) ...[
                            const Spacer(),
                            GestureDetector(
                              onTapDown: (TapDownDetails details) {
                                showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    details.globalPosition.dx,
                                    details.globalPosition.dy,
                                    details.globalPosition.dx,
                                    details.globalPosition.dy,
                                  ),
                                  items: [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Modifier'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Supprimer',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value == 'edit') {
                                    onEdit?.call(comment);
                                  } else if (value == 'delete')
                                    onDelete?.call(comment, isReply);
                                });
                              },
                              child: Icon(
                                Icons.more_horiz,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
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
                (r) => _buildCommentItem(
                  r,
                  isReply: true,
                  onReply: onReply,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ],
        ),
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

  Future<void> _checkFavoriteStatus() async {
    if (widget.jobOfferId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/job-offers/${widget.jobOfferId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['is_favorited'] == true) {
          setState(() => _isFavorite = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.jobOfferId == null) return;

    setState(() => _isLoadingFavorite = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFavorite) {
        // Unfavorite
        final response = await http.delete(
          Uri.parse(
            '${ApiConfig.baseUrl}/job-offers/${widget.jobOfferId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
        }
      } else {
        // Favorite
        final response = await http.post(
          Uri.parse(
            '${ApiConfig.baseUrl}/job-offers/${widget.jobOfferId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _fetchSimilarJobOffers() async {
    setState(() => _isLoadingSimilar = true);
    try {
      // Fetch latest job offers from feed
      final response = await ApiClient().authenticatedGet(
        '/feed/latest?type=job_offer&per_type_limit=4',
      );

      if (response['success'] == true && response['data'] != null) {
        final items = response['data']['items'] as List? ?? [];
        // Extract resource data and filter out current job offer
        final filtered = items
            .map((item) {
              dynamic resourceData = item['resource'];
              Map<String, dynamic> resource;

              // Handle case where resource is a JSON string instead of Map
              if (resourceData is String) {
                resource = jsonDecode(resourceData) as Map<String, dynamic>;
              } else if (resourceData is Map) {
                resource = Map<String, dynamic>.from(resourceData);
              } else {
                resource = {};
              }

              // Ensure id is available at top level for filtering
              resource['id'] = item['id'];
              return resource;
            })
            .where(
              (job) => job['id'].toString() != widget.jobOfferId?.toString(),
            )
            .take(3)
            .toList();
        setState(() {
          _similarJobOffers = filtered;
        });
      }
    } catch (e) {
      debugPrint('Error fetching similar job offers: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSimilar = false);
    }
  }

  // --- Reaction infrastructure for similar items ---
  final Map<String, _ReactionData> _reactions = {};
  String _rKey(String s, String id) => '${s}_$id';
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  _ReactionData _getReaction(String s, String id) =>
      _reactions.putIfAbsent(_rKey(s, id), () => _ReactionData());
  void _seedReaction(String s, String id, Map<String, dynamic> r) {
    _reactions.putIfAbsent(
      _rKey(s, id),
      () => _ReactionData(
        likesCount: _asInt(r['likes_count']),
        commentsCount: _asInt(r['comments_count']),
        userReaction: r['user_reaction']?.toString(),
      ),
    );
  }

  Future<void> _toggleReaction(
    String apiSlug,
    String entityId,
    String type,
  ) async {
    final data = _getReaction(apiSlug, entityId);

    // Optimistic update
    final oldReaction = data.userReaction;
    final oldLikes = data.likesCount;

    setState(() {
      if (oldReaction == type) {
        data.userReaction = null;
        if (type == 'like') data.likesCount--;
      } else {
        if (oldReaction == 'like') data.likesCount--;
        data.userReaction = type;
        if (type == 'like') data.likesCount++;
      }
    });

    try {
      final response = await ApiClient().authenticatedPost(
        '/$apiSlug/$entityId/reactions',
        body: {'type': type},
      );
      final respData = response['data'] as Map<String, dynamic>?;
      if (respData != null && mounted) {
        final newReaction = respData['user_reaction']?.toString();
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = newReaction;
        });
        ReactionCacheService.save(apiSlug, entityId, newReaction);
        ReactionCacheService.saveCount(apiSlug, entityId, data.likesCount);
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
      if (mounted) {
        setState(() {
          data.likesCount = oldLikes;
          data.userReaction = oldReaction;
        });
      }
    }
  }

  void _showEntityCommentsSheet(String apiSlug, String entityId) async {
    await _getCurrentUserId();
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    String? error;
    final commentCtrl = TextEditingController();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            // Load on first build
            if (isLoading && comments.isEmpty && error == null) {
              ApiClient()
                  .authenticatedGet('/$apiSlug/$entityId/comments?per_page=50')
                  .then((response) {
                    final data = response['data'];
                    List<Map<String, dynamic>> fetched = [];
                    if (data is Map && data['data'] is List) {
                      fetched = List<Map<String, dynamic>>.from(
                        data['data'] as List,
                      );
                    } else if (data is List) {
                      fetched = List<Map<String, dynamic>>.from(data);
                    }
                    modalSetState(() {
                      comments = fetched;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    modalSetState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  });
            }

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments',
                    body: {'body': text},
                  );
                }
                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = comments.firstWhere(
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
                      comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  // Update local comments count in feed
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
                    ReactionCacheService.saveCommentsCount(
                      apiSlug,
                      entityId,
                      data.commentsCount,
                    );
                  });
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
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            }

            Future<void> toggleCommentReaction(
              Map<String, dynamic> comment,
              String type,
            ) async {
              final commentId = comment['id'];
              try {
                final response = await ApiClient().authenticatedPost(
                  '/comments/$commentId/reactions',
                  body: {'type': type},
                );
                final respData = response['data'] as Map<String, dynamic>?;
                if (respData != null) {
                  modalSetState(() {
                    comment['likes_count'] = respData['likes_count'];
                    comment['user_reaction'] = respData['user_reaction'];
                  });
                }
              } catch (e) {
                debugPrint('Comment reaction error: $e');
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);

              final newText = await showDialog<String>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (newText == null ||
                  newText.trim().isEmpty ||
                  newText == currentBody) {
                return;
              }

              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment =
                    response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  modalSetState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la modification: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(
              Map<String, dynamic> comment,
              bool isReply,
            ) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');

                // Update local comments count in feed
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }

                modalSetState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    comments.removeWhere((c) => c['id'] == commentId);
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Widget buildCommentItem(
              Map<String, dynamic> comment, {
              bool isReply = false,
            }) {
              final user = comment['user'] as Map<String, dynamic>? ?? {};
              final userId = user['id']?.toString(); // Convertir en String
              final email = user['email']?.toString() ?? '';
              final displayName = (userId != null && userId == _currentUserId)
                  ? 'Vous'
                  : (user['display_name']?.toString() ??
                        user['name']?.toString() ??
                        (user['particulier_profile']
                                as Map<String, dynamic>?)?['pseudo']
                            ?.toString() ??
                        (user['pro_profile']
                                as Map<String, dynamic>?)?['company_name']
                            ?.toString() ??
                        email.split('@').first);
              final body = comment['body']?.toString() ?? '';
              final createdAt = comment['created_at']?.toString();
              final likes = _asInt(comment['likes_count']);
              final userReaction = comment['user_reaction']?.toString();
              final isOwner = userId != null && userId == _currentUserId;
              debugPrint("UserId: $userId");
              debugPrint("_currentUserId: $_currentUserId");
              debugPrint("isOwner: $isOwner");
              final replies =
                  (comment['replies'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [];
              // Get avatar URL from user data - check nested profiles
              final particulierProfile =
                  user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl =
                  particulierProfile?['avatar_url']?.toString() ??
                  proProfile?['avatar_url']?.toString() ??
                  proProfile?['logo_url']?.toString() ??
                  user['avatar_url']?.toString();

              return reportableCommentGesture(
                context: context,
                comment: comment,
                currentUserId: _currentUserId,
                child: Padding(
                  padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReklamAvatar(
                            avatarUrl: avatarUrl,
                            displayName: displayName,
                            radius: isReply ? 14 : 18,
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
                                    const SizedBox(width: 8),
                                    Text(
                                      _buildTimeAgo(createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const Spacer(),
                                      GestureDetector(
                                        onTapDown: (TapDownDetails details) {
                                          showMenu<String>(
                                            context: context,
                                            position: RelativeRect.fromLTRB(
                                              details.globalPosition.dx,
                                              details.globalPosition.dy,
                                              details.globalPosition.dx,
                                              details.globalPosition.dy,
                                            ),
                                            items: [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Modifier'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      size: 18,
                                                      color: Colors.redAccent,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Supprimer',
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ).then((value) {
                                            if (value == 'edit') {
                                              editComment(comment);
                                            } else if (value == 'delete') {
                                              deleteComment(comment, isReply);
                                            }
                                          });
                                        },
                                        child: Icon(
                                          Icons.more_horiz,
                                          size: 18,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4F4F4F),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => toggleCommentReaction(
                                        comment,
                                        'like',
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            userReaction == 'like'
                                                ? Icons.thumb_up_alt
                                                : Icons.thumb_up_alt_outlined,
                                            size: 14,
                                            color: userReaction == 'like'
                                                ? const Color(0xFF3AAE5E)
                                                : Colors.grey[400],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$likes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: userReaction == 'like'
                                                  ? const Color(0xFF3AAE5E)
                                                  : Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isReply) ...[
                                      const SizedBox(width: 14),
                                      GestureDetector(
                                        onTap: () {
                                          modalSetState(() {
                                            replyingToId =
                                                comment['id'] as int?;
                                            replyingToName = displayName;
                                          });
                                          FocusScope.of(
                                            ctx,
                                          ).requestFocus(FocusNode());
                                        },
                                        child: Text(
                                          'Répondre',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2E9B5B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Nested replies
                      if (!isReply && replies.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...replies.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: buildCommentItem(r, isReply: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Commentaires',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Comment list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? Center(
                              child: Text(
                                'Erreur: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, i) =>
                                  buildCommentItem(comments[i]),
                            ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Reply indicator
                    if (replyingToId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            Text(
                              'Répondre à $replyingToName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Écrire un commentaire...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => submitComment(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: submitComment,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3AAE5E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }

  Widget _buildReactionBar(String apiSlug, String entityId) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';
    final isBonPlan = apiSlug == 'bon-plans';

    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                size: 18,
                color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => showLikersSheet(context, apiSlug, entityId),
                child: Text(
                  data.likesCount.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[600],
                    fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        // Comments
        GestureDetector(
          onTap: () => _showEntityCommentsSheet(apiSlug, entityId),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.commentsCount.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Bouton partager masqué
      ],
    );
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Handle already complete URLs (both http:// and https://)
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return url;
    }
    // Handle URLs that might incorrectly start with /storage/ followed by http
    if (url.startsWith('/storage/http')) {
      // Extract the actual URL after /storage/
      final actualUrl = url.substring(9); // Remove '/storage/'
      if (actualUrl.toLowerCase().startsWith('http://') ||
          actualUrl.toLowerCase().startsWith('https://')) {
        return actualUrl;
      }
    }
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$serverBase/storage/$cleanUrl';
  }

  /// Like _asInt but returns null instead of 0 for null/invalid values
  int? _tryAsInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME':
        return 'Temps plein';
      case 'PART_TIME':
        return 'Temps partiel';
      case 'INTERIM':
        return 'Intérim';
      case 'FREELANCE':
        return 'Freelance';
      case 'ALTERNANCE':
        return 'Alternance';
      case 'STAGE':
        return 'Stage';
      default:
        return val;
    }
  }

  String _formatJobSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '$min€ - $max€';
    } else if (min != null) {
      return 'À partir de $min€';
    } else if (max != null) {
      return 'Jusqu\'à $max€';
    }
    return 'Salaire non spécifié';
  }

  String? _currentUserId;

  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserId != null) {
      return _currentUserId;
    }
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final data = response['user'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();

      // Sync mys and parrainage_code to UserSession
      if (data != null) {
        final mys = data['mys'];
        final parrainageCode = data['parrainage_code'];
        if (mys != null) {
          UserSession().updateMys(mys);
        }
        if (parrainageCode != null) {
          UserSession().updateParrainageCode(parrainageCode);
        }
      }

      if (mounted) {
        setState(() => _currentUserId = id);
      } else {
        _currentUserId = id;
      }

      // Refresh bottom bar avatar when user data is fetched
      CustomBottomBar.refreshAvatarNotifier.value = true;

      return id;
    } catch (e) {
      debugPrint('Error fetching current user ID: $e');
      return _currentUserId;
    }
  }

  Future<void> _navigateToJobDetail(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir cette offre d\'emploi'),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet('/job-offers/$jobId');
      Navigator.pop(context); // Dismiss loading

      final data = response['data'] as Map<String, dynamic>? ?? response;

      debugPrint('JOB DETAIL API response keys: ${data.keys.toList()}');
      debugPrint(
        'JOB DETAIL description type: ${data['description']?.runtimeType}',
      );
      debugPrint('JOB DETAIL description value: ${data['description']}');
      debugPrint('JOB DETAIL description_delta: ${data['description_delta']}');
      // Check all keys that contain 'desc'
      data.forEach((key, value) {
        if (key.toLowerCase().contains('desc') ||
            key.toLowerCase().contains('delta')) {
          debugPrint(
            'JOB DETAIL key=$key type=${value?.runtimeType} value=$value',
          );
        }
      });

      // Extract job offer details
      final title = data['title']?.toString() ?? '';
      final descriptionRaw = data['description'];
      final description = descriptionRaw?.toString() ?? '';
      final descriptionDelta =
          data['description_delta'] ??
          (descriptionRaw is List ? descriptionRaw : null);
      final profileDescription = data['profile_description']?.toString();
      final companyName = data['company_name']?.toString() ?? 'Entreprise';
      final companyWebsite = data['company_website']?.toString() ?? '';
      final contractTypeRaw = data['contract_type'];
      final contractType = contractTypeRaw is Map
          ? (contractTypeRaw['name'] ?? contractTypeRaw.toString())
          : (contractTypeRaw?.toString() ?? '');
      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map
          ? (workTimeRaw['name'] ?? workTimeRaw.toString())
          : (workTimeRaw?.toString() ?? '');
      final locationRaw = data['location'];
      final location = locationRaw is Map
          ? (locationRaw['city'] ??
                locationRaw['name'] ??
                locationRaw.toString())
          : (locationRaw?.toString() ?? '');
      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString())
          : (categoryRaw?.toString() ?? '');
      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final advantagesRaw = data['advantages'];
      final advantages = advantagesRaw is List
          ? advantagesRaw
                .map(
                  (a) => a is Map ? (a['name'] ?? a.toString()) : a.toString(),
                )
                .toList()
          : <String>[];
      final createdAt = data['created_at']?.toString();
      final mediaRaw =
          data['media'] as List? ?? data['media_files'] as List? ?? [];
      final remoteWork = data['remote_work'] == true;
      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
          : educationLevelRaw?.toString();
      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
          : experienceLevelRaw?.toString();

      // Build images list
      final images = mediaRaw
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString() ?? '') ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      // Build tags
      final tags = <JobDetailTag>[
        if (contractType.isNotEmpty)
          JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime.isNotEmpty)
          JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (educationLevel != null && educationLevel.isNotEmpty)
          JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatJobSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      // Build advantages list
      final advantagesList = advantages
          .take(3)
          .map((a) => a.toString())
          .toList();

      // Check ownership
      final jobUserId =
          job['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          jobUserId != null &&
          currentUserId != null &&
          jobUserId == currentUserId;

      // Get user data and accept_messages
      final user = data['user'] as Map<String, dynamic>?;
      final acceptMessages = data['accept_messages'] == true;

      String companyLogo = '';
      if (user != null) {
        final particulierProfile =
            user['particulier_profile'] is Map<String, dynamic>
            ? user['particulier_profile'] as Map<String, dynamic>
            : null;
        final proProfile = user['pro_profile'] is Map<String, dynamic>
            ? user['pro_profile'] as Map<String, dynamic>
            : null;
        companyLogo =
            (particulierProfile?['avatar_url'] ??
                    proProfile?['avatar_url'] ??
                    proProfile?['logo_url'])
                ?.toString() ??
            '';
      }

      final resolvedCompanyLogo =
          _buildStorageUrl(companyLogo) ??
          'assets/images/dashboard_particulier/Rectangle 13.png';

      // Navigate to detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo: companyLogo,
            companyName: companyName,
            companyWebsite: companyWebsite,
            jobTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            profileDescription: profileDescription,
            tags: tags,
            postTags: <PostTag>[
              if (workTime.isNotEmpty)
                PostTag(
                  title: workTime,
                  icon: Icons.access_time,
                  color: Colors.grey,
                ),
            ],
            subtags: contractType.isNotEmpty
                ? PostTag(
                    title: contractType,
                    icon: Icons.description_outlined,
                    color: const Color(0xFF27A5FF),
                  )
                : null,
            advantages: advantagesList,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            location: location,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobId,
            jobOfferData: data,
            acceptMessages: acceptMessages,
            authorData: user,
            commentsCount: _tryAsInt(data['comments_count']),
          ),
        ),
      );
      // Refresh feed when returning from detail (to update comment counts, etc.)
    } catch (e) {
      Navigator.pop(context); // Dismiss loading
      debugPrint('Error fetching job offer detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }

  Widget _buildSimilarJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location =
        job['location']?.toString() ??
        job['city']?.toString() ??
        'Non spécifié';
    final contract = job['contract_type']?.toString() ?? '';
    final experience = job['experience_level']?.toString() ?? '';
    final salary =
        job['salary_label']?.toString() ??
        _buildJobSalaryDisplay(job) ??
        job['salary']?.toString();

    // Check initial favorite status
    final favoris = job['job_offer_favorites'] as List? ?? [];
    final bool initialIsFavorited = favoris.isNotEmpty;

    // Use ValueNotifier for state that persists across rebuilds
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    final tags = <JobDetailTag>[
      // 1st: Place (location)
      if (location.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: location),
      // 2nd: Contract duration
      if (contract.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contract),
      // 3rd: Salary (depending on type)
      if (salary != null && salary.isNotEmpty)
        JobDetailTag(icon: Icons.euro, text: salary, isSpecial: true),
    ];

    final user = job['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    // Extract display name: company_name for pros, pseudo for particuliers
    final String companyName =
        proProfile?['company_name']?.toString() ??
        particulierProfile?['pseudo']?.toString() ??
        job['company_name']?.toString() ??
        'Entreprise';

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final companyLogoUrl =
        _buildStorageUrl(avatarUrl) ??
        'assets/images/dashboard_particulier/Rectangle 13.png';

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoading = false;

        Future<void> toggleFavorite() async {
          if (isLoading || jobId.isEmpty) return;

          // Toggle immediately for responsive UI
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => isLoading = true);

          try {
            if (!isFavoritedNotifier.value) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (job['job_offer_favorites'] is List) {
                (job['job_offer_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == UserSession().id ||
                          f['user']?['id']?.toString() == UserSession().id),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/job-offers/$jobId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (job['job_offer_favorites'] is! List) {
                job['job_offer_favorites'] = [];
              }
              (job['job_offer_favorites'] as List).add({
                'user_id': UserSession().id,
                'user': {'id': UserSession().id},
              });
            }

            setState(() {
              isLoading = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavoritedNotifier.value
                        ? 'Ajouté aux favoris'
                        : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return JobAnnouncementCard(
          companyLogo: companyLogoUrl,
          companyName: companyName,
          jobTitle: jobTitle,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          tags: tags,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: isLoading,
          onFavoriteToggle: toggleFavorite,
          onApply: () => _navigateToJobDetail(job),
          onReport: canReportResource(job)
              ? () => showAnnouncementReportDialog(
                  context: context,
                  entityType: 'job-offers',
                  entityId: jobId,
                  title: jobTitle,
                )
              : null,
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isProUser
                      ? ProPublicViewScreen(userId: user!['id'].toString())
                      : ParticulierPublicViewScreen(
                          userId: user!['id'].toString(),
                        ),
                ),
              );
            }
          },
          reactionBar: jobId.isNotEmpty
              ? Builder(
                  builder: (ctx) {
                    _seedReaction('job-offers', jobId, job);
                    return _buildReactionBar('job-offers', jobId);
                  },
                )
              : null,
        );
      },
    );
  }

  String? _buildJobSalaryDisplay(Map<String, dynamic> job) {
    final min = job['salary_min'];
    final max = job['salary_max'];
    final exact = job['salary_exact'];
    final paymentType = job['salary_payment_type']?.toString();
    final period = job['salary_period']?.toString();

    String periodLabel = '';
    if (period == 'horaire') {
      periodLabel = '/h';
    } else if (period == 'mensuel')
      periodLabel = '/mois';
    else if (period == 'annuel')
      periodLabel = '/an';

    String paymentLabel = paymentType == 'brut'
        ? ' brut'
        : (paymentType == 'net' ? ' net' : '');

    if (min != null && max != null) {
      return '$min€ - $max€$periodLabel$paymentLabel';
    }

    if (exact != null) {
      return '$exact€$periodLabel$paymentLabel';
    }

    if (min != null) {
      return 'À partir de $min€$periodLabel$paymentLabel';
    }

    if (max != null) {
      return 'Jusqu\'à $max€$periodLabel$paymentLabel';
    }

    final salaryType = job['salary_type']?.toString();
    if (salaryType == 'selon_profil') {
      return 'Selon profil';
    }

    return null;
  }

  String _buildTimeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Posté récemment';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 365) {
        final years = (diff.inDays / 365).floor();
        return 'il y a $years an${years > 1 ? 's' : ''}';
      } else if (diff.inDays > 30) {
        final months = (diff.inDays / 30).floor();
        return 'il y a $months mois';
      } else if (diff.inDays > 0) {
        return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'il y a ${diff.inHours}h';
      } else if (diff.inMinutes > 0) {
        return 'il y a ${diff.inMinutes}min';
      } else {
        return 'À l\'instant';
      }
    } catch (_) {
      return 'Posté récemment';
    }
  }

  void _navigateToSimilarJobDetail(Map<String, dynamic> job) {
    final jobId = job['id']?.toString();
    if (jobId == null || jobId.isEmpty) return;

    final user = job['user'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;

    final avatarUrl =
        proProfile?['logo_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        particulierProfile?['avatar_url']?.toString() ??
        user?['avatar']?.toString();

    final companyLogo =
        ApiConfig.resolveMediaUrl(avatarUrl) ??
        'assets/images/dashboard_particulier/Rectangle 13.png';

    final companyName =
        proProfile?['company_name']?.toString() ??
        user?['name']?.toString() ??
        'Entreprise';

    final jobTitle = job['title']?.toString() ?? 'Offre d\'emploi';
    final description = _stripHtml(job['description']?.toString() ?? '');
    final location =
        job['location']?.toString() ?? job['city']?.toString() ?? '';
    final contract = job['contract_type']?.toString() ?? '';
    final experience = job['experience_level']?.toString() ?? '';
    final education = job['education_level']?.toString() ?? '';
    final remoteWork = job['remote_work'] == true;
    final salary =
        job['salary_label']?.toString() ??
        _buildJobSalaryDisplay(job) ??
        job['salary']?.toString() ??
        '';
    final acceptMessages = job['accept_messages'] == true;

    final tags = <JobDetailTag>[
      if (location.isNotEmpty)
        JobDetailTag(icon: Icons.location_on_outlined, text: location),
      if (contract.isNotEmpty)
        JobDetailTag(icon: Icons.description_outlined, text: contract),
      if (experience.isNotEmpty)
        JobDetailTag(icon: Icons.work_history_outlined, text: experience),
      if (education.isNotEmpty)
        JobDetailTag(icon: Icons.school_outlined, text: education),
      if (salary.isNotEmpty)
        JobDetailTag(icon: Icons.euro, text: salary, isSpecial: true),
    ];

    // Extract media files
    final mediaFiles = <String>[];
    final media = job['media'] ?? job['media_files'];
    if (media is List) {
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          final url = item['url']?.toString();
          if (url != null && url.isNotEmpty) {
            if (url.startsWith('http')) {
              mediaFiles.add(url);
            } else {
              mediaFiles.add(
                "${ApiConfig.baseUrl.replaceFirst('/api', '')}$url",
              );
            }
          }
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(
          companyLogo: companyLogo,
          companyName: companyName,
          companyWebsite: proProfile?['company_website']?.toString() ?? '',
          jobTitle: jobTitle,
          description: description,
          descriptionDelta: job['description_delta'],
          tags: tags,
          jobOfferId: jobId,
          jobOfferData: job,
          timeAgo: _buildTimeAgo(job['created_at']?.toString()),
          isOwner: false,
          acceptMessages: acceptMessages,
          authorData: user,
          images: mediaFiles,
          location: location,
          educationLevel: education.isNotEmpty ? education : null,
          experienceLevel: experience.isNotEmpty ? experience : null,
          remoteWork: remoteWork,
          profileDescription: job['profile_description']?.toString(),
          advantages: job['advantages'] is List
              ? List<String>.from(job['advantages'] as List)
              : const [],
        ),
      ),
    );
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
        setState(() => _hasApplied = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF3AAE5E),
          ),
        );

        // Award 1 My for applying to job and show modal
        try {
          final mysResponse = await MysEarningService().awardMys(
            actionType: 'job_application',
            referenceId: widget.jobOfferId?.toString(),
          );
          if (mysResponse['success'] == true && context.mounted) {
            final newBalance = mysResponse['earning']?['new_balance'];
            if (newBalance != null) {
              UserSession().updateMys(newBalance);
            }
            final amount = mysResponse['earning']?['amount'] ?? 1;
            await MysRewardModal.show(
              context,
              amount: amount,
              actionType: 'job_application',
            );
          }
        } catch (e) {
          debugPrint("Error awarding My's for job application: $e");
        }
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

    void showApplyDialog() {
      if (widget.jobOfferId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Offre invalide.')));
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirmer la candidature',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job details preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // if (widget.companyLogo.isNotEmpty)
                          //   ClipRRect(
                          //     borderRadius: BorderRadius.circular(8),
                          //     child: Image.network(
                          //       widget.companyLogo,
                          //       width: 40,
                          //       height: 40,
                          //       fit: BoxFit.cover,
                          //       errorBuilder: (_, __, ___) => Container(
                          //         width: 40,
                          //         height: 40,
                          //         color: Colors.grey[300],
                          //         child: Icon(
                          //           Icons.business,
                          //           size: 20,
                          //           color: Colors.grey[600],
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          // const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.jobTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.companyName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Voulez-vous postuler à cette offre d\'emploi ?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre profil sera envoyé au recruteur.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _isLoadingApply
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await applyToJobOffer();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: _isLoadingApply
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Postuler'),
              ),
            ],
          );
        },
      );
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
          'Details de l\'offre',
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
                  if (_canEdit &&
                      DelegationManager.instance.can(
                        DelegationPermission.announcements,
                      ))
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
                  if (DelegationManager.instance.can(
                    DelegationPermission.announcements,
                  ))
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Carousel - full width
            if (widget.images.isNotEmpty) ImageCarousel(images: widget.images),

            // 2. Main content section - no card, edge to edge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  if (widget.jobOfferData != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Category tag
                        if (widget.jobOfferData!['category'] != null)
                          _buildTag(
                            widget.jobOfferData!['category'] is Map
                                ? widget.jobOfferData!['category']['name']
                                          ?.toString() ??
                                      'Offre d\'emploi'
                                : widget.jobOfferData!['category']
                                          ?.toString() ??
                                      'Offre d\'emploi',
                            Icons.work_outline,
                            const Color(0xFF3AAE5E),
                          ),
                        // Contract type tag
                        if (widget.jobOfferData!['contract_type'] != null)
                          _buildTag(
                            widget.jobOfferData!['contract_type']?.toString() ??
                                '',
                            Icons.description_outlined,
                            Colors.blue,
                          ),
                      ],
                    ),
                  if (widget.jobOfferData != null) const SizedBox(height: 12),

                  // Title - big and bold
                  Text(
                    widget.jobTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags (location, contract, etc.) - GRAY TAGS
                  // Sort to put location first
                  if (widget.tags.isNotEmpty) ...[
                    Builder(
                      builder: (context) {
                        final sortedTags = List<JobDetailTag>.from(widget.tags)
                          ..sort((a, b) {
                            // Location tag comes first
                            final aIsLocation =
                                a.icon == Icons.location_on_outlined ||
                                a.icon == Icons.location_on;
                            final bIsLocation =
                                b.icon == Icons.location_on_outlined ||
                                b.icon == Icons.location_on;
                            if (aIsLocation && !bIsLocation) return -1;
                            if (!aIsLocation && bIsLocation) return 1;
                            return 0;
                          });
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sortedTags
                              .map((tag) => _buildDetailTag(tag))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Salary in green - BELOW GRAY TAGS
                  _buildSalaryDisplay(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Description - no card, full width
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Job details section - no card, full width
            if (widget.educationLevel != null ||
                widget.experienceLevel != null ||
                widget.remoteWork ||
                widget.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profil recherché',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.educationLevel != null)
                      _buildDetailItem(
                        icon: Icons.school_outlined,
                        iconColor: Colors.orange,
                        bgColor: Colors.orange.withValues(alpha: 0.1),
                        label: 'Niveau d\'études',
                        value: widget.educationLevel!,
                      ),
                    if (widget.educationLevel != null)
                      const SizedBox(height: 12),
                    if (widget.experienceLevel != null)
                      _buildDetailItem(
                        icon: Icons.work_history_outlined,
                        iconColor: const Color(0xFF3AAE5E),
                        bgColor: const Color(0xFFE6F7EF),
                        label: 'Expérience requise',
                        value: widget.experienceLevel!,
                      ),
                    if (widget.experienceLevel != null)
                      const SizedBox(height: 12),
                    if (widget.remoteWork)
                      _buildDetailItem(
                        icon: Icons.home_work_outlined,
                        iconColor: Colors.blue,
                        bgColor: Colors.blue.withValues(alpha: 0.1),
                        label: 'Télétravail',
                        value: 'Possible',
                      ),
                    if (widget.remoteWork) const SizedBox(height: 5),
                  ],
                ),
              ),

            // Profil recherché section - no card, full width (like Description)
            if (widget.profileDescription != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      widget.profileDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.profileDescription != null) const SizedBox(height: 16),

            // 6. Avantages - no card
            if (widget.advantages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avantages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.advantages
                          .map((adv) => _buildAdvantageTag(adv))
                          .toList(),
                    ),
                  ],
                ),
              ),
            if (widget.advantages.isNotEmpty) const SizedBox(height: 16),

            // 7. Apply buttons - full width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (!widget.isOwner) ...[
                    Expanded(
                      flex: widget.applyButtonFlex,
                      child: ElevatedButton(
                        onPressed: _hasApplied ? null : showApplyDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasApplied
                              ? Colors.grey
                              : const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _hasApplied
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'postulé',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Postuler',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Favoris, Partager, Owner section - moved above Contacter button
            // Action buttons row (Share button commented out)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Favoris button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: _isLoadingFavorite
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: _isFavorite
                                  ? Colors.red
                                  : Colors.grey[600],
                              size: 24,
                            ),
                    ),
                    Text(
                      'Favoris',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // Bouton partager masqué
                //         color: Colors.grey[600],
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
            const SizedBox(height: 16),

            // Company/Owner section - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Avatar
                  ReklamAvatar(
                    avatarUrl: widget.companyLogo,
                    displayName: widget.companyName,
                    radius: 24,
                    accountType: 'pro',
                    onTap: widget.authorData != null
                        ? () => _navigateToUserProfile(context)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name and user type
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.authorData != null
                          ? () => _navigateToUserProfile(context)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.companyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subscribe/Follow button
                  if (!widget.isOwner)
                    _isLoadingFollow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _toggleFollow,
                            style: TextButton.styleFrom(
                              foregroundColor: _isFollowing
                                  ? Colors.grey[600]
                                  : const Color(0xFF3AAE5E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _isFollowing
                                      ? Colors.grey[400]!
                                      : const Color(0xFF3AAE5E),
                                ),
                              ),
                            ),
                            child: Text(
                              _isFollowing ? 'Suivis' : 'Suivre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Posted time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.timeAgo.isNotEmpty ? widget.timeAgo : 'Posté récemment',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),

            // Contact button - only if not owner and acceptMessages is true
            if (!widget.isOwner &&
                widget.acceptMessages &&
                widget.authorData != null &&
                DelegationManager.instance.can(DelegationPermission.messages))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startConversation(
                      context,
                      widget.authorData!,
                      annonceData: {
                        'annonce_type': 'Offre d\'emploi',
                        'annonce_id': widget.jobOfferId ?? '',
                        'title': widget.jobTitle,
                        'description': widget.description,
                        'image_url': widget.images.isNotEmpty
                            ? widget.images.first
                            : '',
                        'author_name': widget.companyName,
                      },
                    ),
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

            // Localisation - no card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Localisation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocationMap(
                    query:
                        AddressFormatter.query(
                          postalCode: widget.locationPostalCode,
                          city: widget.locationCity,
                        ).isNotEmpty
                        ? AddressFormatter.query(
                            postalCode: widget.locationPostalCode,
                            city: widget.locationCity,
                          )
                        : widget.location,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AddressFormatter.format(
                          postalCode: widget.locationPostalCode,
                          city: widget.locationCity,
                        ).isNotEmpty
                        ? AddressFormatter.format(
                            postalCode: widget.locationPostalCode,
                            city: widget.locationCity,
                          )
                        : (widget.location.isNotEmpty
                              ? widget.location
                              : 'Localisation non spécifiée'),
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

            // Comments Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                        '${_localCommentsCount ?? _comments.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                  else if (_comments.isEmpty &&
                      (_localCommentsCount == null || _localCommentsCount == 0))
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
                      onPressed: () => SubscriptionHelper.guardFeature(
                        context,
                        ProFeature.commentAndReact,
                        () => _showCommentsSheet(context),
                        featureName: 'Commenter',
                      ),
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
                "Autres offres d'emplois qui pourraient vous intéresser",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(height: 1, color: Colors.grey[300]),
            ),

            // Similar job offers - dynamically fetched
            if (_isLoadingSimilar)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_similarJobOffers.isEmpty)
              const SizedBox.shrink()
            else
              ..._similarJobOffers.map((job) => _buildSimilarJobCard(job)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Bouton partager masqué
  // void _shareJob() { ... }

  static Future<void> _startConversation(
    BuildContext context,
    Map<String, dynamic> authorData, {
    Map<String, dynamic>? annonceData,
  }) async {
    // Check subscription for pro users
    if (!SubscriptionHelper.canAccessFeature(ProFeature.messaging)) {
      if (context.mounted) {
        SubscriptionHelper.showPremiumRequiredDialog(
          context,
          featureName: 'Messagerie',
        );
      }
      return;
    }

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

      final conversation = await ConversationService().getOrCreateConversation(
        authorId,
      );
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            conversationId: conversation.id.toString(),
            name:
                authorData['display_name']?.toString() ??
                authorData['name']?.toString() ??
                'Utilisateur',
            avatar:
                authorData['avatar_url']?.toString() ??
                authorData['avatar']?.toString(),
            linkedAnnonce: annonceData,
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
    // First try plain text description (HTML stripped)
    if (widget.description.isNotEmpty &&
        widget.description != 'Description non disponible.') {
      return Text(
        _stripHtml(widget.description),
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
      );
    }

    // Fallback to rich text delta if plain text is empty
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
            RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s]*?)(\s*[\}\]])'),
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
      'Description non disponible.',
      style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
    );
  }

  String _stripHtml(String text) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return text.replaceAll(exp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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
        border: Border.all(
          color: const Color(0xFF3AAE5E).withValues(alpha: 0.5),
        ),
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

  // Helper methods for new layout
  Widget _buildTag(String text, IconData icon, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryDisplay() {
    // Extract salary from tags or jobOfferData
    String? salaryText;

    // First check tags for salary info
    for (final tag in widget.tags) {
      if (tag.icon == Icons.euro ||
          tag.icon == Icons.monetization_on_outlined ||
          tag.icon == Icons.monetization_on) {
        salaryText = tag.text;
        break;
      }
    }

    // If no salary in tags, check jobOfferData
    if (salaryText == null && widget.jobOfferData != null) {
      final salary = widget.jobOfferData!['salary'];
      final salaryLabel = widget.jobOfferData!['salary_label'];
      final salaryMin = widget.jobOfferData!['salary_min'];
      final salaryMax = widget.jobOfferData!['salary_max'];
      final salaryExact = widget.jobOfferData!['salary_exact'];
      final salaryType = widget.jobOfferData!['salary_type']?.toString();
      final paymentType = widget.jobOfferData!['salary_payment_type']
          ?.toString(); // brut/net
      final period = widget.jobOfferData!['salary_period']
          ?.toString(); // horaire/mensuel/annuel

      // Build period label
      String periodLabel = '';
      if (period == 'horaire') {
        periodLabel = '/h';
      } else if (period == 'mensuel')
        periodLabel = '/mois';
      else if (period == 'annuel')
        periodLabel = '/an';

      // Build payment label (brut/net)
      String paymentLabel = paymentType == 'brut'
          ? ' brut'
          : (paymentType == 'net' ? ' net' : '');

      // Handle different salary types
      if (salaryType == 'selon_profil') {
        salaryText = 'Selon profil';
      } else if (salaryMin != null && salaryMax != null) {
        salaryText = '$salaryMin€ - $salaryMax€$periodLabel$paymentLabel';
      } else if (salaryExact != null) {
        salaryText = '$salaryExact€$periodLabel$paymentLabel';
      } else if (salaryLabel != null && salaryLabel.toString().isNotEmpty) {
        // Clean up salaryLabel if it contains JSON
        final labelStr = salaryLabel.toString();
        if (labelStr.startsWith('{') || labelStr.startsWith('[')) {
          // Try to parse as JSON and extract meaningful data
          try {
            final decoded = jsonDecode(labelStr);
            if (decoded is Map) {
              if (decoded['min'] != null && decoded['max'] != null) {
                salaryText =
                    '${decoded['min']}€ - ${decoded['max']}€$periodLabel$paymentLabel';
              } else if (decoded['amount'] != null) {
                salaryText = '${decoded['amount']}€$periodLabel$paymentLabel';
              } else if (decoded['text'] != null) {
                salaryText = decoded['text'].toString();
              } else {
                salaryText = 'Selon profil';
              }
            } else {
              salaryText = 'Selon profil';
            }
          } catch (_) {
            salaryText = 'Selon profil';
          }
        } else {
          salaryText = labelStr;
        }
      } else if (salary != null) {
        // Handle salary that might be a Map/JSON
        if (salary is Map) {
          if (salary['min'] != null && salary['max'] != null) {
            salaryText =
                '${salary['min']}€ - ${salary['max']}€$periodLabel$paymentLabel';
          } else if (salary['amount'] != null) {
            salaryText = '${salary['amount']}€$periodLabel$paymentLabel';
          } else if (salary['text'] != null) {
            salaryText = salary['text'].toString();
          } else {
            salaryText = 'Selon profil';
          }
        } else {
          final salaryStr = salary.toString();
          if (salaryStr.startsWith('{') || salaryStr.startsWith('[')) {
            try {
              final decoded = jsonDecode(salaryStr);
              if (decoded is Map) {
                if (decoded['min'] != null && decoded['max'] != null) {
                  salaryText =
                      '${decoded['min']}€ - ${decoded['max']}€$periodLabel$paymentLabel';
                } else if (decoded['amount'] != null) {
                  salaryText = '${decoded['amount']}€$periodLabel$paymentLabel';
                } else {
                  salaryText = 'Selon profil';
                }
              } else {
                salaryText = 'Selon profil';
              }
            } catch (_) {
              salaryText = 'Selon profil';
            }
          } else {
            salaryText = salaryStr + periodLabel + paymentLabel;
          }
        }
      }
    }

    if (salaryText == null || salaryText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      salaryText,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E9B5B),
      ),
    );
  }

  Widget _buildDetailTag(JobDetailTag tag) {
    final isSpecial = tag.isSpecial;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSpecial ? const Color(0xFFE6F7EF) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpecial
              ? const Color(0xFF3AAE5E).withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: TextStyle(
              fontSize: 12,
              color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
              fontWeight: isSpecial ? FontWeight.bold : FontWeight.w500,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context) {
    if (widget.authorData == null) return;

    final userId = widget.authorData!['id']?.toString();
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticulierMainScreen(initialIndex: 3),
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
