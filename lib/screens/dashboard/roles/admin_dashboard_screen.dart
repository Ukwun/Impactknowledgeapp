import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String firstName;

  const AdminDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.admin)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchAdminDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = AdminDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'Admin Dashboard',
          subtitle:
              'Govern platform analytics, users, and operational controls.',
          roleLabel: 'Platform Admin',
          firstName: firstName,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRefreshing
                        ? 'Refreshing live data...'
                        : 'Live backend data${lastUpdated != null ? ' updated' : ''}',
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
                ('Total Users', d.totalUsers.toString(), Icons.people_alt),
                (
                  'Active Courses',
                  d.activeCourses.toString(),
                  Icons.library_books,
                ),
                ('Completion', '${d.completionRate}%', Icons.done_all),
                (
                  'Critical Alerts',
                  d.openAlerts.toString(),
                  Icons.crisis_alert,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Platform Analytics',
              subtitle: 'Audit courses and system-wide performance.',
              icon: Icons.query_stats,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Global Achievements',
              subtitle:
                  'Inspect badges, leaderboards, and certification health.',
              icon: Icons.emoji_events,
              onTap: () => Get.toNamed(AppRoutes.achievements),
            ),
            RoleActionTile(
              title: 'Admin Profile',
              subtitle: 'Manage account and platform governance settings.',
              icon: Icons.admin_panel_settings,
              onTap: () => Get.toNamed(AppRoutes.profile),
            ),
          ],
        );
      },
    );
  }
}
