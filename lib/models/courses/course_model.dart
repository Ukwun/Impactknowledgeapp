import 'package:json_annotation/json_annotation.dart';

part 'course_model.g.dart';

@JsonSerializable()
class Course {
  final String id;
  final String title;
  final String? description;
  final String? coverImage;
  final String? learningOutcomes;
  final String? category;
  final int? estimatedDuration;
  final String? difficultyLevel; // 'beginner', 'intermediate', 'advanced'
  final bool isPublished;
  final int enrollmentCount;
  final double? averageRating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String instructorId;
  final int moduleCount;
  final int lessonCount;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.learningOutcomes,
    this.category,
    this.estimatedDuration,
    this.difficultyLevel,
    this.isPublished = false,
    this.enrollmentCount = 0,
    this.averageRating,
    required this.createdAt,
    required this.updatedAt,
    required this.instructorId,
    this.moduleCount = 0,
    this.lessonCount = 0,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}

@JsonSerializable()
class Module {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int sequenceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int lessonCount;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.sequenceNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lessonCount = 0,
  });

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);

  Map<String, dynamic> toJson() => _$ModuleToJson(this);
}

@JsonSerializable()
class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String? content;
  final String? videoUrl;
  final int sequenceNumber;
  final int estimatedDuration;
  final bool requiresCompletion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lessonType; // 'video', 'text', 'quiz', 'assignment'

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    this.content,
    this.videoUrl,
    required this.sequenceNumber,
    this.estimatedDuration = 0,
    this.requiresCompletion = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lessonType,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

  Map<String, dynamic> toJson() => _$LessonToJson(this);
}

@JsonSerializable()
class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final String status; // 'active', 'completed', 'dropped'
  final double? progressPercentage;
  final DateTime enrolledAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    this.progressPercentage,
    required this.enrolledAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentToJson(this);
}

@JsonSerializable()
class LessonProgress {
  final String id;
  final String userId;
  final String lessonId;
  final String status; // 'not_started', 'in_progress', 'completed'
  final double? score;
  final int? attemptCount;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  LessonProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.status,
    this.score,
    this.attemptCount,
    required this.startedAt,
    this.completedAt,
    required this.updatedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) =>
      _$LessonProgressFromJson(json);

  Map<String, dynamic> toJson() => _$LessonProgressToJson(this);
}
