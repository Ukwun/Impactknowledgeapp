import '../api/api_service.dart';
import '../../models/courses/course_model.dart';

class CourseService {
  final ApiService apiService;

  CourseService({required this.apiService});

  // Get all courses
  Future<List<Course>> getAllCourses({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        'courses',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (category != null) 'category': category,
          if (search != null) 'search': search,
        },
      );
      return response
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get course by ID
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/courses/$courseId',
      );
      return Course.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get course modules
  Future<List<Module>> getCourseModules(String courseId) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/api/courses/$courseId/modules',
      );
      return response
          .map((item) => Module.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get module lessons
  Future<List<Lesson>> getModuleLessons(String moduleId) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/api/modules/$moduleId/lessons',
      );
      return response
          .map((item) => Lesson.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get lesson by ID
  Future<Lesson> getLessonById(String lessonId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/lessons/$lessonId',
      );
      return Lesson.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Enroll in course
  Future<Enrollment> enrollCourse(String courseId) async {
    try {
      final response = await apiService.post<Map<String, dynamic>>(
        '/api/enrollments',
        data: {'courseId': courseId},
      );
      return Enrollment.fromJson(response);
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
      final response = await apiService.get<List<dynamic>>(
        '/api/enrollments',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return response
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get enrollment by ID
  Future<Enrollment> getEnrollmentById(String enrollmentId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/api/enrollments/$enrollmentId',
      );
      return Enrollment.fromJson(response);
    } catch (e) {
      rethrow;
    }
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
