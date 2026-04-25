import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/course_controller.dart';
import 'video_lesson_player_screen.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../widgets/course/course_widgets.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  @override
  Widget build(BuildContext context) {
    final courseController = Get.find<CourseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson'), elevation: 0),
      body: Obx(() {
        if (courseController.isLoading.value) {
          return const LoadingIndicator();
        }

        if (courseController.moduleLessons.isEmpty) {
          return const EmptyState(title: 'No Lessons Available');
        }

        return Column(
          children: [
            // Lessons List
            Expanded(
              child: ListView.builder(
                itemCount: courseController.moduleLessons.length,
                itemBuilder: (context, index) {
                  final lesson = courseController.moduleLessons[index];
                  return GestureDetector(
                    onTap: () {
                      courseController.getLessonDetails(lesson.id);
                      _showLessonDetails(context, lesson);
                    },
                    child: LessonTile(
                      lesson: lesson,
                      onTap: () {
                        courseController.getLessonDetails(lesson.id);
                        _showLessonDetails(context, lesson);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showLessonDetails(BuildContext context, dynamic lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text('${lesson.estimatedDuration} mins'),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.bookmark_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_getLessonTypeLabel(lesson.lessonType)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (lesson.content != null) ...[
                      const Text(
                        'Content',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.content!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (lesson.lessonType == 'video' &&
                        lesson.videoUrl != null &&
                        lesson.videoUrl.toString().isNotEmpty) ...[
                      const Text(
                        'Video Lesson',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black87,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.ondemand_video_outlined,
                              size: 44,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Play this lesson inside the app',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VideoLessonPlayerScreen(
                                      title: lesson.title,
                                      videoUrl: lesson.videoUrl!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Open Video Player'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    CustomButton(
                      label: 'Mark as Complete',
                      onPressed: () {
                        final courseController = Get.find<CourseController>();
                        courseController.updateLessonProgress(
                          lesson.id,
                          status: 'completed',
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getLessonTypeLabel(String type) {
    switch (type) {
      case 'video':
        return 'Video';
      case 'text':
        return 'Text';
      case 'quiz':
        return 'Quiz';
      case 'assignment':
        return 'Assignment';
      default:
        return 'Lesson';
    }
  }
}
