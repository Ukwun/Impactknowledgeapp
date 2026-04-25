import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../providers/course_controller.dart';
import '../../config/routes.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  late final CourseController _courseController;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _courseController = Get.find<CourseController>();
    _authController = Get.find<AuthController>();
    _loadManagedCourses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is Map && args['action'] is String) {
        final action = args['action'] as String;
        if (action == 'create') {
          _showCreateCourseDialog();
        }
      }
    });
  }

  Future<void> _loadManagedCourses() async {
    final userId = _authController.currentUser.value?.id;
    if (userId == null || userId.isEmpty) return;
    await _courseController.fetchInstructorCourses(userId);
  }

  Future<void> _showCreateCourseDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final levelController = TextEditingController(text: 'beginner');
    final durationController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: levelController,
                  decoration: const InputDecoration(labelText: 'Level'),
                ),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (hours)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final success = await _courseController.createCourse(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  category: categoryController.text.trim().isEmpty
                      ? null
                      : categoryController.text.trim(),
                  level: levelController.text.trim().isEmpty
                      ? null
                      : levelController.text.trim(),
                  durationHours: int.tryParse(durationController.text.trim()),
                );
                if (success && mounted) {
                  Get.back();
                  await _loadManagedCourses();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditCourseDialog(String courseId) async {
    final matches = _courseController.courses.where((c) => c.id == courseId);
    if (matches.isEmpty) return;
    final course = matches.first;

    final titleController = TextEditingController(text: course.title);
    final descriptionController = TextEditingController(
      text: course.description ?? '',
    );
    final categoryController = TextEditingController(
      text: course.category ?? '',
    );
    final levelController = TextEditingController(
      text: course.difficultyLevel ?? '',
    );
    final durationController = TextEditingController(
      text: course.estimatedDuration?.toString() ?? '',
    );
    bool isPublished = course.isPublished;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    TextField(
                      controller: levelController,
                      decoration: const InputDecoration(labelText: 'Level'),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (hours)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isPublished,
                      onChanged: (value) =>
                          setDialogState(() => isPublished = value),
                      title: const Text('Published'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final success = await _courseController.updateCourse(
                      courseId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: categoryController.text.trim(),
                      level: levelController.text.trim(),
                      durationHours: int.tryParse(
                        durationController.text.trim(),
                      ),
                      isPublished: isPublished,
                    );
                    if (success && mounted) {
                      Get.back();
                      await _loadManagedCourses();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAnalytics(String courseId) async {
    final data = await _courseController.fetchCourseAnalytics(courseId);
    if (data == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('View Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Enrollments: ${data['totalEnrollments'] ?? 0}'),
            Text('Completed: ${data['completedEnrollments'] ?? 0}'),
            Text('Completion Rate: ${data['completionRate'] ?? 0}%'),
            Text('Modules: ${data['moduleCount'] ?? 0}'),
            Text('Lessons: ${data['lessonCount'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showReports(String courseId) async {
    final data = await _courseController.fetchCourseReports(courseId);
    if (data == null || !mounted) return;

    final summary = data['summary'] is Map<String, dynamic>
        ? data['summary'] as Map<String, dynamic>
        : <String, dynamic>{};

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('View Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Learners: ${summary['totalLearners'] ?? 0}'),
            Text('Active Learners: ${summary['activeLearners'] ?? 0}'),
            Text('Completed Learners: ${summary['completedLearners'] ?? 0}'),
            Text('Average Progress: ${summary['avgProgress'] ?? 0}%'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showMessageStudentsDialog(String courseId) async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              if (subject.isEmpty || message.isEmpty) return;

              final result = await _courseController.messageCourseStudents(
                courseId,
                subject: subject,
                message: message,
              );
              if (result != null && mounted) {
                Get.back();
                final recipients = result['recipients'] ?? 0;
                Get.snackbar(
                  'Announcement sent',
                  'Delivered to $recipients learners',
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilitator Course Management'),
        actions: [
          IconButton(
            onPressed: _showCreateCourseDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Course',
          ),
        ],
      ),
      body: Obx(() {
        if (_courseController.isLoading.value &&
            _courseController.courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_courseController.courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No managed courses yet'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _showCreateCourseDialog,
                  child: const Text('Create Course'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadManagedCourses,
          child: ListView.builder(
            itemCount: _courseController.courses.length,
            itemBuilder: (context, index) {
              final course = _courseController.courses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              course.isPublished ? 'Published' : 'Draft',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(course.description ?? 'No description'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showCreateCourseDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Course'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showEditCourseDialog(course.id),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Course'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showAnalytics(course.id),
                            icon: const Icon(Icons.analytics),
                            label: const Text('View Analytics'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showMessageStudentsDialog(course.id),
                            icon: const Icon(Icons.message_outlined),
                            label: const Text('Message Students'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showReports(course.id),
                            icon: const Icon(Icons.assessment_outlined),
                            label: const Text('View Reports'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Get.toNamed(
                              AppRoutes.lessonEditor,
                              arguments: {'courseId': course.id},
                            ),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Author Lesson Content'),
                          ),
                          TextButton.icon(
                            onPressed: () => _courseController
                                .deleteManagedCourse(course.id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
