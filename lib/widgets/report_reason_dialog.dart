import 'package:flutter/material.dart';
import 'package:myreklam/services/announcement_report_service.dart';
import 'package:myreklam/services/api_client.dart';
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
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
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
