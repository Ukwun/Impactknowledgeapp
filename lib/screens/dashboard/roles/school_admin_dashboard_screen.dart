import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class SchoolAdminDashboardScreen extends StatelessWidget {
  final String firstName;

  const SchoolAdminDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.schoolAdmin)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchSchoolAdminDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = SchoolAdminDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'School Admin Dashboard',
          subtitle: 'Oversee performance, operations, and facilitator quality.',
          roleLabel: 'School Admin',
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
                ('Students', d.totalStudents.toString(), Icons.groups),
                ('Facilitators', d.totalFacilitators.toString(), Icons.school),
                ('Completion Rate', '${d.completionRate}%', Icons.task_alt),
                (
                  'Open Alerts',
                  d.openAlerts.toString(),
                  Icons.notification_important,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'School Performance',
              subtitle: 'Review courses and academic indicators.',
              icon: Icons.bar_chart,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Institution Achievements',
              subtitle: 'Audit outcomes and recognitions.',
              icon: Icons.emoji_events,
              onTap: () => Get.toNamed(AppRoutes.achievements),
            ),
            RoleActionTile(
              title: 'Administration Profile',
              subtitle: 'Manage admin profile and account settings.',
              icon: Icons.admin_panel_settings,
              onTap: () => Get.toNamed(AppRoutes.profile),
            ),
          ],
        );
      },
    );
  }
}
