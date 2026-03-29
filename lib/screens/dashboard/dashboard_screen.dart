import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/role_dashboard_resolver.dart';
import '../../providers/auth_controller.dart';
import '../../providers/course_controller.dart';
import '../../providers/achievement_controller.dart';
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  Obx(() {
                    final user = authController.currentUser.value;
                    final initials = _initials(user?.firstName, user?.lastName);
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
            ),
          ),

          // Continue Learning
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
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: courseController.enrolledCourses.length,
                      itemBuilder: (context, index) {
                        final enrollment =
                            courseController.enrolledCourses[index];
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
                                    height: 80,
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
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'In Progress',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Expanded(
                                    child: Text(
                                      'Course',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary400,
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

          // Browse Courses
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
        ],
      ),
    );
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
