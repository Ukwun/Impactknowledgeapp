import 'package:get/get.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/courses/courses_list_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/lesson_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/payments/membership_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/landing_screen.dart';
import '../providers/auth_controller.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String landing = '/landing';

  // Auth Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  // App Routes
  static const String dashboard = '/dashboard';
  static const String courses = '/courses';
  static const String courseDetail = '/course-detail';
  static const String lesson = '/lesson';
  static const String achievements = '/achievements';
  static const String leaderboard = '/leaderboard';
  static const String membership = '/membership';
  static const String profile = '/profile';
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.landing,
      page: () => const LandingScreen(),
      transition: Transition.fadeIn,
    ),

    // Auth Pages
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),

    // App Pages
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.courses,
      page: () => const CoursesListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.courseDetail,
      page: () => const CourseDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.lesson,
      page: () => const LessonScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.membership,
      page: () => const MembershipScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),
  ];

  static String initial() {
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      return AppRoutes.dashboard;
    }
    return AppRoutes.login;
  }
}
