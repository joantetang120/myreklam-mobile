import 'package:myreklam/services/api_client.dart';

class CommentReportService {
  static final CommentReportService _instance = CommentReportService._internal();
  factory CommentReportService() => _instance;
  CommentReportService._internal();

  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> reportComment({
    required String commentId,
    required String reason,
  }) async {
    return await _api.authenticatedPost(
      '/comments/$commentId/report',
      body: {'reason': reason.trim()},
    );
  }
}
