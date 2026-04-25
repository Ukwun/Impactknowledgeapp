import '../api/api_service.dart';
import '../../models/courses/course_model.dart';

class CourseService {
  final ApiService apiService;

  CourseService({required this.apiService});

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic> && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return const <dynamic>[];
  }

  DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Course _toCourse(dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    return Course.fromJson({
      'id': (map['id'] ?? '').toString(),
      'title': (map['title'] ?? 'Untitled course').toString(),
      'description': map['description']?.toString(),
      'coverImage':
          map['coverImage']?.toString() ?? map['thumbnail_url']?.toString(),
      'learningOutcomes': map['learningOutcomes']?.toString(),
      'category': map['category']?.toString(),
      'estimatedDuration':
          (map['estimatedDuration'] ?? map['duration_hours']) as num?,
      'difficultyLevel':
          map['difficultyLevel']?.toString() ?? map['level']?.toString(),
      'isPublished': (map['isPublished'] ?? map['is_published']) == true,
      'enrollmentCount': (map['enrollmentCount'] ?? 0) as num,
      'averageRating': map['averageRating'] as num?,
      'createdAt': _parseDate(
        map['createdAt'] ?? map['created_at'],
      ).toIso8601String(),
      'updatedAt': _parseDate(
        map['updatedAt'] ?? map['updated_at'],
      ).toIso8601String(),
      'instructorId': (map['instructorId'] ?? map['instructor_id'] ?? '')
          .toString(),
      'moduleCount': (map['moduleCount'] ?? 0) as num,
      'lessonCount': (map['lessonCount'] ?? 0) as num,
    });
  }

  Module _toModule(dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    return Module.fromJson({
      'id': (map['id'] ?? '').toString(),
      'courseId': (map['courseId'] ?? map['course_id'] ?? '').toString(),
      'title': (map['title'] ?? '').toString(),
      'description': map['description']?.toString(),
      'sequenceNumber':
          (map['sequenceNumber'] ?? map['order_index'] ?? 0) as num,
      'createdAt': _parseDate(
        map['createdAt'] ?? map['created_at'],
      ).toIso8601String(),
      'updatedAt': _parseDate(
        map['updatedAt'] ?? map['updated_at'],
      ).toIso8601String(),
      'lessonCount': (map['lessonCount'] ?? 0) as num,
    });
  }

  Lesson _toLesson(dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    return Lesson.fromJson({
      'id': (map['id'] ?? '').toString(),
      'moduleId': (map['moduleId'] ?? map['module_id'] ?? '').toString(),
      'title': (map['title'] ?? '').toString(),
      'content':
          map['content']?.toString() ??
          map['content_body']?.toString() ??
          map['description']?.toString(),
      'videoUrl': map['videoUrl']?.toString() ?? map['content_url']?.toString(),
      'sequenceNumber':
          (map['sequenceNumber'] ?? map['order_index'] ?? 0) as num,
      'estimatedDuration':
          (map['estimatedDuration'] ?? map['duration_minutes'] ?? 0) as num,
      'requiresCompletion': (map['requiresCompletion'] ?? false) == true,
      'createdAt': _parseDate(
        map['createdAt'] ?? map['created_at'],
      ).toIso8601String(),
      'updatedAt': _parseDate(
        map['updatedAt'] ?? map['updated_at'],
      ).toIso8601String(),
      'lessonType': (map['lessonType'] ?? map['content_type'] ?? 'text')
          .toString(),
    });
  }

  Enrollment _toEnrollment(dynamic item) {
    final map = Map<String, dynamic>.from(item as Map);
    return Enrollment.fromJson({
      'id': (map['id'] ?? '').toString(),
      'userId': (map['userId'] ?? map['user_id'] ?? '').toString(),
      'courseId': (map['courseId'] ?? map['course_id'] ?? '').toString(),
      'status': (map['status'] ?? map['completion_status'] ?? 'in_progress')
          .toString(),
      'progressPercentage':
          (map['progressPercentage'] ?? map['progress_percentage']) as num?,
      'enrolledAt': _parseDate(
        map['enrolledAt'] ?? map['enrollment_date'] ?? map['created_at'],
      ).toIso8601String(),
      'completedAt': (map['completedAt'] ?? map['completed_at'])?.toString(),
      'updatedAt': _parseDate(
        map['updatedAt'] ?? map['updated_at'] ?? map['created_at'],
      ).toIso8601String(),
    });
  }

  // Get all courses
  Future<List<Course>> getAllCourses({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    try {
      final response = await apiService.get<dynamic>(
        'courses',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (category != null) 'category': category,
          if (search != null) 'search': search,
        },
      );
      return _extractList(response).map(_toCourse).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Course>> getInstructorCourses(String instructorId) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/courses/instructor/$instructorId/courses',
      );
      return _extractList(response).map(_toCourse).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get course by ID
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await apiService.get<dynamic>('/api/courses/$courseId');
      return _toCourse(_extractMap(response));
    } catch (e) {
      rethrow;
    }
  }

  // Get course modules
  Future<List<Module>> getCourseModules(String courseId) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/courses/$courseId/modules',
      );
      return _extractList(response).map(_toModule).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get module lessons
  Future<List<Lesson>> getModuleLessons(String moduleId) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/courses/modules/$moduleId/lessons',
      );
      return _extractList(response).map(_toLesson).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get lesson by ID
  Future<Lesson> getLessonById(String lessonId) async {
    try {
      final response = await apiService.get<dynamic>('/api/lessons/$lessonId');
      return _toLesson(_extractMap(response));
    } catch (e) {
      rethrow;
    }
  }

  // Enroll in course
  Future<Enrollment> enrollCourse(String courseId) async {
    try {
      final response = await apiService.post<dynamic>(
        '/api/enrollments',
        data: {'courseId': courseId},
      );
      return _toEnrollment(_extractMap(response));
    } catch (e) {
      rethrow;
    }
  }

  // Get user enrollments
  Future<List<Enrollment>> getUserEnrollments({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/enrollments',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return _extractList(response).map(_toEnrollment).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get enrollment by ID
  Future<Enrollment> getEnrollmentById(String enrollmentId) async {
    try {
      final response = await apiService.get<dynamic>(
        '/api/enrollments/$enrollmentId',
      );
      return _toEnrollment(_extractMap(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<Course> createCourse({
    required String title,
    String? description,
    String? category,
    String? level,
    int? durationHours,
    double price = 0,
  }) async {
    final response = await apiService.post<dynamic>(
      '/api/courses',
      data: {
        'title': title,
        'description': description,
        'category': category,
        'level': level,
        'duration_hours': durationHours,
        'price': price,
      },
    );
    return _toCourse(_extractMap(response));
  }

  Future<Course> updateCourse(
    String courseId, {
    String? title,
    String? description,
    String? category,
    String? level,
    int? durationHours,
    bool? isPublished,
    double? price,
  }) async {
    final response = await apiService.put<dynamic>(
      '/api/courses/$courseId',
      data: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (level != null) 'level': level,
        if (durationHours != null) 'duration_hours': durationHours,
        if (isPublished != null) 'is_published': isPublished,
        if (price != null) 'price': price,
      },
    );
    return _toCourse(_extractMap(response));
  }

  Future<void> deleteCourse(String courseId) async {
    await apiService.delete('/api/courses/$courseId');
  }

  Future<Map<String, dynamic>> getCourseAnalytics(String courseId) async {
    final response = await apiService.get<dynamic>(
      '/api/courses/$courseId/analytics',
    );
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> getCourseReports(String courseId) async {
    final response = await apiService.get<dynamic>(
      '/api/courses/$courseId/reports',
    );
    return _extractMap(response);
  }

  Future<Map<String, dynamic>> sendCourseAnnouncement(
    String courseId, {
    required String subject,
    required String message,
  }) async {
    final response = await apiService.post<dynamic>(
      '/api/courses/$courseId/announcements',
      data: {'subject': subject, 'message': message},
    );
    return _extractMap(response);
  }

  Future<Lesson?> createLesson(
    String courseId, {
    required String moduleId,
    required String title,
    String? description,
    String? contentBody,
    String contentType = 'rich_text',
    String? contentUrl,
    int orderIndex = 1,
    int? durationMinutes,
  }) async {
    final response = await apiService.createLesson(courseId, {
      'moduleId': moduleId,
      'title': title,
      if (description != null) 'description': description,
      if (contentBody != null) 'content_body': contentBody,
      'content_type': contentType,
      if (contentUrl != null) 'content_url': contentUrl,
      'order_index': orderIndex,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
    });

    final map = _extractMap(response);
    if (map.isEmpty) return null;
    return _toLesson(map);
  }

  Future<Lesson?> updateLesson(
    String lessonId, {
    String? title,
    String? description,
    String? contentBody,
    String? contentType,
    String? contentUrl,
    int? orderIndex,
    int? durationMinutes,
  }) async {
    final response = await apiService.updateLesson(lessonId, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (contentBody != null) 'content_body': contentBody,
      if (contentType != null) 'content_type': contentType,
      if (contentUrl != null) 'content_url': contentUrl,
      if (orderIndex != null) 'order_index': orderIndex,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
    });

    final map = _extractMap(response);
    if (map.isEmpty) return null;
    return _toLesson(map);
  }

  // Update lesson progress
  Future<LessonProgress> updateLessonProgress(
    String lessonId, {
    required String status,
    double? score,
  }) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/api/lessons/$lessonId/progress',
        data: {'status': status, if (score != null) 'score': score},
      );
      return LessonProgress.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get lesson progress
  Future<LessonProgress> getLessonProgress(String lessonId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/lessons/$lessonId/progress',
      );
      return LessonProgress.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get enrollment progress
  Future<double> getEnrollmentProgress(String enrollmentId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/enrollments/$enrollmentId/progress',
      );
      return (response['progressPercentage'] as num).toDouble();
    } catch (e) {
      rethrow;
    }
  }

  // Complete course
  Future<void> completeCourse(String enrollmentId) async {
    try {
      await apiService.post('enrollments/$enrollmentId/complete');
    } catch (e) {
      rethrow;
    }
  }

  // Drop course
  Future<void> dropCourse(String enrollmentId) async {
    try {
      await apiService.post('/api/enrollments/$enrollmentId/drop');
    } catch (e) {
      rethrow;
    }
  }
}
