import 'package:dio/dio.dart';
import '../api/api_service.dart';
import 'package:logger/logger.dart';

class ModerationService {
  final ApiService _apiService;
  static final _logger = Logger();

  ModerationService({required ApiService apiService})
    : _apiService = apiService;

  // User flags content for review
  Future<Map<String, dynamic>> flagContent({
    required String contentType, // 'course', 'lesson', 'comment', 'user'
    required int contentId,
    required String
    reason, // 'spam', 'inappropriate', 'misleading', 'copyright', 'other'
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        '/moderation/flag',
        data: {
          'content_type': contentType,
          'content_id': contentId,
          'reason': reason,
          'description': description,
        },
      );

      _logger.i('Content flagged: $contentId');
      return response.data;
    } catch (e) {
      _logger.e('Error flagging content: $e');
      rethrow;
    }
  }

  // Get user's submitted flags
  Future<Map<String, dynamic>> getMyFlags({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/moderation/my-flags',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      _logger.i('Retrieved user flags');
      return response.data;
    } catch (e) {
      _logger.e('Error getting user flags: $e');
      rethrow;
    }
  }

  // ADMIN: Get all flagged content for review
  Future<Map<String, dynamic>> getAdminFlags({
    String status = 'pending', // 'pending', 'approved', 'rejected', 'all'
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/moderation/admin/flags',
        queryParameters: {'status': status, 'limit': limit, 'offset': offset},
      );

      _logger.i('Retrieved admin flags');
      return response.data;
    } catch (e) {
      _logger.e('Error getting admin flags: $e');
      rethrow;
    }
  }

  // ADMIN: Resolve flag (approve/reject)
  Future<Map<String, dynamic>> resolveFlag({
    required int flagId,
    required String action, // 'approved' or 'rejected'
    String? resolutionNote,
  }) async {
    try {
      final response = await _apiService.put(
        '/moderation/admin/flags/$flagId',
        data: {'action': action, 'resolution_note': resolutionNote},
      );

      _logger.i('Flag resolved: $flagId -> $action');
      return response.data;
    } catch (e) {
      _logger.e('Error resolving flag: $e');
      rethrow;
    }
  }

  // ADMIN: Get moderation statistics
  Future<Map<String, dynamic>> getModerationStats() async {
    try {
      final response = await _apiService.get('/moderation/admin/stats');

      _logger.i('Retrieved moderation statistics');
      return response.data;
    } catch (e) {
      _logger.e('Error getting moderation stats: $e');
      rethrow;
    }
  }
}
