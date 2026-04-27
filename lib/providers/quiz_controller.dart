import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../services/api/api_service.dart';
import '../config/service_locator.dart';

final Logger _logger = Logger();

class QuizController extends GetxController {
  final apiService = getIt<ApiService>();

  // Observable states
  final quizzes = <Map<String, dynamic>>[].obs;
  final questions = <Map<String, dynamic>>[].obs;
  final currentQuiz = Rx<Map<String, dynamic>?>(null);
  final currentAttempt = Rx<Map<String, dynamic>?>(null);
  final userResponses = <int, dynamic>{}.obs;
  final leaderboard = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final error = RxString('');
  final remainingTime = 0.obs;

  /// Load all quizzes for a specific course
  Future<void> loadQuizzesForCourse(String courseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getQuizzes(courseId);
      if (response is List) {
        quizzes.value = List<Map<String, dynamic>>.from(
          response.map((q) => q as Map<String, dynamic>),
        );
      } else if (response is Map && response['success'] == true) {
        quizzes.value = List<Map<String, dynamic>>.from(
          (response['data'] as List).map((q) => q as Map<String, dynamic>),
        );
      }
    } catch (e) {
      error.value = 'Failed to load quizzes: ${e.toString()}';
      _logger.e('Error loading quizzes', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a quiz to take
  Future<void> startQuiz(String quizId) async {
    try {
      isLoading.value = true;
      error.value = '';

      // Get quiz details
      final quizResponse = await apiService.getQuizDetail(quizId);
      currentQuiz.value = quizResponse is Map
          ? Map<String, dynamic>.from(quizResponse)
          : <String, dynamic>{};

      // Get quiz questions
      final questionsResponse = await apiService.getQuizQuestions(quizId);
      if (questionsResponse is List) {
        questions.value = List<Map<String, dynamic>>.from(
          questionsResponse.map((q) => q as Map<String, dynamic>),
        );
      } else if (questionsResponse is Map &&
          questionsResponse['success'] == true) {
        questions.value = List<Map<String, dynamic>>.from(
          (questionsResponse['data'] as List).map(
            (q) => q as Map<String, dynamic>,
          ),
        );
      }

      // Initialize user responses
      userResponses.clear();

      // Start attempt
      final attemptResponse = await apiService.startQuizAttempt(quizId);
      currentAttempt.value = attemptResponse is Map
          ? Map<String, dynamic>.from(attemptResponse)
          : <String, dynamic>{};

      // Set up timer based on time limit
      final timeLimit = currentQuiz.value?['timeLimit'] ?? 60;
      remainingTime.value = timeLimit * 60; // Convert minutes to seconds
      _startTimer();
    } catch (e) {
      error.value = 'Failed to start quiz: ${e.toString()}';
      _logger.e('Error starting quiz', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit an answer to a question
  void submitAnswer(int questionIndex, dynamic answer) {
    userResponses[questionIndex] = answer;
  }

  /// Submit completed quiz
  Future<bool> submitQuiz() async {
    try {
      isLoading.value = true;
      error.value = '';

      final attemptId = currentAttempt.value?['id'] ?? '';
      if (attemptId.isEmpty) {
        throw Exception('No active quiz attempt');
      }

      // Convert user responses to submission format
      final answers = Map<String, dynamic>.fromEntries(
        userResponses.entries.map((e) => MapEntry('q_${e.key}', e.value)),
      );

      final response = await apiService.submitQuizAttempt(attemptId, answers);

      if (response is Map && response['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to submit quiz: ${e.toString()}';
      _logger.e('Error submitting quiz', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get quiz attempt results
  Future<Map<String, dynamic>?> getQuizResults() async {
    try {
      isLoading.value = true;
      error.value = '';

      final attemptId = currentAttempt.value?['id'] ?? '';
      if (attemptId.isEmpty) {
        throw Exception('No quiz attempt found');
      }

      final response = await apiService.getQuizAttemptDetail(attemptId);
      return response is Map ? response : <String, dynamic>{};
    } catch (e) {
      error.value = 'Failed to get results: ${e.toString()}';
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get leaderboard for a quiz
  Future<void> getLeaderboard(String quizId) async {
    try {
      error.value = '';

      final response = await apiService.getLeaderboard(quizId);
      if (response is List) {
        leaderboard.value = List<Map<String, dynamic>>.from(
          response.map((item) => item as Map<String, dynamic>),
        );
      } else if (response is Map && response['success'] == true) {
        leaderboard.value = List<Map<String, dynamic>>.from(
          (response['data'] as List).map(
            (item) => item as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      error.value = 'Failed to load leaderboard: ${e.toString()}';
      _logger.e('Error loading leaderboard', error: e);
    }
  }

  /// Select a quiz from the list
  void selectQuiz(String quizId) {
    final selected = quizzes.firstWhereOrNull((q) => q['id'] == quizId);
    currentQuiz.value = selected;
  }

  /// Start countdown timer for quiz
  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (remainingTime.value > 0) {
        remainingTime.value--;
        return true;
      }
      // Auto-submit when time is up
      if (currentAttempt.value != null) {
        await submitQuiz();
      }
      return false;
    });
  }

  /// Load quizzes for all provided course IDs (dashboard overview use).
  Future<void> loadMyQuizzes(List<String> courseIds) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getMyQuizzes(courseIds);
      if (response is List) {
        quizzes.value = response
            .map<Map<String, dynamic>>(
              (q) => Map<String, dynamic>.from(q as Map),
            )
            .toList();
      }
    } catch (e) {
      error.value = 'Failed to load quizzes: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    userResponses.clear();
    super.onClose();
  }
}
