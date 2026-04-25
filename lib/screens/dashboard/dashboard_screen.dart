import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/role_dashboard_resolver.dart';
import '../../config/service_locator.dart';
import '../../providers/auth_controller.dart';
import '../../providers/course_controller.dart';
import '../../providers/achievement_controller.dart';
import '../../services/dashboard/dashboard_service.dart';
import '../../widgets/common/custom_widgets.dart';
import '../../widgets/course/course_widgets.dart';
import '../../config/routes.dart';
import '../../config/app_theme.dart';
import 'roles/role_dashboard_switcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Learner dashboard snapshot from backend (assignments, quizzes, stats).
  Map<String, dynamic> _dashboardData = {};
  bool _dashboardLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLearnerDashboard();
  }

  Future<void> _loadLearnerDashboard() async {
    try {
      final dashboardService = getIt<DashboardService>();
      final data = await dashboardService.fetchLearnerDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = (data['data'] is Map<String, dynamic>)
              ? data['data'] as Map<String, dynamic>
              : data;
          _dashboardLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dashboardLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final courseController = Get.find<CourseController>();
    final achievementController = Get.find<AchievementController>();

    return Obx(() {
      final role = authController.currentUser.value?.role;
      final usesLearnerDashboard = RoleDashboardResolver.usesLearnerDashboard(
        role,
      );

      return Scaffold(
        backgroundColor: AppTheme.dark800,
        body: SafeArea(
          child: usesLearnerDashboard
              ? _buildBody(
                  authController,
                  courseController,
                  achievementController,
                )
              : RoleDashboardSwitcher(
                  role: role!,
                  firstName:
                      authController.currentUser.value?.firstName ?? 'User',
                ),
        ),
        bottomNavigationBar: usesLearnerDashboard ? _buildBottomNav() : null,
      );
    });
  }

  Widget _buildBody(
    AuthController authController,
    CourseController courseController,
    AchievementController achievementController,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(authController, courseController);
      case 1:
        return _buildCoursesTab(courseController);
      case 2:
        return _buildAchievementsTab(achievementController);
      case 3:
        return _buildProfileTab(authController);
      default:
        return _buildHomeTab(authController, courseController);
    }
  }

  Widget _buildHomeTab(
    AuthController authController,
    CourseController courseController,
  ) {
    return RefreshIndicator(
      color: AppTheme.primary400,
      backgroundColor: AppTheme.dark700,
      onRefresh: _loadLearnerDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            DecoratedBox(
              decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Obx(
                          () => Text(
                            authController.currentUser.value?.firstName ??
                                'Learner',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.toNamed(AppRoutes.globalSearch),
                          icon: const Icon(
                            Icons.search,
                            color: AppTheme.textLight,
                          ),
                          tooltip: 'Global Search',
                        ),
                        IconButton(
                          onPressed: () => Get.toNamed(AppRoutes.notifications),
                          icon: const Icon(
                            Icons.notifications_none,
                            color: AppTheme.textLight,
                          ),
                          tooltip: 'Notifications',
                        ),
                        Obx(() {
                          final user = authController.currentUser.value;
                          final initials = _initials(
                            user?.firstName,
                            user?.lastName,
                          );
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Strip ─────────────────────────────────────────────────
            _buildStatsStrip(),

            // ── Assignments Due ──────────────────────────────────────────────
            _buildAssignmentsDue(),

            // ── Available Quizzes ────────────────────────────────────────────
            _buildAvailableQuizzes(),

            // ── Continue Learning ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue Learning',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (courseController.enrolledCourses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.darkCard(radius: 12),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              color: AppTheme.textMuted,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'No enrolled courses yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: courseController.enrolledCourses.length,
                        itemBuilder: (context, index) {
                          final enrollment =
                              courseController.enrolledCourses[index];
                          final matchedCourse = courseController.courses
                              .firstWhereOrNull(
                                (c) => c.id == enrollment.courseId,
                              );
                          final progress =
                              (enrollment.progressPercentage ?? 0.0).clamp(
                                0.0,
                                100.0,
                              );
                          return GestureDetector(
                            onTap: () {
                              courseController.getCourseDetails(
                                enrollment.courseId,
                              );
                              Get.toNamed(AppRoutes.courseDetail);
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: AppTheme.darkCard(radius: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary500.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.book_outlined,
                                          color: AppTheme.primary400,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      matchedCourse?.title ?? 'Course',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    // Progress bar
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${progress.toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        Text(
                                          enrollment.status == 'completed'
                                              ? '✓ Done'
                                              : 'In Progress',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                enrollment.status == 'completed'
                                                ? Colors.greenAccent
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress / 100,
                                        minHeight: 5,
                                        backgroundColor: AppTheme.dark400,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              AppTheme.primary500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Browse Courses ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Browse Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primary400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (courseController.isLoading.value) {
                      return const LoadingIndicator();
                    }

                    if (courseController.courses.isEmpty) {
                      return const EmptyState(
                        title: 'No Courses Available',
                        subtitle: 'Check back later for new courses',
                      );
                    }

                    return Column(
                      children: courseController.courses
                          .take(3)
                          .map(
                            (course) => CourseCard(
                              course: course,
                              onTap: () {
                                courseController.getCourseDetails(course.id);
                                Get.toNamed(AppRoutes.courseDetail);
                              },
                            ),
                          )
                          .toList(),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Stats Strip ────────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    if (_dashboardLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: LinearProgressIndicator(
          color: AppTheme.primary500,
          backgroundColor: AppTheme.dark400,
        ),
      );
    }

    final enrollmentCount = _dashboardData['enrollmentCount'] ?? 0;
    final pendingAssignments =
        (_dashboardData['pendingAssignments'] as List?)?.length ?? 0;
    final availableQuizzes =
        (_dashboardData['availableQuizzes'] as List?)?.length ?? 0;
    final avgProgress = _dashboardData['avgProgress'] ?? 0;
    final achievementCount = _dashboardData['achievementCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _statChip(
            Icons.school_outlined,
            '$enrollmentCount',
            'Courses',
            AppTheme.primary500,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.assignment_late_outlined,
            '$pendingAssignments',
            'Due',
            pendingAssignments > 0 ? Colors.orangeAccent : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.quiz_outlined,
            '$availableQuizzes',
            'Quizzes',
            AppTheme.secondary400,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.emoji_events_outlined,
            '$achievementCount',
            'Badges',
            AppTheme.secondary500,
          ),
          const SizedBox(width: 8),
          _statChip(
            Icons.trending_up,
            '$avgProgress%',
            'Avg',
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: AppTheme.darkCard(radius: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Assignments Due ─────────────────────────────────────────────────────────
  Widget _buildAssignmentsDue() {
    final rawList = _dashboardData['pendingAssignments'];
    if (rawList == null) return const SizedBox.shrink();
    final assignments = (rawList as List).cast<Map<String, dynamic>>().toList();
    if (assignments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                color: Colors.orangeAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Assignments Due',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${assignments.length}',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...assignments.take(3).map((a) => _assignmentRow(a)),
        ],
      ),
    );
  }

  Widget _assignmentRow(Map<String, dynamic> assignment) {
    final isOverdue = assignment['is_overdue'] == true;
    final dueDate = _parseDueDate(assignment['due_date']?.toString());
    final urgencyColor = isOverdue ? Colors.redAccent : Colors.orangeAccent;
    final assignmentId = assignment['id']?.toString() ?? '';
    final courseId = assignment['course_id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (assignmentId.isNotEmpty) {
          Get.toNamed(
            AppRoutes.assignmentDetail,
            arguments: {'assignmentId': assignmentId, 'courseId': courseId},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.darkCard(radius: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOverdue ? Icons.assignment_late : Icons.assignment_outlined,
                color: urgencyColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment['title']?.toString() ?? 'Assignment',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assignment['course_title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isOverdue ? 'Overdue' : 'Due',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgencyColor,
                  ),
                ),
                Text(
                  dueDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        urgencyColor.withValues(alpha: 0.8),
                        urgencyColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Available Quizzes ───────────────────────────────────────────────────────
  Widget _buildAvailableQuizzes() {
    final rawList = _dashboardData['availableQuizzes'];
    if (rawList == null) return const SizedBox.shrink();
    final quizzes = (rawList as List).cast<Map<String, dynamic>>().toList();
    if (quizzes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.quiz_outlined,
                color: AppTheme.secondary400,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quizzes Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondary400.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${quizzes.length}',
                  style: const TextStyle(
                    color: AppTheme.secondary400,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...quizzes.take(3).map((q) => _quizRow(q)),
        ],
      ),
    );
  }

  Widget _quizRow(Map<String, dynamic> quiz) {
    final questionCount =
        int.tryParse(quiz['question_count']?.toString() ?? '0') ?? 0;
    final timeLimit = quiz['time_limit'];
    final timeLimitStr = timeLimit != null ? '${timeLimit}m' : '—';
    final quizId = quiz['id']?.toString() ?? '';
    final courseId = quiz['course_id']?.toString() ?? '';
    final timesPassed =
        int.tryParse(quiz['times_passed']?.toString() ?? '0') ?? 0;
    final alreadyPassed = timesPassed > 0;

    return GestureDetector(
      onTap: () {
        if (quizId.isNotEmpty) {
          Get.toNamed(
            AppRoutes.quiz,
            arguments: {'quizId': quizId, 'courseId': courseId},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.darkCard(radius: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.secondary500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alreadyPassed ? Icons.check_circle_outline : Icons.quiz,
                color: alreadyPassed
                    ? Colors.greenAccent
                    : AppTheme.secondary400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quiz['title']?.toString() ?? 'Quiz',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quiz['course_title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$questionCount Qs',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      timeLimitStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: alreadyPassed
                          ? [
                              Colors.greenAccent.withValues(alpha: 0.7),
                              Colors.greenAccent,
                            ]
                          : [
                              AppTheme.secondary500.withValues(alpha: 0.8),
                              AppTheme.secondary400,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alreadyPassed ? 'Retry' : 'Take Quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format a due date string to a short human-readable form.
  String _parseDueDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      if (diff.isNegative) {
        final days = diff.inDays.abs();
        if (days == 0) return 'Today';
        if (days == 1) return 'Yesterday';
        return '${days}d ago';
      } else {
        if (diff.inHours < 24) return 'Today';
        if (diff.inDays == 1) return 'Tomorrow';
        return 'In ${diff.inDays}d';
      }
    } catch (_) {
      return raw.substring(0, raw.length.clamp(0, 10));
    }
  }

  Widget _buildCoursesTab(CourseController courseController) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Courses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) =>
                    courseController.searchQuery.value = value,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.darkInput(
                  hint: 'Search courses...',
                  prefix: const Icon(
                    Icons.search,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (courseController.isLoading.value) {
              return const LoadingIndicator();
            }

            if (courseController.courses.isEmpty) {
              return const EmptyState(title: 'No Courses Found');
            }

            return ListView.builder(
              itemCount: courseController.courses.length,
              itemBuilder: (context, index) {
                final course = courseController.courses[index];
                return CourseCard(
                  course: course,
                  onTap: () {
                    courseController.getCourseDetails(course.id);
                    Get.toNamed(AppRoutes.courseDetail);
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab(AchievementController achievementController) {
    return Obx(() {
      if (achievementController.isLoading.value) {
        return const LoadingIndicator();
      }

      if (achievementController.userAchievements.isEmpty &&
          achievementController.achievements.isEmpty) {
        return const EmptyState(
          title: 'No Achievements Yet',
          subtitle: 'Complete courses and lessons to unlock achievements',
        );
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (achievementController.userPoints.value != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary600, AppTheme.primary500],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${achievementController.userPoints.value!.totalPoints}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.star_rounded,
                            size: 52,
                            color: AppTheme.secondary400,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Badges',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: achievementController.userAchievements.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: AppTheme.darkCard(radius: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 32,
                              color: AppTheme.secondary500,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Badge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProfileTab(AuthController authController) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final user = authController.currentUser.value;
              final initials = _initials(user?.firstName, user?.lastName);
              final String role = user?.role?.name ?? 'student';
              return Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary500.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary500.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: const TextStyle(
                        color: AppTheme.primary400,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // info rows
                  _infoRow(Icons.mail_outline, user?.email ?? '—'),
                  if (user?.phone != null && user!.phone!.isNotEmpty)
                    _infoRow(Icons.phone_outlined, user.phone!),
                  if (user?.state != null && user!.state!.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, user.state!),
                  if (user?.institution != null &&
                      user!.institution!.isNotEmpty)
                    _infoRow(Icons.school_outlined, user.institution!),
                ],
              );
            }),
          ),
          const Divider(color: AppTheme.dark400, height: 1),
          // Menu Items
          ...[
            (
              'View Full Profile',
              Icons.person_outline,
              () => Get.toNamed(AppRoutes.profile),
            ),
            (
              'Notifications',
              Icons.notifications_none,
              () => Get.toNamed(AppRoutes.notifications),
            ),
            (
              'Achievements',
              Icons.emoji_events_outlined,
              () => Get.toNamed(AppRoutes.achievements),
            ),
            (
              'Leaderboard',
              Icons.leaderboard,
              () => Get.toNamed(AppRoutes.leaderboard),
            ),
            (
              'Membership',
              Icons.card_membership,
              () => Get.toNamed(AppRoutes.membership),
            ),
            ('Logout', Icons.logout, () async => await authController.logout()),
          ].map(
            (item) => ListTile(
              leading: Icon(item.$2, color: AppTheme.textMuted),
              title: Text(
                item.$1,
                style: const TextStyle(color: AppTheme.textLight),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textMuted,
              ),
              onTap: item.$3,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  String _initials(String? first, String? last) {
    final f = (first?.isNotEmpty ?? false) ? first![0].toUpperCase() : '';
    final l = (last?.isNotEmpty ?? false) ? last![0].toUpperCase() : '';
    return f + l;
  }

  String _roleLabel(String role) {
    const labels = {
      'student': 'Student',
      'parent': 'Parent',
      'facilitator': 'Facilitator',
      'instructor': 'Instructor',
      'schoolAdmin': 'School Admin',
      'school_admin': 'School Admin',
      'uniMember': 'University Member',
      'uni_member': 'University Member',
      'circleMember': 'Circle Member',
      'circle_member': 'Circle Member',
      'mentor': 'Mentor',
      'admin': 'Admin',
    };
    return labels[role] ?? role;
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.dark700,
      selectedItemColor: AppTheme.primary500,
      unselectedItemColor: AppTheme.textMuted,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: 'Learn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events_outlined),
          activeIcon: Icon(Icons.emoji_events),
          label: 'Achievements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          activeIcon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}
