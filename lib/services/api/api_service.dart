import 'package:dio/dio.dart';
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

  // Generic GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
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
        endpoint,
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
        endpoint,
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
        endpoint,
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

      final response = await _dio.post(endpoint, data: formData);

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
      return await get('quiz/course/$courseId');
    } catch (e) {
      logger.e('Error fetching quizzes: $e');
      return [];
    }
  }

  Future<dynamic> getQuizDetail(String quizId) async {
    try {
      return await get('quiz/$quizId');
    } catch (e) {
      logger.e('Error fetching quiz detail: $e');
      return {};
    }
  }

  Future<dynamic> getQuizQuestions(String quizId) async {
    try {
      return await get('quiz/$quizId/questions');
    } catch (e) {
      logger.e('Error fetching quiz questions: $e');
      return [];
    }
  }

  Future<dynamic> startQuizAttempt(String quizId) async {
    try {
      return await post('quiz/$quizId/attempt/start');
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
      return await post(
        'quiz/attempt/$attemptId/submit',
        data: {'answers': answers},
      );
    } catch (e) {
      logger.e('Error submitting quiz: $e');
      return {'score': 0, 'passed': false};
    }
  }

  Future<Map<String, dynamic>?> getQuizAttemptDetail(String attemptId) async {
    try {
      final response = await get('quiz/attempt/$attemptId');
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error fetching attempt detail: $e');
      return null;
    }
  }

  Future<dynamic> getLeaderboard(String quizId, {int limit = 100}) async {
    try {
      return await get(
        'quiz/$quizId/leaderboard',
        queryParameters: {'limit': limit},
      );
    } catch (e) {
      logger.e('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ==================== ASSIGNMENT ENDPOINTS ====================
  Future<dynamic> getAssignments(String courseId) async {
    try {
      return await get('assignment/course/$courseId');
    } catch (e) {
      logger.e('Error fetching assignments: $e');
      return [];
    }
  }

  Future<dynamic> getAssignmentDetail(String assignmentId) async {
    try {
      return await get('assignment/$assignmentId');
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
      return await post('assignment/$assignmentId/submit', data: data);
    } catch (e) {
      logger.e('Error submitting assignment: $e');
      return {'submissionId': '', 'status': 'error'};
    }
  }

  Future<Map<String, dynamic>?> getSubmission(String submissionId) async {
    try {
      final response = await get('assignment/submission/$submissionId');
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error fetching submission: $e');
      return null;
    }
  }

  Future<dynamic> getSubmissions(String assignmentId) async {
    try {
      return await get('assignment/$assignmentId/submissions');
    } catch (e) {
      logger.e('Error fetching submissions: $e');
      return [];
    }
  }

  // ==================== EVENT ENDPOINTS ====================
  Future<dynamic> getEvents() async {
    try {
      return await get('event');
    } catch (e) {
      logger.e('Error fetching events: $e');
      return [];
    }
  }

  Future<dynamic> getRegisteredEvents() async {
    try {
      return await get('event/registered');
    } catch (e) {
      logger.e('Error fetching registered events: $e');
      return [];
    }
  }

  Future<dynamic> getUpcomingEvents() async {
    try {
      return await get('event/upcoming');
    } catch (e) {
      logger.e('Error fetching upcoming events: $e');
      return [];
    }
  }

  Future<dynamic> getEventDetail(String eventId) async {
    try {
      return await get('event/$eventId');
    } catch (e) {
      logger.e('Error fetching event detail: $e');
      return {};
    }
  }

  Future<dynamic> registerEvent(String eventId) async {
    try {
      return await post('event/$eventId/register');
    } catch (e) {
      logger.e('Error registering for event: $e');
      return {'success': false};
    }
  }

  Future<dynamic> unregisterEvent(String eventId) async {
    try {
      return await post('event/$eventId/unregister');
    } catch (e) {
      logger.e('Error unregistering from event: $e');
      return {'success': false};
    }
  }

  Future<List<Map<String, dynamic>>?> getEventAttendees(String eventId) async {
    try {
      final response = await get('event/$eventId/attendees');
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
      final response = await get('event/$eventId/analytics');
      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error fetching event analytics: $e');
      return null;
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
