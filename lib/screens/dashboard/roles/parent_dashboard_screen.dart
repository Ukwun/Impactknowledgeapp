import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class ParentDashboardScreen extends StatelessWidget {
  final String firstName;

  const ParentDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.parent)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchParentDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = ParentDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'Parent Dashboard',
          subtitle: 'Monitor child progress, activities, and communication.',
          roleLabel: 'Parent',
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
                (
                  'Children Linked',
                  d.childrenLinked.toString(),
                  Icons.family_restroom,
                ),
                ('Avg Progress', '${d.avgProgress}%', Icons.trending_up),
                ('Attendance', '${d.attendanceRate}%', Icons.how_to_reg),
                (
                  'Unread Messages',
                  d.unreadMessages.toString(),
                  Icons.mail_outline,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Child Learning Progress',
              subtitle: 'Review course progress and recent performance.',
              icon: Icons.insights,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Messages With Facilitators',
              subtitle: 'Open communication and check notifications.',
              icon: Icons.message,
              onTap: () => Get.toNamed(AppRoutes.profile),
            ),
            RoleActionTile(
              title: 'Leaderboard & Achievements',
              subtitle: 'Track recognitions and class standings.',
              icon: Icons.emoji_events,
              onTap: () => Get.toNamed(AppRoutes.leaderboard),
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
