import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/course_controller.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../widgets/course/course_widgets.dart';
import '../../config/routes.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final courseController = Get.find<CourseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Course Details'), elevation: 0),
      body: Obx(() {
        if (courseController.isLoading.value) {
          return const LoadingIndicator();
        }

        final course = courseController.selectedCourse.value;
        if (course == null) {
          return const EmptyState(title: 'Course not found');
        }

        final isEnrolled = courseController.enrolledCourses.any(
          (e) => e.courseId == course.id,
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: course.coverImage != null
                    ? Image.network(course.coverImage!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey[500],
                        ),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meta Info
                    Row(
                      children: [
                        if (course.difficultyLevel != null)
                          Chip(
                            label: Text(course.difficultyLevel!),
                            backgroundColor: Colors.orange[100],
                          ),
                        const SizedBox(width: 12),
                        Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${course.enrollmentCount} enrolled'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (course.description != null) ...[
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Learning Outcomes
                    if (course.learningOutcomes != null) ...[
                      const Text(
                        'Learning Outcomes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.learningOutcomes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Modules
                    if (isEnrolled &&
                        courseController.courseModules.isNotEmpty) ...[
                      const Text(
                        'Course Modules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courseController.courseModules.length,
                        itemBuilder: (context, index) {
                          final module = courseController.courseModules[index];
                          return ModuleCard(
                            module: module,
                            onTap: () {
                              courseController.selectedModule.value = module;
                              courseController.getModuleLessons(module.id);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action Button
                    if (isEnrolled)
                      CustomButton(
                        label: 'Continue Learning',
                        onPressed: () {
                          if (courseController.courseModules.isNotEmpty) {
                            final firstModule =
                                courseController.courseModules.first;
                            courseController.getModuleLessons(firstModule.id);
                            Get.toNamed(AppRoutes.lesson);
                          }
                        },
                      )
                    else
                      CustomButton(
                        label: 'Enroll Now',
                        onPressed: () {
                          courseController.enrollInCourse(course.id);
                        },
                        isLoading: courseController.isLoading.value,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
