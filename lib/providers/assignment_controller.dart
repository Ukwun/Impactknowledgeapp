import 'package:get/get.dart';
import '../services/api/api_service.dart';
import '../config/service_locator.dart';

class AssignmentController extends GetxController {
  final apiService = getIt<ApiService>();

  // Observable states
  final assignments = <Map<String, dynamic>>[].obs;
  final submissions = <Map<String, dynamic>>[].obs;
  final gradedSubmissions = <Map<String, dynamic>>[].obs;
  final currentAssignment = Rx<Map<String, dynamic>?>(null);
  final currentSubmission = Rx<Map<String, dynamic>?>(null);
  final isLoading = false.obs;
  final error = RxString('');

  /// Load all assignments for a specific course
  Future<void> loadAssignments(String courseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getAssignments(courseId);
      if (response is List) {
        assignments.value = List<Map<String, dynamic>>.from(
          response.map((a) => a as Map<String, dynamic>),
        );
      } else if (response is Map && response['success'] == true) {
        assignments.value = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((a) => a as Map<String, dynamic>),
        );
      }
    } catch (e) {
      error.value = 'Failed to load assignments: ${e.toString()}';
      print('Error loading assignments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get assignment detail by ID
  Map<String, dynamic>? getAssignmentById(String assignmentId) {
    try {
      return assignments.firstWhereOrNull((a) => a['id'] == assignmentId);
    } catch (e) {
      print('Error getting assignment: $e');
      return null;
    }
  }

  /// Load assignment detail
  Future<void> loadAssignmentDetail(String assignmentId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getAssignmentDetail(assignmentId);
      currentAssignment.value = response is Map
          ? Map<String, dynamic>.from(response as Map)
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      error.value = 'Failed to load assignment: ${e.toString()}';
      print('Error loading assignment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit an assignment
  Future<bool> submitAssignment(
    String assignmentId,
    String answerText,
    List<String> attachmentPaths,
  ) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Prepare submission data
      final submissionData = {
        'assignmentId': assignmentId,
        'submissionText': answerText,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      final response = await apiService.submitAssignment(
        assignmentId,
        submissionData,
      );

      if (response is Map && response['success'] == true) {
        // Store submission locally
        currentSubmission.value = response['data'] ?? submissionData;
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to submit assignment: ${e.toString()}';
      print('Error submitting assignment: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get submission by ID
  Future<void> getSubmission(String submissionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getSubmission(submissionId);
      currentSubmission.value = response is Map
          ? response
          : Map<String, dynamic>.from(response as Map);
    } catch (e) {
      error.value = 'Failed to load submission: ${e.toString()}';
      print('Error loading submission: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get all submissions for an assignment
  Future<void> getSubmissions(String assignmentId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getSubmissions(assignmentId);
      if (response is List) {
        submissions.value = List<Map<String, dynamic>>.from(
          response.map((s) => s as Map<String, dynamic>),
        );
      } else if (response is Map && response['success'] == true) {
        submissions.value = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((s) => s as Map<String, dynamic>),
        );
      }
    } catch (e) {
      error.value = 'Failed to load submissions: ${e.toString()}';
      print('Error loading submissions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get graded submissions
  Future<void> loadGradedSubmissions() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Filter submissions that have grades
      gradedSubmissions.value = submissions
          .where((s) => s['grade'] != null && s['grade'] is num)
          .toList();
    } catch (e) {
      error.value = 'Failed to load grades: ${e.toString()}';
      print('Error loading grades: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Download submission file
  Future<bool> downloadSubmission(String submissionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      // In a real app, this would download the file
      // For now, just fetch the submission details
      await getSubmission(submissionId);
      return true;
    } catch (e) {
      error.value = 'Failed to download submission: ${e.toString()}';
      print('Error downloading: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter assignments by status
  List<Map<String, dynamic>> getAssignmentsByStatus(String status) {
    return assignments.where((a) => a['submissionStatus'] == status).toList();
  }

  /// Get overdue assignments
  List<Map<String, dynamic>> getOverdueAssignments() {
    final now = DateTime.now();
    return assignments.where((a) {
      try {
        final dueDate = DateTime.parse(a['dueDate'] ?? '');
        return dueDate.isBefore(now) && a['submissionStatus'] != 'submitted';
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  void onClose() {
    assignments.clear();
    submissions.clear();
    super.onClose();
  }
}
