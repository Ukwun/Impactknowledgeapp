import 'package:get/get.dart';
import '../models/achievements/achievement_model.dart';
import '../services/achievement/achievement_service.dart';
import '../config/service_locator.dart';

class AchievementController extends GetxController {
  final achievementService = getIt<AchievementService>();

  final achievements = RxList<Achievement>();
  final userAchievements = RxList<UserAchievement>();
  final userPoints = Rx<UserPoints?>(null);
  final leaderboard = RxList<Leaderboard>();
  final userRank = Rx<Leaderboard?>(null);
  final leaderboardAroundUser = RxList<Leaderboard>();

  final isLoading = false.obs;
  final errorMessage = RxString('');

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      fetchAllAchievements(),
      fetchUserAchievements(),
      fetchUserPoints(),
      fetchLeaderboard(),
      fetchUserRank(),
    ]);
  }

  Future<void> fetchAllAchievements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      achievements.value = await achievementService.getAllAchievements();
    } catch (e) {
      errorMessage.value = 'Failed to load achievements';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserAchievements({int page = 1, int pageSize = 20}) async {
    try {
      errorMessage.value = '';
      userAchievements.value = await achievementService.getUserAchievements(
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load user achievements';
    }
  }

  Future<void> fetchUserPoints() async {
    try {
      errorMessage.value = '';
      userPoints.value = await achievementService.getUserPoints();
    } catch (e) {
      errorMessage.value = 'Failed to load points';
    }
  }

  Future<void> fetchLeaderboard({
    int page = 1,
    int pageSize = 50,
    String timeframe = 'all',
  }) async {
    try {
      errorMessage.value = '';
      leaderboard.value = await achievementService.getLeaderboard(
        page: page,
        pageSize: pageSize,
        timeframe: timeframe,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load leaderboard';
    }
  }

  Future<void> fetchUserRank() async {
    try {
      errorMessage.value = '';
      userRank.value = await achievementService.getUserRank();
    } catch (e) {
      errorMessage.value = 'Failed to load rank';
    }
  }

  Future<void> fetchLeaderboardAroundUser({int radius = 5}) async {
    try {
      errorMessage.value = '';
      leaderboardAroundUser.value = await achievementService
          .getLeaderboardAroundUser(radius: radius);
    } catch (e) {
      errorMessage.value = 'Failed to load nearby users';
    }
  }

  Future<List<UserAchievement>> fetchUserAchievementsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await achievementService.getUserAchievementsByUserId(
        userId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      errorMessage.value = 'Failed to load user achievements';
      return [];
    }
  }

  Future<UserPoints?> fetchUserPointsByUserId(String userId) async {
    try {
      return await achievementService.getUserPointsByUserId(userId);
    } catch (e) {
      errorMessage.value = 'Failed to load user points';
      return null;
    }
  }

  void clearError() {
    errorMessage.value = '';
  }
}
