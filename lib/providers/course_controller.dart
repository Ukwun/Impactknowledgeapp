import 'package:get/get.dart';
import '../models/courses/course_model.dart';
import '../services/course/course_service.dart';
import '../config/service_locator.dart';

class CourseController extends GetxController {
  final courseService = getIt<CourseService>();

  final courses = RxList<Course>();
  final enrolledCourses = RxList<Enrollment>();
  final selectedCourse = Rx<Course?>(null);
  final selectedModule = Rx<Module?>(null);
  final selectedLesson = Rx<Lesson?>(null);
  final courseModules = RxList<Module>();
  final moduleLessons = RxList<Lesson>();

  final isLoading = false.obs;
  final errorMessage = RxString('');

  final selectedCategory = RxString('');
  final searchQuery = RxString('');

  Future<void> fetchAllCourses({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? search,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      courses.value = await courseService.getAllCourses(
        page: page,
        pageSize: pageSize,
        category: category,
        search: search,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load courses';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchInstructorCourses(String instructorId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      courses.value = await courseService.getInstructorCourses(instructorId);
    } catch (e) {
      errorMessage.value = 'Failed to load managed courses';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCourseDetails(String courseId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedCourse.value = await courseService.getCourseById(courseId);
      await getCourseModules(courseId);
    } catch (e) {
      errorMessage.value = 'Failed to load course details';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCourseModules(String courseId) async {
    try {
      courseModules.value = await courseService.getCourseModules(courseId);
    } catch (e) {
      errorMessage.value = 'Failed to load modules';
    }
  }

  Future<void> getModuleLessons(String moduleId) async {
    try {
      moduleLessons.value = await courseService.getModuleLessons(moduleId);
    } catch (e) {
      errorMessage.value = 'Failed to load lessons';
    }
  }

  Future<void> getLessonDetails(String lessonId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedLesson.value = await courseService.getLessonById(lessonId);
    } catch (e) {
      errorMessage.value = 'Failed to load lesson';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await courseService.enrollCourse(courseId);
      await fetchUserEnrollments();
      Get.snackbar('Success', 'Enrolled in course successfully');
    } catch (e) {
      errorMessage.value = 'Failed to enroll in course';
      Get.snackbar('Error', 'Could not enroll in course');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserEnrollments({int page = 1, int pageSize = 20}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      enrolledCourses.value = await courseService.getUserEnrollments(
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load enrollments';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLessonProgress(
    String lessonId, {
    required String status,
    double? score,
  }) async {
    try {
      errorMessage.value = '';
      await courseService.updateLessonProgress(
        lessonId,
        status: status,
        score: score,
      );
      Get.snackbar('Success', 'Progress updated');
    } catch (e) {
      errorMessage.value = 'Failed to update progress';
    }
  }

  Future<double> getEnrollmentProgress(String enrollmentId) async {
    try {
      return await courseService.getEnrollmentProgress(enrollmentId);
    } catch (e) {
      errorMessage.value = 'Failed to load progress';
      return 0.0;
    }
  }

  Future<void> completeCourse(String enrollmentId) async {
    try {
      isLoading.value = true;
      await courseService.completeCourse(enrollmentId);
      await fetchUserEnrollments();
      Get.snackbar('Success', 'Course completed!');
    } catch (e) {
      errorMessage.value = 'Failed to complete course';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> dropCourse(String enrollmentId) async {
    try {
      isLoading.value = true;
      await courseService.dropCourse(enrollmentId);
      await fetchUserEnrollments();
      Get.snackbar('Success', 'Course dropped');
    } catch (e) {
      errorMessage.value = 'Failed to drop course';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCourse({
    required String title,
    String? description,
    String? category,
    String? level,
    int? durationHours,
    double price = 0,
  }) async {
    try {
      isLoading.value = true;
      await courseService.createCourse(
        title: title,
        description: description,
        category: category,
        level: level,
        durationHours: durationHours,
        price: price,
      );
      Get.snackbar('Success', 'Course created successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create course';
      Get.snackbar('Error', 'Could not create course');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCourse(
    String courseId, {
    String? title,
    String? description,
    String? category,
    String? level,
    int? durationHours,
    bool? isPublished,
    double? price,
  }) async {
    try {
      isLoading.value = true;
      await courseService.updateCourse(
        courseId,
        title: title,
        description: description,
        category: category,
        level: level,
        durationHours: durationHours,
        isPublished: isPublished,
        price: price,
      );
      Get.snackbar('Success', 'Course updated successfully');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update course';
      Get.snackbar('Error', 'Could not update course');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteManagedCourse(String courseId) async {
    try {
      isLoading.value = true;
      await courseService.deleteCourse(courseId);
      courses.removeWhere((c) => c.id == courseId);
      Get.snackbar('Success', 'Course deleted');
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete course';
      Get.snackbar('Error', 'Could not delete course');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> fetchCourseAnalytics(String courseId) async {
    try {
      return await courseService.getCourseAnalytics(courseId);
    } catch (e) {
      errorMessage.value = 'Failed to load course analytics';
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchCourseReports(String courseId) async {
    try {
      return await courseService.getCourseReports(courseId);
    } catch (e) {
      errorMessage.value = 'Failed to load course reports';
      return null;
    }
  }

  Future<Map<String, dynamic>?> messageCourseStudents(
    String courseId, {
    required String subject,
    required String message,
  }) async {
    try {
      return await courseService.sendCourseAnnouncement(
        courseId,
        subject: subject,
        message: message,
      );
    } catch (e) {
      errorMessage.value = 'Failed to send announcement';
      return null;
    }
  }

  Future<Lesson?> createLessonForCourse(
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
    try {
      isLoading.value = true;
      final lesson = await courseService.createLesson(
        courseId,
        moduleId: moduleId,
        title: title,
        description: description,
        contentBody: contentBody,
        contentType: contentType,
        contentUrl: contentUrl,
        orderIndex: orderIndex,
        durationMinutes: durationMinutes,
      );
      if (lesson != null) {
        Get.snackbar('Success', 'Lesson created successfully');
      }
      return lesson;
    } catch (e) {
      errorMessage.value = 'Failed to create lesson';
      Get.snackbar('Error', 'Could not create lesson');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Lesson?> updateLessonContent(
    String lessonId, {
    String? title,
    String? description,
    String? contentBody,
    String? contentType,
    String? contentUrl,
    int? orderIndex,
    int? durationMinutes,
  }) async {
    try {
      isLoading.value = true;
      final lesson = await courseService.updateLesson(
        lessonId,
        title: title,
        description: description,
        contentBody: contentBody,
        contentType: contentType,
        contentUrl: contentUrl,
        orderIndex: orderIndex,
        durationMinutes: durationMinutes,
      );
      if (lesson != null) {
        Get.snackbar('Success', 'Lesson updated successfully');
      }
      return lesson;
    } catch (e) {
      errorMessage.value = 'Failed to update lesson';
      Get.snackbar('Error', 'Could not update lesson');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
