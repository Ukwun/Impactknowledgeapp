import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

@JsonSerializable()
class Achievement {
  final String id;
  final String title;
  final String? name; // Alias for title
  final String? description;
  final String? icon; // Alias for iconUrl
  final String? iconUrl;
  final String? unlockedIconUrl;
  final int? points;
  final String?
  criteriaType; // 'course_completion', 'quiz_score', 'streak', 'custom'
  final String? criteriaValue;
  final String? requirements;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Achievement({
    required this.id,
    required this.title,
    String? name,
    this.description,
    this.icon,
    this.iconUrl,
    this.unlockedIconUrl,
    this.points = 0,
    this.criteriaType,
    this.criteriaValue,
    this.requirements,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  }) : name = name ?? title;

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

@JsonSerializable()
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final DateTime createdAt;
  final Achievement? achievement; // Nested achievement details

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.createdAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      _$UserAchievementFromJson(json);

  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);
}

@JsonSerializable()
class UserPoints {
  final String id;
  final String userId;
  final int totalPoints;
  final int monthlyPoints;
  final int currentStreak;
  final int level;
  final DateTime lastUpdated;

  UserPoints({
    required this.id,
    required this.userId,
    required this.totalPoints,
    this.monthlyPoints = 0,
    this.currentStreak = 0,
    this.level = 1,
    required this.lastUpdated,
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) =>
      _$UserPointsFromJson(json);

  Map<String, dynamic> toJson() => _$UserPointsToJson(this);
}

@JsonSerializable()
class Leaderboard {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int totalPoints;
  final int points; // Alias for totalPoints
  final int rank;
  final int achievementCount;

  Leaderboard({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalPoints,
    int? points,
    required this.rank,
    this.achievementCount = 0,
  }) : points = points ?? totalPoints;

  factory Leaderboard.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderboardToJson(this);
}
