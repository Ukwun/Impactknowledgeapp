import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class MentorDashboardScreen extends StatelessWidget {
  final String firstName;

  const MentorDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.mentor)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchMentorDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = MentorDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'Mentor Dashboard',
          subtitle: 'Support mentees through sessions, goals, and milestones.',
          roleLabel: 'Mentor',
          firstName: firstName,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRefreshing
                        ? 'Refreshing live data...'
                        : 'Live backend data',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                IconButton(
                  onPressed: reload,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            RoleDashboardStats(
              stats: [
                ('Mentees', d.totalMentees.toString(), Icons.people),
                (
                  'Upcoming Sessions',
                  d.upcomingSessions.toString(),
                  Icons.calendar_today,
                ),
                (
                  'Completed Sessions',
                  d.completedSessions.toString(),
                  Icons.check_circle_outline,
                ),
                (
                  'Avg Mentee Growth',
                  '${d.avgMenteeGrowth}%',
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Learning Resources',
              subtitle: 'Open course catalog for mentoring references.',
              icon: Icons.library_books,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Mentee Achievements',
              subtitle: 'Review recognition and leaderboard trends.',
              icon: Icons.workspace_premium,
              onTap: () => Get.toNamed(AppRoutes.leaderboard),
            ),
            RoleActionTile(
              title: 'Mentor Profile',
              subtitle: 'Update your profile and mentorship details.',
              icon: Icons.person_outline,
              onTap: () => Get.toNamed(AppRoutes.profile),
            ),
            if (lastUpdated != null)
              Text(
                'Last update: ${lastUpdated.toLocal()}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        );
      },
    );
  }
}
