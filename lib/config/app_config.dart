// Application configuration for runtime endpoints and feature flags.

class AppConfig {
  /// API Configuration
  // PRODUCTION: Using Render.com cloud deployment
  // Backend URL: https://impactapp-backend.onrender.com
  static const String CLOUD_URL = 'https://impactapp-backend.onrender.com/';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: CLOUD_URL,
  );
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://impactapp-backend.onrender.com',
  );
  static const Duration apiTimeout = Duration(seconds: 60);

  /// App Info
  static const String appName = 'ImpactKnowledge';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.impactknowledge';

  /// Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;

  /// API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String coursesEndpoint = '/courses';
  static const String enrollmentsEndpoint = '/enrollments';
  static const String achievementsEndpoint = '/achievements';
  static const String leaderboardEndpoint = '/leaderboard';
  static const String paymentsEndpoint = '/payments';
  static const String onboardingEndpoint = '/onboarding';

  /// Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';
  static const String onboardingCompleted = 'onboarding_completed';

  /// Payment Configuration
  static const String stripePublishableKey =
      'STRIPE_PUBLISHABLE_KEY'; // Set from env if needed for future native flows

  /// Firebase Configuration
  static const bool useFirebase = false; // Set to true if using Firebase
}
