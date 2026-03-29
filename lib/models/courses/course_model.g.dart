// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      learningOutcomes: json['learningOutcomes'] as String?,
      category: json['category'] as String?,
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt(),
      difficultyLevel: json['difficultyLevel'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      enrollmentCount: (json['enrollmentCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      instructorId: json['instructorId'] as String,
      moduleCount: (json['moduleCount'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverImage': instance.coverImage,
      'learningOutcomes': instance.learningOutcomes,
      'category': instance.category,
      'estimatedDuration': instance.estimatedDuration,
      'difficultyLevel': instance.difficultyLevel,
      'isPublished': instance.isPublished,
      'enrollmentCount': instance.enrollmentCount,
      'averageRating': instance.averageRating,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'instructorId': instance.instructorId,
      'moduleCount': instance.moduleCount,
      'lessonCount': instance.lessonCount,
    };

Module _$ModuleFromJson(Map<String, dynamic> json) => Module(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      sequenceNumber: (json['sequenceNumber'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ModuleToJson(Module instance) => <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'title': instance.title,
      'description': instance.description,
      'sequenceNumber': instance.sequenceNumber,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lessonCount': instance.lessonCount,
    };

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      videoUrl: json['videoUrl'] as String?,
      sequenceNumber: (json['sequenceNumber'] as num).toInt(),
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt() ?? 0,
      requiresCompletion: json['requiresCompletion'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lessonType: json['lessonType'] as String,
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'moduleId': instance.moduleId,
      'title': instance.title,
      'content': instance.content,
      'videoUrl': instance.videoUrl,
      'sequenceNumber': instance.sequenceNumber,
      'estimatedDuration': instance.estimatedDuration,
      'requiresCompletion': instance.requiresCompletion,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lessonType': instance.lessonType,
    };

Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) => Enrollment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      status: json['status'] as String,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble(),
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$EnrollmentToJson(Enrollment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'courseId': instance.courseId,
      'status': instance.status,
      'progressPercentage': instance.progressPercentage,
      'enrolledAt': instance.enrolledAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

LessonProgress _$LessonProgressFromJson(Map<String, dynamic> json) =>
    LessonProgress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lessonId: json['lessonId'] as String,
      status: json['status'] as String,
      score: (json['score'] as num?)?.toDouble(),
      attemptCount: (json['attemptCount'] as num?)?.toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LessonProgressToJson(LessonProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'lessonId': instance.lessonId,
      'status': instance.status,
      'score': instance.score,
      'attemptCount': instance.attemptCount,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
