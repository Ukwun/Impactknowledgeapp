import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import 'package:logger/logger.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger logger = Logger();

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        contentType: 'application/json',
      ),
    );

    logger.i('=== API SERVICE INITIALIZED ===');
    logger.i('Base URL: ${AppConfig.apiBaseUrl}');
    logger.i('Timeout: ${AppConfig.apiTimeout}');

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authorization token
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final fullUrl = '${options.baseUrl}${options.path}';
          logger.i('→ REQUEST: ${options.method} $fullUrl');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i(
            '← RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          logger.e('✗ ERROR [${error.type}]: ${error.message}');
          logger.e('   URI: ${error.requestOptions.uri}');
          return handler.next(error);
        },
      ),
    );
  }

  String _normalizeEndpoint(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }

    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    if (normalized.startsWith('/api/')) {
      return normalized;
    }

    if (normalized == '/health') {
      return normalized;
    }

    return '/api$normalized';
  }

  // Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        _normalizeEndpoint(endpoint),
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } catch (e) {
      logger.e('GET Error: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<T> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        _normalizeEndpoint(endpoint),
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } catch (e) {
      logger.e('POST Error: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<T> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        _normalizeEndpoint(endpoint),
        data: data,
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } catch (e) {
      logger.e('PUT Error: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        _normalizeEndpoint(endpoint),
        queryParameters: queryParameters,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } catch (e) {
      logger.e('DELETE Error: $e');
      rethrow;
    }
  }

  // File upload
  Future<T> uploadFile<T>(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        _normalizeEndpoint(endpoint),
        data: formData,
      );

      if (fromJson != null) {
        return fromJson(response.data);
      }
      return response.data as T;
    } catch (e) {
      logger.e('Upload Error: $e');
      rethrow;
    }
  }

  // ==================== QUIZ ENDPOINTS ====================
  Future<dynamic> getQuizzes(String courseId) async {
    try {
      return await get('quizzes', queryParameters: {'courseId': courseId});
    } catch (e) {
      logger.e('Error fetching quizzes: $e');
      return [];
    }
  }

  Future<dynamic> getQuizDetail(String quizId) async {
    try {
      return await get('quizzes/$quizId');
    } catch (e) {
      logger.e('Error fetching quiz detail: $e');
      return {};
    }
  }

  Future<dynamic> getQuizQuestions(String quizId) async {
    try {
      final response = await get('quizzes/$quizId');
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          return (response['data']['questions'] as List?) ?? [];
        }
        return response['questions'] ?? [];
      }
      return [];
    } catch (e) {
      logger.e('Error fetching quiz questions: $e');
      return [];
    }
  }

  Future<dynamic> startQuizAttempt(String quizId) async {
    try {
      return {'id': quizId, 'status': 'started'};
    } catch (e) {
      logger.e('Error starting quiz attempt: $e');
      return {'attemptId': '', 'status': 'error'};
    }
  }

  Future<dynamic> submitQuizAttempt(
    String attemptId,
    Map<String, dynamic> answers,
  ) async {
    try {
      final formattedAnswers = answers.entries
          .map((entry) {
            final key = entry.key.replaceFirst('q_', '');
            final questionId = int.tryParse(key);
            if (questionId == null) return null;
            return {'questionId': questionId, 'selectedAnswerId': entry.value};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      return await post(
        'quizzes/$attemptId/attempts',
        data: {'answers': formattedAnswers},
      );
    } catch (e) {
      logger.e('Error submitting quiz: $e');
      return {'score': 0, 'passed': false};
    }
  }

  Future<Map<String, dynamic>?> getQuizAttemptDetail(String attemptId) async {
    try {
      final response = await get('quizzes/$attemptId/attempts');
      return response as Map<String, dynamic>?;
    } catch (e) {
      logger.e('Error fetching attempt detail: $e');
      return null;
    }
  }

  Future<dynamic> getLeaderboard(String quizId, {int limit = 100}) async {
    try {
      return await get('leaderboard', queryParameters: {'limit': limit});
    } catch (e) {
      logger.e('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ==================== ASSIGNMENT ENDPOINTS ====================
  Future<dynamic> getAssignments(String courseId) async {
    try {
      return await get('assignments', queryParameters: {'courseId': courseId});
    } catch (e) {
      logger.e('Error fetching assignments: $e');
      return [];
    }
  }

  /// All pending/due assignments for the authenticated user across every enrolled course.
  Future<dynamic> getMyAssignments() async {
    try {
      return await get('assignments');
    } catch (e) {
      logger.e('Error fetching my assignments: $e');
      return [];
    }
  }

  Future<dynamic> getMyQuizzes(List<String> courseIds) async {
    try {
      if (courseIds.isEmpty) return [];
      final results = await Future.wait(
        courseIds.take(5).map((id) => getQuizzes(id)).toList(),
      );
      final flat = <Map<String, dynamic>>[];
      for (final r in results) {
        if (r is List) flat.addAll(r.cast<Map<String, dynamic>>());
        if (r is Map && r['data'] is List) {
          flat.addAll((r['data'] as List).cast<Map<String, dynamic>>());
        }
      }
      return flat;
    } catch (e) {
      logger.e('Error fetching my quizzes: $e');
      return [];
    }
  }

  /// Full learner dashboard data from a single backend call.
  Future<Map<String, dynamic>> getStudentDashboard() async {
    try {
      final response = await get('dashboard/student');
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          return response['data'] as Map<String, dynamic>;
        }
        return response;
      }
      return {};
    } catch (e) {
      logger.e('Error fetching student dashboard: $e');
      return {};
    }
  }

  Future<dynamic> getAssignmentDetail(String assignmentId) async {
    try {
      return await get('assignments/$assignmentId');
    } catch (e) {
      logger.e('Error fetching assignment detail: $e');
      return {};
    }
  }

  Future<dynamic> submitAssignment(
    String assignmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      return await post('assignments/$assignmentId/submit', data: data);
    } catch (e) {
      logger.e('Error submitting assignment: $e');
      return {'submissionId': '', 'status': 'error'};
    }
  }

  Future<Map<String, dynamic>?> getSubmission(String submissionId) async {
    try {
      final response = await get('assignments/submissions/$submissionId');
      return response as Map<String, dynamic>?;
    } catch (e) {
      logger.e('Error fetching submission: $e');
      return null;
    }
  }

  Future<dynamic> getSubmissions(String assignmentId) async {
    try {
      return await get('assignments/$assignmentId/submissions');
    } catch (e) {
      logger.e('Error fetching submissions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSubmissionFile(String submissionId) async {
    try {
      final response = await get('assignments/submissions/$submissionId/file');
      return response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      logger.e('Error fetching submission file: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteSubmissionFile(
    String submissionId,
  ) async {
    try {
      final response = await delete(
        'assignments/submissions/$submissionId/file',
      );
      return response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      logger.e('Error deleting submission file: $e');
      return null;
    }
  }

  // ==================== EVENT ENDPOINTS ====================
  Future<dynamic> getEvents() async {
    try {
      return await get('events');
    } catch (e) {
      logger.e('Error fetching events: $e');
      return [];
    }
  }

  Future<dynamic> getRegisteredEvents() async {
    try {
      return await get('events/user/my-events');
    } catch (e) {
      logger.e('Error fetching registered events: $e');
      return [];
    }
  }

  Future<dynamic> getUpcomingEvents() async {
    try {
      return await get(
        'events',
        queryParameters: {'upcomingOnly': true, 'status': 'scheduled'},
      );
    } catch (e) {
      logger.e('Error fetching upcoming events: $e');
      return [];
    }
  }

  Future<dynamic> getEventDetail(String eventId) async {
    try {
      return await get('events/$eventId');
    } catch (e) {
      logger.e('Error fetching event detail: $e');
      return {};
    }
  }

  Future<dynamic> registerEvent(String eventId) async {
    try {
      return await post('events/$eventId/register');
    } catch (e) {
      logger.e('Error registering for event: $e');
      return {'success': false};
    }
  }

  Future<dynamic> unregisterEvent(String eventId) async {
    try {
      return await delete('events/$eventId/register');
    } catch (e) {
      logger.e('Error unregistering from event: $e');
      return {'success': false};
    }
  }

  Future<List<Map<String, dynamic>>?> getEventAttendees(String eventId) async {
    try {
      final response = await get('events/$eventId/attendees');
      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((e) => e as Map<String, dynamic>),
        );
      }
      return null;
    } catch (e) {
      logger.e('Error fetching event attendees: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getEventAnalytics(String eventId) async {
    try {
      final response = await get('events/$eventId/analytics');
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error fetching event analytics: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createEvent(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('events', data: payload);
      return response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      logger.e('Error creating event: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateEvent(
    String eventId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('events/$eventId', data: payload);
      return response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      logger.e('Error updating event: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> deleteEvent(String eventId) async {
    try {
      final response = await delete('events/$eventId');
      return response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      logger.e('Error deleting event: $e');
      return null;
    }
  }

  // ==================== ADMIN ENDPOINTS ====================
  Future<Map<String, dynamic>> getAdminUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    return await get(
      'admin/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (role != null) 'role': role,
        if (status != null) 'status': status,
        'search': (search != null && search.isNotEmpty) ? search : null,
      },
    );
  }

  Future<Map<String, dynamic>> changeUserRole(
    int userId,
    String newRole,
  ) async {
    return await put('admin/users/$userId/role', data: {'newRole': newRole});
  }

  Future<Map<String, dynamic>> deactivateUser(int userId) async {
    return await put('admin/users/$userId/deactivate', data: {});
  }

  Future<Map<String, dynamic>> reactivateUser(int userId) async {
    return await put('admin/users/$userId/reactivate', data: {});
  }

  Future<Map<String, dynamic>> getAdminMembershipTiers() async {
    return await get('admin/membership-tiers');
  }

  Future<Map<String, dynamic>> createMembershipTier(
    Map<String, dynamic> payload,
  ) async {
    return await post('admin/membership-tiers', data: payload);
  }

  Future<Map<String, dynamic>> deleteMembershipTier(int tierId) async {
    return await delete('admin/membership-tiers/$tierId');
  }

  Future<Map<String, dynamic>> getAdminPartners() async {
    return await get('admin/partners');
  }

  Future<Map<String, dynamic>> createPartner(
    Map<String, dynamic> payload,
  ) async {
    return await post('admin/partners', data: payload);
  }

  Future<Map<String, dynamic>> deletePartner(int id) async {
    return await delete('admin/partners/$id');
  }

  Future<Map<String, dynamic>> updatePartner(
    int id,
    Map<String, dynamic> payload,
  ) async {
    return await put('admin/partners/$id', data: payload);
  }

  Future<Map<String, dynamic>> getAdminTestimonials() async {
    return await get('admin/testimonials');
  }

  Future<Map<String, dynamic>> createTestimonial(
    Map<String, dynamic> payload,
  ) async {
    return await post('admin/testimonials', data: payload);
  }

  Future<Map<String, dynamic>> deleteTestimonial(int id) async {
    return await delete('admin/testimonials/$id');
  }

  Future<Map<String, dynamic>> updateTestimonial(
    int id,
    Map<String, dynamic> payload,
  ) async {
    return await put('admin/testimonials/$id', data: payload);
  }

  // ==================== MODERATION ENDPOINTS ====================
  Future<Map<String, dynamic>> getModerationFlags({
    String status = 'pending',
    String? contentType,
    String? reason,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await get(
        'moderation/admin/flags',
        queryParameters: {
          'status': status,
          'limit': limit,
          'offset': offset,
          if (contentType != null && contentType.isNotEmpty)
            'contentType': contentType,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': []};
    } catch (e) {
      logger.e('Error loading moderation flags: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> resolveModerationFlag(
    int flagId, {
    required String action,
    String? resolutionNote,
  }) async {
    return await put(
      'moderation/admin/flags/$flagId',
      data: {
        'action': action,
        if (resolutionNote != null && resolutionNote.isNotEmpty)
          'resolution_note': resolutionNote,
      },
    );
  }

  Future<Map<String, dynamic>> resolveModerationFlagsBulk(
    List<int> flagIds, {
    required String action,
    String? resolutionNote,
  }) async {
    return await put(
      'moderation/admin/flags/bulk',
      data: {
        'flagIds': flagIds,
        'action': action,
        if (resolutionNote != null && resolutionNote.isNotEmpty)
          'resolution_note': resolutionNote,
      },
    );
  }

  Future<Map<String, dynamic>> getModerationStats() async {
    return await get('moderation/admin/stats');
  }

  Future<dynamic> createLesson(
    String courseId,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await post('courses/$courseId/lessons', data: payload);
    } catch (e) {
      logger.e('Error creating lesson: $e');
      return {'success': false};
    }
  }

  Future<dynamic> updateLesson(
    String lessonId,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await put('courses/lessons/$lessonId', data: payload);
    } catch (e) {
      logger.e('Error updating lesson: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('auth/me', data: payload);
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error updating profile: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String?> exportAdminReport(
    String type, {
    String format = 'csv',
  }) async {
    try {
      final response = await _dio.get(
        _normalizeEndpoint('admin/reports/export/$type'),
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data?.toString();
    } catch (e) {
      logger.e('Error exporting admin report: $e');
      return null;
    }
  }

  Future<String?> saveAdminReportToFile(
    String type, {
    String format = 'csv',
  }) async {
    try {
      final contents = await exportAdminReport(type, format: format);
      if (contents == null || contents.isEmpty) return null;

      final root = await getApplicationDocumentsDirectory();
      final exportDir = Directory(
        '${root.path}${Platform.pathSeparator}exports',
      );
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final safeType = type.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File(
        '${exportDir.path}${Platform.pathSeparator}$safeType-$timestamp.$format',
      );
      await file.writeAsString(contents, flush: true);
      return file.path;
    } catch (e) {
      logger.e('Error saving admin report: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> listRoleResources(
    String namespace, {
    bool includeAll = false,
  }) async {
    try {
      final response = await get(
        'role-resources/$namespace',
        queryParameters: includeAll ? {'scope': 'all'} : null,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': []};
    } catch (e) {
      logger.e('Error listing role resources: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> createRoleResource(
    String namespace,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('role-resources/$namespace', data: payload);
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating role resource: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> updateRoleResource(
    String namespace,
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put(
        'role-resources/$namespace/$id',
        data: payload,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error updating role resource: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> deleteRoleResource(
    String namespace,
    String id,
  ) async {
    try {
      final response = await delete('role-resources/$namespace/$id');
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error deleting role resource: $e');
      return {'success': false};
    }
  }

  // ==================== PUBLIC CONTENT ENDPOINTS ====================
  Future<Map<String, dynamic>> getLandingContent() async {
    return await get('public/landing-content');
  }

  // ==================== GLOBAL SEARCH ENDPOINTS ====================
  Future<Map<String, dynamic>> globalSearch(
    String searchTerm, {
    String type = 'all',
    int limit = 8,
  }) async {
    try {
      final response = await get(
        'search/global',
        queryParameters: {'q': searchTerm, 'type': type, 'limit': limit},
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': {}};
    } catch (e) {
      logger.e('Error searching content: $e');
      return {'success': false, 'data': {}};
    }
  }

  // ==================== NOTIFICATION CENTER ENDPOINTS ====================
  Future<Map<String, dynamic>> getNotifications({
    int limit = 25,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await get(
        'notifications',
        queryParameters: {'limit': limit, 'unreadOnly': unreadOnly},
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': []};
    } catch (e) {
      logger.e('Error fetching notifications: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    try {
      final response = await put('notifications/$id/read');
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error marking notification read: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      final response = await put('notifications/read-all');
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error marking notifications read: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(String id) async {
    try {
      final response = await delete('notifications/$id');
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error deleting notification: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> registerDeviceToken(String token) async {
    try {
      final response = await put(
        'notifications/device-token',
        data: {'token': token},
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error registering device token: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> clearDeviceToken() async {
    try {
      final response = await delete('notifications/device-token');
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error clearing device token: $e');
      return {'success': false};
    }
  }

  // ==================== PAYMENT REFUND ENDPOINT ====================
  Future<Map<String, dynamic>> refundPayment(
    String reference, {
    double? amount,
    String? reason,
  }) async {
    try {
      final response = await post(
        'payments/$reference/refund',
        data: {
          if (amount != null) 'amount': amount,
          'reason': (reason != null && reason.isNotEmpty) ? reason : null,
        },
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error refunding payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CLASSROOM BLUEPRINT ENDPOINTS ====================
  Future<Map<String, dynamic>> getClassroomBlueprint() async {
    try {
      final response = await get('classroom/blueprint');
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': {}};
    } catch (e) {
      logger.e('Error loading classroom blueprint: $e');
      return {'success': false, 'data': {}};
    }
  }

  Future<Map<String, dynamic>> getClassroomHierarchy() async {
    try {
      final response = await get('classroom/hierarchy');
      if (response is Map<String, dynamic>) return response;
      return {'success': false, 'data': []};
    } catch (e) {
      logger.e('Error loading classroom hierarchy: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<Map<String, dynamic>> createClassroomProgramme(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('classroom/programmes', data: payload);
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom programme: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> createClassroomLevel(
    String programmeId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post(
        'classroom/programmes/$programmeId/levels',
        data: payload,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom level: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> createClassroomCycle(
    String levelId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post(
        'classroom/levels/$levelId/cycles',
        data: payload,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom cycle: $e');
      return {'success': false};
    }
  }

  Future<Map<String, dynamic>> createClassroomActivity(
    String lessonId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post(
        'classroom/lessons/$lessonId/activities',
        data: payload,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom activity: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createClassroomLiveSession(
    String cycleId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post(
        'classroom/cycles/$cycleId/live-sessions',
        data: payload,
      );
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom live session: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createClassroomBadgeRule(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('classroom/badges', data: payload);
      if (response is Map<String, dynamic>) return response;
      return {'success': false};
    } catch (e) {
      logger.e('Error creating classroom badge rule: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConfig.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }

  Future<String?> _getToken() async {
    return await getToken();
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: AppConfig.tokenKey);
  }

  // Close Dio
  void dispose() {
    _dio.close();
  }
}
