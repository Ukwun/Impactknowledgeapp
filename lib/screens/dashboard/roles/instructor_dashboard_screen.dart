import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_controller.dart';
import '../../../providers/course_controller.dart';
import '../../../providers/assignment_controller.dart';
import '../../../config/routes.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  late AuthController authController;
  late CourseController courseController;
  late AssignmentController assignmentController;

  int _totalStudents = 0;
  double _avgRating = 0;
  int _publishedCourses = 0;
  int _draftCourses = 0;
  int _totalLessons = 0;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    courseController = Get.find<CourseController>();
    assignmentController = Get.put(AssignmentController());

    _loadInstructorData();
  }

  Future<void> _loadInstructorData() async {
    // Load courses and enrolled stats.
    await courseController.fetchAllCourses();
    await courseController.fetchUserEnrollments();

    // Calculate stats
    _calculateStats();
  }

  void _calculateStats() {
    int totalStudents = 0;
    int publishedCourses = 0;
    int draftCourses = 0;
    int totalLessons = 0;
    double ratingSum = 0;
    int ratingCount = 0;

    for (final course in courseController.courses) {
      totalStudents += course.enrollmentCount;
      totalLessons += course.lessonCount;

      if (course.isPublished) {
        publishedCourses++;
      } else {
        draftCourses++;
      }

      if (course.averageRating != null) {
        ratingSum += course.averageRating!;
        ratingCount++;
      }
    }

    setState(() {
      _totalStudents = totalStudents;
      _publishedCourses = publishedCourses;
      _draftCourses = draftCourses;
      _totalLessons = totalLessons;
      _avgRating = ratingCount > 0 ? (ratingSum / ratingCount) : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Key metrics
            _buildMetricsSection(),
            const SizedBox(height: 24),

            // Courses taught
            _buildCoursesSection(),
            const SizedBox(height: 24),

            // Pending submissions
            _buildPendingSubmissionsSection(),
            const SizedBox(height: 24),

            // Student progress
            _buildStudentProgressSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final firstName =
          authController.currentUser.value?.firstName ?? 'Instructor';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Prof. $firstName 👨‍🏫',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your courses and students',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      );
    });
  }

  Widget _buildMetricsSection() {
    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricCard(
                icon: Icons.school_outlined,
                value: '${courseController.courses.length}',
                label: 'Courses',
              ),
              _MetricCard(
                icon: Icons.people_outlined,
                value: '$_totalStudents',
                label: 'Students',
              ),
              _MetricCard(
                icon: Icons.star_outline,
                value: _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-',
                label: 'Avg Rating',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.dark400),
          const SizedBox(height: 16),
          _PendingTasksCard(pendingCount: _draftCourses),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.courses),
              child: const Text(
                'Manage all →',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (courseController.courses.isEmpty) {
            return Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No courses created',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: courseController.courses.map((course) {
              final enrollmentCount = course.enrollmentCount;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.darkCard(radius: 12),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.isPublished ? 'Published' : 'Draft',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primary500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '$enrollmentCount students',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Get.toNamed(
                              '${AppRoutes.courseDetail}/${course.id}',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text(
                            'Manage',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPendingSubmissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Pipeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.darkCard(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SubmissionStatusRow(
                label: 'Published Courses',
                count: _publishedCourses,
                color: Colors.orange,
              ),
              const Divider(color: AppTheme.dark400),
              _SubmissionStatusRow(
                label: 'Draft Courses',
                count: _draftCourses,
                color: AppTheme.success500,
              ),
              const Divider(color: AppTheme.dark400),
              _SubmissionStatusRow(
                label: 'Total Lessons',
                count: _totalLessons,
                color: AppTheme.primary500,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Courses by Enrollment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.darkCard(),
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (courseController.courses.isEmpty) {
              return const Text(
                'Create your first course to see performance data.',
                style: TextStyle(color: AppTheme.textMuted),
              );
            }

            final topCourses = [...courseController.courses]
              ..sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));

            final visible = topCourses.take(3).toList();
            return Column(
              children: [
                for (int i = 0; i < visible.length; i++) ...[
                  _StudentProgressRow(
                    rank: i + 1,
                    name: visible[i].title,
                    progress: visible[i].enrollmentCount,
                    suffix: 'students',
                  ),
                  if (i != visible.length - 1)
                    const Divider(color: AppTheme.dark400),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary500.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary500, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _PendingTasksCard extends StatelessWidget {
  final int pendingCount;

  const _PendingTasksCard({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.task_alt_outlined, color: AppTheme.warning500, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publishing Queue',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                '$pendingCount draft courses waiting for publish review',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppTheme.textMuted,
        ),
      ],
    );
  }
}

class _SubmissionStatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SubmissionStatusRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentProgressRow extends StatelessWidget {
  final int rank;
  final String name;
  final int progress;
  final String suffix;

  const _StudentProgressRow({
    required this.rank,
    required this.name,
    required this.progress,
    this.suffix = '%',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary500.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '$progress $suffix',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary500,
            ),
          ),
        ],
      ),
    );
  }
}
