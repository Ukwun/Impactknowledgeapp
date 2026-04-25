import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_controller.dart';
import '../../../providers/course_controller.dart';
import '../../../providers/quiz_controller.dart';
import '../../../providers/assignment_controller.dart';
import '../../../providers/achievement_controller.dart';
import '../../../config/routes.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late AuthController authController;
  late CourseController courseController;
  late QuizController quizController;
  late AssignmentController assignmentController;
  late AchievementController achievementController;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    courseController = Get.find<CourseController>();
    quizController = Get.put(QuizController());
    assignmentController = Get.put(AssignmentController());
    achievementController = Get.find<AchievementController>();

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      courseController.fetchUserEnrollments(),
      achievementController.fetchUserAchievements(),
      courseController.fetchAllCourses(),
    ]);

    if (courseController.enrolledCourses.isNotEmpty) {
      final firstCourseId = courseController.enrolledCourses.first.courseId;
      await Future.wait([
        quizController.loadQuizzesForCourse(firstCourseId),
        assignmentController.loadAssignments(firstCourseId),
      ]);
    }
  }

  String _resolveCourseTitle(String courseId) {
    final matched = courseController.courses.firstWhereOrNull(
      (c) => c.id == courseId,
    );
    return matched?.title ?? 'Course';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting
            _buildHeader(),
            const SizedBox(height: 24),

            // Stats overview
            _buildStatsOverview(),
            const SizedBox(height: 24),

            // Enrolled courses section
            _buildEnrolledCoursesSection(),
            const SizedBox(height: 24),

            // Recent quizzes
            _buildRecentQuizzesSection(),
            const SizedBox(height: 24),

            // Assignments section
            _buildAssignmentsSection(),
            const SizedBox(height: 24),

            // Achievements section
            _buildAchievementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final firstName =
          authController.currentUser.value?.firstName ?? 'Student';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $firstName! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep up the momentum',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      );
    });
  }

  Widget _buildStatsOverview() {
    return Obx(() {
      final enrolledCount = courseController.enrolledCourses.length;
      final achievementCount = achievementController.userAchievements.length;
      final avgProgress = enrolledCount == 0
          ? 0
          : courseController.enrolledCourses
                    .map((e) => e.progressPercentage ?? 0)
                    .reduce((a, b) => a + b) /
                enrolledCount;

      return Container(
        decoration: AppTheme.darkCard(),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCard(
              icon: Icons.book_outlined,
              value: '$enrolledCount',
              label: 'Courses',
            ),
            _StatCard(
              icon: Icons.star_rounded,
              value: '$achievementCount',
              label: 'Badges',
            ),
            _StatCard(
              icon: Icons.trending_up,
              value: '${avgProgress.toStringAsFixed(0)}%',
              label: 'Progress',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEnrolledCoursesSection() {
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
                'View all →',
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
          if (courseController.enrolledCourses.isEmpty) {
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
                      'No courses yet',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: courseController.enrolledCourses.take(3).map((course) {
              final progress = (course.progressPercentage ?? 0).toInt();
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
                            _resolveCourseTitle(course.courseId),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (progress / 100).clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: AppTheme.dark400,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary500,
                        ),
                      ),
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

  Widget _buildRecentQuizzesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Quizzes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (quizController.quizzes.isEmpty) {
            return Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No quizzes available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }

          return Column(
            children: quizController.quizzes.take(2).map((quiz) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.darkCard(radius: 12),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppTheme.primary500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz['title'] ?? 'Quiz',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${quiz['totalQuestions']} questions',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textMuted,
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

  Widget _buildAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignments Due',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final overdue = assignmentController.getOverdueAssignments();

          if (overdue.isEmpty) {
            return Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'All caught up! 🎉',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }

          return Column(
            children: overdue.take(2).map((a) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] ?? 'Assignment',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Overdue',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final assignmentId = a['id']?.toString();
                        if (assignmentId != null && assignmentId.isNotEmpty) {
                          Get.toNamed(
                            AppRoutes.assignmentDetail,
                            arguments: assignmentId,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
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

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Badges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.achievements),
              child: const Text(
                'View all →',
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
          if (achievementController.userAchievements.isEmpty) {
            return Container(
              decoration: AppTheme.darkCard(),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Earn achievements by completing courses and quizzes',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievementController.userAchievements.take(6).map((
              achievement,
            ) {
              final achievementTitle =
                  achievement.achievement?.title ?? 'Badge';
              final displayText = achievementTitle.length > 10
                  ? achievementTitle.substring(0, 10)
                  : achievementTitle;
              return Container(
                width: 80,
                padding: const EdgeInsets.all(8),
                decoration: AppTheme.darkCard(radius: 12),
                child: Column(
                  children: [
                    Text(
                      achievement.achievement?.icon ?? '🏆',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
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
