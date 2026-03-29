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

  void clearError() {
    errorMessage.value = '';
  }
}
