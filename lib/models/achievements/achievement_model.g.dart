// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      iconUrl: json['iconUrl'] as String?,
      unlockedIconUrl: json['unlockedIconUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      criteriaType: json['criteriaType'] as String?,
      criteriaValue: json['criteriaValue'] as String?,
      requirements: json['requirements'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'name': instance.name,
      'description': instance.description,
      'icon': instance.icon,
      'iconUrl': instance.iconUrl,
      'unlockedIconUrl': instance.unlockedIconUrl,
      'points': instance.points,
      'criteriaType': instance.criteriaType,
      'criteriaValue': instance.criteriaValue,
      'requirements': instance.requirements,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      achievement: json['achievement'] == null
          ? null
          : Achievement.fromJson(json['achievement'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'achievementId': instance.achievementId,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'achievement': instance.achievement,
    };

UserPoints _$UserPointsFromJson(Map<String, dynamic> json) => UserPoints(
      id: json['id'] as String,
      userId: json['userId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
      monthlyPoints: (json['monthlyPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$UserPointsToJson(UserPoints instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'totalPoints': instance.totalPoints,
      'monthlyPoints': instance.monthlyPoints,
      'currentStreak': instance.currentStreak,
      'level': instance.level,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

Leaderboard _$LeaderboardFromJson(Map<String, dynamic> json) => Leaderboard(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      totalPoints: (json['totalPoints'] as num).toInt(),
      points: (json['points'] as num?)?.toInt(),
      rank: (json['rank'] as num).toInt(),
      achievementCount: (json['achievementCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LeaderboardToJson(Leaderboard instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
      'totalPoints': instance.totalPoints,
      'points': instance.points,
      'rank': instance.rank,
      'achievementCount': instance.achievementCount,
    };
