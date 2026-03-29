import '../api/api_service.dart';
import '../../models/achievements/achievement_model.dart';

class AchievementService {
  final ApiService apiService;

  AchievementService({required this.apiService});

  // Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await apiService.get<List<dynamic>>('/achievements');
      return response
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get achievement by ID
  Future<Achievement> getAchievementById(String achievementId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/achievements/$achievementId',
      );
      return Achievement.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get user achievements
  Future<List<UserAchievement>> getUserAchievements({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/users/achievements',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return response
          .map((item) => UserAchievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get user points
  Future<UserPoints> getUserPoints() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/users/points',
      );
      return UserPoints.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get leaderboard
  Future<List<Leaderboard>> getLeaderboard({
    int page = 1,
    int pageSize = 50,
    String timeframe = 'all', // 'all', 'monthly', 'weekly'
  }) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/leaderboard',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          'timeframe': timeframe,
        },
      );
      return response
          .map((item) => Leaderboard.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get user rank
  Future<Leaderboard> getUserRank() async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/leaderboard/me',
      );
      return Leaderboard.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get leaderboard around user
  Future<List<Leaderboard>> getLeaderboardAroundUser({int radius = 5}) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/leaderboard/around-me',
        queryParameters: {'radius': radius},
      );
      return response
          .map((item) => Leaderboard.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get specific user achievements
  Future<List<UserAchievement>> getUserAchievementsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiService.get<List<dynamic>>(
        '/users/$userId/achievements',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return response
          .map((item) => UserAchievement.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get specific user points
  Future<UserPoints> getUserPointsByUserId(String userId) async {
    try {
      final response = await apiService.get<Map<String, dynamic>>(
        '/users/$userId/points',
      );
      return UserPoints.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
