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
  double _avgProgress = 0;
  int _pendingGrading = 0;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    courseController = Get.find<CourseController>();
    assignmentController = Get.put(AssignmentController());

    _loadInstructorData();
  }

  Future<void> _loadInstructorData() async {
    // Load instructor's courses
    courseController.getInstructorCourses();

    // Calculate stats
    _calculateStats();
  }

  void _calculateStats() {
    // Sum up students across all instructor's courses
    int totalStudents = 0;
    double totalProgress = 0;

    // This would come from the API in a real app
    // For now, using placeholder logic
    setState(() {
      _totalStudents = totalStudents;
      _avgProgress = totalProgress;
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
                value: '${courseController.instructorCourses.length}',
                label: 'Courses',
              ),
              _MetricCard(
                icon: Icons.people_outlined,
                value: '$_totalStudents',
                label: 'Students',
              ),
              _MetricCard(
                icon: Icons.trending_up,
                value: '${_avgProgress.toStringAsFixed(1)}%',
                label: 'Avg Progress',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.dark400),
          const SizedBox(height: 16),
          _PendingTasksCard(pendingCount: _pendingGrading),
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
          if (courseController.instructorCourses.isEmpty) {
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
            children: courseController.instructorCourses.map((course) {
              final enrollmentCount = course['enrollmentCount'] ?? 0;
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
                            course['title'] ?? 'Course',
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
                            course['is_published'] ? 'Published' : 'Draft',
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
                              '${AppRoutes.courseDetail}/${course['id']}',
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
          'Recent Submissions',
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
                label: 'Pending Grading',
                count: _pendingGrading,
                color: Colors.orange,
              ),
              const Divider(color: AppTheme.dark400),
              _SubmissionStatusRow(
                label: 'Submitted',
                count: 12,
                color: AppTheme.success500,
              ),
              const Divider(color: AppTheme.dark400),
              _SubmissionStatusRow(
                label: 'Graded',
                count: 28,
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
          'Top Performing Students',
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
              _StudentProgressRow(rank: 1, name: 'John Doe', progress: 95),
              const Divider(color: AppTheme.dark400),
              _StudentProgressRow(rank: 2, name: 'Jane Smith', progress: 92),
              const Divider(color: AppTheme.dark400),
              _StudentProgressRow(rank: 3, name: 'Mike Johnson', progress: 88),
            ],
          ),
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
                'Pending Tasks',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                '$pendingCount assignments waiting for grading',
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

  const _StudentProgressRow({
    required this.rank,
    required this.name,
    required this.progress,
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
            '$progress%',
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
