import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../services/api/api_service.dart';
import '../config/service_locator.dart';

final Logger _logger = Logger();

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
      _logger.e('Error loading assignments', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get assignment detail by ID
  Map<String, dynamic>? getAssignmentById(String assignmentId) {
    try {
      return assignments.firstWhereOrNull((a) => a['id'] == assignmentId);
    } catch (e) {
      _logger.e('Error getting assignment', error: e);
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
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
    } catch (e) {
      error.value = 'Failed to load assignment: ${e.toString()}';
      _logger.e('Error loading assignment', error: e);
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
      _logger.e('Error submitting assignment', error: e);
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
          : <String, dynamic>{};
    } catch (e) {
      error.value = 'Failed to load submission: ${e.toString()}';
      _logger.e('Error loading submission', error: e);
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
      _logger.e('Error loading submissions', error: e);
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
      _logger.e('Error loading grades', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Download submission file
  Future<bool> downloadSubmission(String submissionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getSubmissionFile(submissionId);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['fileUrl'] != null) {
          currentSubmission.value ??= <String, dynamic>{};
          currentSubmission.value!['fileUrl'] = data['fileUrl'];
          return true;
        }
      }
      return false;
    } catch (e) {
      error.value = 'Failed to download submission: ${e.toString()}';
      _logger.e('Error downloading submission file', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Resolve and cache the latest secure file URL for a submission
  Future<String?> resolveSubmissionFileUrl(String submissionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getSubmissionFile(submissionId);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['fileUrl'] != null) {
          final url = data['fileUrl'].toString();
          currentSubmission.value ??= <String, dynamic>{};
          currentSubmission.value!['fileUrl'] = url;
          currentSubmission.value!['file_url'] = url;
          return url;
        }
      }
      return null;
    } catch (e) {
      error.value = 'Failed to resolve submission file: ${e.toString()}';
      _logger.e('Error resolving submission file URL', error: e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete submission file
  Future<bool> deleteSubmissionFile(String submissionId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.deleteSubmissionFile(submissionId);
      if (response != null && response['success'] == true) {
        if (currentSubmission.value != null) {
          currentSubmission.value!.remove('fileUrl');
          currentSubmission.value!.remove('file_url');
        }
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to delete submission file: ${e.toString()}';
      _logger.e('Error deleting submission file', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all pending/due assignments for the current user across every enrolled course.
  Future<void> loadMyAssignments() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getMyAssignments();
      if (response is List) {
        assignments.value = response
            .map<Map<String, dynamic>>(
              (a) => Map<String, dynamic>.from(a as Map),
            )
            .toList();
      } else if (response is Map && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          assignments.value = data
              .map<Map<String, dynamic>>(
                (a) => Map<String, dynamic>.from(a as Map),
              )
              .toList();
        }
      }
    } catch (e) {
      error.value = 'Failed to load your assignments: ${e.toString()}';
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
