import 'package:myreklam/services/api_client.dart';

class AnnouncementReportService {
  static final AnnouncementReportService _instance =
      AnnouncementReportService._internal();
  factory AnnouncementReportService() => _instance;
  AnnouncementReportService._internal();

  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> reportAnnouncement({
    required String entityType,
    required String entityId,
    required String reason,
  }) async {
    return await _api.authenticatedPost(
      '/$entityType/$entityId/report',
      body: {'reason': reason.trim()},
    );
  }
}
