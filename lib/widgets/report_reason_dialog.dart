import 'package:flutter/material.dart';
import 'package:myreklam/services/announcement_report_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/comment_report_service.dart';
import 'package:myreklam/utils/user_session.dart';

String? ownerIdFromResource(Map<String, dynamic> item) {
  final user = item['user'];
  return (user is Map ? user['id']?.toString() : null) ??
      item['user_id']?.toString() ??
      item['owner_id']?.toString() ??
      item['userid']?.toString() ??
      item['userId']?.toString() ??
      item['author_id']?.toString();
}

bool canReportResource(Map<String, dynamic> item) {
  final ownerId = ownerIdFromResource(item);
  final currentUserId = UserSession().id?.toString();
  return ownerId != null &&
      ownerId.isNotEmpty &&
      currentUserId != null &&
      currentUserId.isNotEmpty &&
      ownerId != currentUserId;
}

String? ownerIdFromComment(Map<String, dynamic> comment) {
  final user = comment['user'];
  return (user is Map ? user['id']?.toString() : null) ??
      comment['user_id']?.toString() ??
      comment['userid']?.toString() ??
      comment['userId']?.toString() ??
      comment['author_id']?.toString();
}

bool canReportComment(Map<String, dynamic> comment, {String? currentUserId}) {
  final ownerId = ownerIdFromComment(comment);
  final sessionUserId = currentUserId ?? UserSession().id?.toString();
  return ownerId != null &&
      ownerId.isNotEmpty &&
      sessionUserId != null &&
      sessionUserId.isNotEmpty &&
      ownerId != sessionUserId;
}

Widget reportableCommentGesture({
  required BuildContext context,
  required Map<String, dynamic> comment,
  required Widget child,
  String? currentUserId,
}) {
  return GestureDetector(
    onLongPress: canReportComment(comment, currentUserId: currentUserId)
        ? () => showCommentReportActionSheet(
            context: context,
            comment: comment,
            currentUserId: currentUserId,
          )
        : null,
    child: child,
  );
}

Future<void> showCommentReportActionSheet({
  required BuildContext context,
  required Map<String, dynamic> comment,
  String? currentUserId,
}) async {
  if (!canReportComment(comment, currentUserId: currentUserId)) {
    return;
  }

  final commentId = comment['id']?.toString() ?? '';
  if (commentId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'identifier ce commentaire.')),
    );
    return;
  }

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
            title: const Text(
              'Signaler ce commentaire',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, 'report'),
          ),
          ListTile(
            leading: Icon(Icons.close, color: Colors.grey[600]),
            title: Text('Annuler', style: TextStyle(color: Colors.grey[700])),
            onTap: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    ),
  );

  if (action == 'report' && context.mounted) {
    await showCommentReportDialog(context: context, commentId: commentId);
  }
}

Future<void> showCommentReportDialog({
  required BuildContext context,
  required String commentId,
}) async {
  final reasonController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      String? reasonError;
      bool isSubmitting = false;

      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Signaler le commentaire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pourquoi voulez-vous signaler ce commentaire ?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Expliquez la raison du signalement...',
                  errorText: reasonError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.length < 10) {
                        setDialogState(() {
                          reasonError =
                              'Veuillez saisir au moins 10 caracteres.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        reasonError = null;
                      });

                      try {
                        await CommentReportService().reportComment(
                          commentId: commentId,
                          reason: reason,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signalement envoye'),
                            backgroundColor: Color(0xFF3AAE5E),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setDialogState(() {
                          isSubmitting = false;
                          reasonError = e is ApiException
                              ? e.firstError
                              : 'Impossible d\'envoyer le signalement.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Signaler',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      );
    },
  );

  reasonController.dispose();
}

Future<void> showAnnouncementReportDialog({
  required BuildContext context,
  required String entityType,
  required String entityId,
  required String title,
}) async {
  if (entityId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'identifier cette annonce.')),
    );
    return;
  }

  final reasonController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      String? reasonError;
      bool isSubmitting = false;

      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Signaler l\'annonce'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pourquoi voulez-vous signaler "$title" ?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Expliquez la raison du signalement...',
                  errorText: reasonError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.length < 10) {
                        setDialogState(() {
                          reasonError =
                              'Veuillez saisir au moins 10 caracteres.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        reasonError = null;
                      });

                      try {
                        await AnnouncementReportService().reportAnnouncement(
                          entityType: entityType,
                          entityId: entityId,
                          reason: reason,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signalement envoye'),
                            backgroundColor: Color(0xFF3AAE5E),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        setDialogState(() {
                          isSubmitting = false;
                          reasonError = e is ApiException
                              ? e.firstError
                              : 'Impossible d\'envoyer le signalement.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Signaler',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      );
    },
  );

  reasonController.dispose();
}
