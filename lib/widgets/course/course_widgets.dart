import 'package:flutter/material.dart';
import '../../models/courses/course_model.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool isEnrolled;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.isEnrolled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[300],
                child: course.coverImage != null
                    ? Image.network(course.coverImage!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category & Difficulty
                  Row(
                    children: [
                      if (course.category != null) ...[
                        Chip(
                          label: Text(
                            course.category!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[100],
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (course.difficultyLevel != null)
                        Chip(
                          label: Text(
                            course.difficultyLevel!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: _getDifficultyColor(
                            course.difficultyLevel!,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.enrollmentCount} enrolled',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (course.averageRating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.averageRating.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status Badge
                  if (isEnrolled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Enrolled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green[100]!;
      case 'intermediate':
        return Colors.orange[100]!;
      case 'advanced':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? backgroundColor;
  final Color? progressColor;

  const ProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.backgroundColor,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: backgroundColor ?? Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final bool isCompleted;
  final bool isLocked;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.onTap,
    this.isCompleted = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLocked ? null : onTap,
      enabled: !isLocked,
      leading: _getLessonIcon(),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLocked ? Colors.grey : Colors.black87,
        ),
      ),
      subtitle: Text(
        '${lesson.estimatedDuration} min',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isCompleted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : isLocked
          ? const Icon(Icons.lock, color: Colors.grey)
          : const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _getLessonIcon() {
    switch (lesson.lessonType) {
      case 'video':
        return const Icon(Icons.play_circle_outline, color: Colors.blue);
      case 'text':
        return const Icon(Icons.description_outlined, color: Colors.orange);
      case 'quiz':
        return const Icon(Icons.quiz_outlined, color: Colors.purple);
      case 'assignment':
        return const Icon(Icons.assignment_outlined, color: Colors.teal);
      default:
        return const Icon(Icons.book_outlined);
    }
  }
}

class ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;
  final double? progress;

  const ModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Module ${module.sequenceNumber}: ${module.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              if (module.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  module.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${module.lessonCount} lessons',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (progress != null)
                    Text(
                      '${(progress! * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                ProgressBar(progress: progress!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
