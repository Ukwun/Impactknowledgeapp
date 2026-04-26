import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';

/// Firebase Analytics Service
/// Centralizes all analytics event tracking and error reporting
class AnalyticsService {
  static final _instance = AnalyticsService._internal();
  static final _logger = Logger();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// 📊 User Authentication Events

  void logSignup({
    required String userId,
    required String userRole,
    required String email,
  }) {
    _analytics.logSignUp(signUpMethod: userRole);
    _analytics.logEvent(
      name: 'user_signup',
      parameters: {
        'user_id': userId,
        'role': userRole,
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 User signup tracked: $userRole');
  }

  void logLogin({required String userId, required String userRole}) {
    _analytics.logEvent(
      name: 'user_login',
      parameters: {
        'user_id': userId,
        'role': userRole,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 User login tracked: $userId');
  }

  void logLogout({required String userId}) {
    _analytics.logEvent(
      name: 'user_logout',
      parameters: {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 User logout tracked: $userId');
  }

  /// 🎓 Learning Events

  void logEnrollCourse({
    required String userId,
    required String courseId,
    required String courseName,
  }) {
    _analytics.logEvent(
      name: 'enroll_course',
      parameters: {
        'user_id': userId,
        'course_id': courseId,
        'course_name': courseName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Course enrollment tracked: $courseName');
  }

  void logCompleteLesson({
    required String userId,
    required String lessonId,
    required String lessonName,
    required String courseId,
    required int timeSpentSeconds,
  }) {
    _analytics.logEvent(
      name: 'complete_lesson',
      parameters: {
        'user_id': userId,
        'lesson_id': lessonId,
        'lesson_name': lessonName,
        'course_id': courseId,
        'time_spent_seconds': timeSpentSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Lesson completion tracked: $lessonName');
  }

  void logCompleteCourse({
    required String userId,
    required String courseId,
    required String courseName,
    required double completionPercentage,
  }) {
    _analytics.logEvent(
      name: 'complete_course',
      parameters: {
        'user_id': userId,
        'course_id': courseId,
        'course_name': courseName,
        'completion_percentage': completionPercentage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Course completion tracked: $courseName');
  }

  void logQuizAttempt({
    required String userId,
    required String quizId,
    required String quizName,
    required int score,
    required int maxScore,
    required int timeSpentSeconds,
  }) {
    _analytics.logEvent(
      name: 'quiz_attempt',
      parameters: {
        'user_id': userId,
        'quiz_id': quizId,
        'quiz_name': quizName,
        'score': score,
        'max_score': maxScore,
        'percentage': (score / maxScore * 100).toInt(),
        'time_spent_seconds': timeSpentSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i(
      '📊 Quiz attempt tracked: $quizName (${(score / maxScore * 100).toInt()}%)',
    );
  }

  /// 🏆 Gamification Events

  void logUnlockAchievement({
    required String userId,
    required String achievementId,
    required String achievementName,
    required int pointsEarned,
  }) {
    _analytics.logEvent(
      name: 'unlock_achievement',
      parameters: {
        'user_id': userId,
        'achievement_id': achievementId,
        'achievement_name': achievementName,
        'points_earned': pointsEarned,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Achievement unlocked: $achievementName (+$pointsEarned pts)');
  }

  void logLevelUp({
    required String userId,
    required int newLevel,
    required int totalPoints,
  }) {
    _analytics.logEvent(
      name: 'level_up',
      parameters: {
        'user_id': userId,
        'new_level': newLevel,
        'total_points': totalPoints,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Level up tracked: Level $newLevel');
  }

  void logStreakMilestone({
    required String userId,
    required int currentStreak,
  }) {
    _analytics.logEvent(
      name: 'streak_milestone',
      parameters: {
        'user_id': userId,
        'current_streak': currentStreak,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Streak milestone: $currentStreak days');
  }

  /// 💳 Payment Events

  void logPaymentAttempt({
    required String userId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required String tier,
  }) {
    _analytics.logEvent(
      name: 'payment_attempt',
      parameters: {
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod,
        'tier': tier,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 Payment attempt: $amount $currency ($tier)');
  }

  void logPaymentSuccess({
    required String userId,
    required double amount,
    required String currency,
    required String tier,
    required String transactionId,
  }) {
    _analytics.logPurchase(
      currency: currency,
      value: amount,
      items: [
        AnalyticsEventItem(
          itemId: transactionId,
          itemName: 'Membership: $tier',
          itemCategory: 'membership',
          price: amount,
        ),
      ],
    );
    _logger.i('📊 Payment successful: $amount $currency');
  }

  /// 📱 User Engagement Events

  void logScreenView({required String screenName}) {
    _analytics.logScreenView(screenName: screenName);
    _logger.i('📊 Screen viewed: $screenName');
  }

  void logFeatureUsage({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) {
    final typedParams = <String, Object>{};
    parameters?.forEach((key, value) {
      if (value != null) {
        typedParams[key] = value;
      }
    });

    _analytics.logEvent(
      name: featureName,
      parameters: typedParams.isEmpty ? null : typedParams,
    );
    _logger.i('📊 Feature used: $featureName');
  }

  void logUserEngagement({
    required String userId,
    required String engagementType,
    required int durationSeconds,
  }) {
    _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'user_id': userId,
        'engagement_type': engagementType,
        'duration_seconds': durationSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.i('📊 User engagement: $engagementType ($durationSeconds sec)');
  }

  /// ❌ Error & Crash Reporting

  void reportError({
    required String errorCode,
    required String errorMessage,
    required String stackTrace,
  }) {
    _crashlytics.recordError(
      Exception(errorMessage),
      StackTrace.fromString(stackTrace),
      reason: errorCode,
      fatal: false,
    );

    _analytics.logEvent(
      name: 'error_reported',
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    _logger.e('❌ Error reported: $errorCode - $errorMessage');
  }

  void reportCrash({required String exception, required String stackTrace}) {
    _crashlytics.recordError(
      Exception(exception),
      StackTrace.fromString(stackTrace),
      fatal: true,
    );
    _logger.e('💥 Crash reported: $exception');
  }

  /// 👤 User Property Setting

  void setUserProperties({
    required String userId,
    required String userRole,
    required String email,
    String? country,
    String? joinDate,
  }) {
    // Note: setUserId is deprecated in newer Firebase versions
    // Using setUserProperty instead for user identification
    _analytics.setUserProperty(name: 'user_id', value: userId);
    _analytics.setUserProperty(name: 'user_role', value: userRole);
    _analytics.setUserProperty(name: 'email', value: email);
    if (country != null) {
      _analytics.setUserProperty(name: 'country', value: country);
    }
    if (joinDate != null) {
      _analytics.setUserProperty(name: 'join_date', value: joinDate);
    }
    _logger.i('📊 User properties set: $userId ($userRole)');
  }

  void clearUserProperties() {
    // Clear user properties by setting to empty
    _analytics.setUserProperty(name: 'user_id', value: '');
    _logger.i('📊 User properties cleared');
  }
}
