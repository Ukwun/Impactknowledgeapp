import 'package:get_it/get_it.dart';
import '../services/api/api_service.dart';
import '../services/auth/auth_service.dart';
import '../services/course/course_service.dart';
import '../services/achievement/achievement_service.dart';
import '../services/payment/payment_service.dart';
import '../services/dashboard/dashboard_cache_service.dart';
import '../services/dashboard/dashboard_service.dart';
import '../services/dashboard/dashboard_sse_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Register API Service
  if (!getIt.isRegistered<ApiService>()) {
    getIt.registerSingleton<ApiService>(ApiService());
  }

  // Register Services
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerSingleton<AuthService>(
      AuthService(apiService: getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<CourseService>()) {
    getIt.registerSingleton<CourseService>(
      CourseService(apiService: getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<AchievementService>()) {
    getIt.registerSingleton<AchievementService>(
      AchievementService(apiService: getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<PaymentService>()) {
    getIt.registerSingleton<PaymentService>(
      PaymentService(apiService: getIt<ApiService>()),
    );
  }

  if (!getIt.isRegistered<DashboardCacheService>()) {
    getIt.registerSingleton<DashboardCacheService>(DashboardCacheService());
  }

  if (!getIt.isRegistered<DashboardService>()) {
    getIt.registerSingleton<DashboardService>(
      DashboardService(
        apiService: getIt<ApiService>(),
        cacheService: getIt<DashboardCacheService>(),
      ),
    );
  }

  if (!getIt.isRegistered<DashboardSseService>()) {
    getIt.registerSingleton<DashboardSseService>(DashboardSseService());
  }
}
