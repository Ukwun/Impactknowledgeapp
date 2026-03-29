import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class CircleMemberDashboardScreen extends StatelessWidget {
  final String firstName;

  const CircleMemberDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.circleMember)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchCircleMemberDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = CircleMemberDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'Circle Member Dashboard',
          subtitle: 'Grow your network and engage with circle opportunities.',
          roleLabel: 'Circle Member',
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
                ('Connections', d.connections.toString(), Icons.hub),
                (
                  'Posts This Month',
                  d.postsThisMonth.toString(),
                  Icons.post_add,
                ),
                ('Roundtables', d.roundtables.toString(), Icons.groups_2),
                ('Profile Reach', d.profileReach.toString(), Icons.visibility),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Professional Learning',
              subtitle: 'Browse courses and advanced learning resources.',
              icon: Icons.school,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Community Recognition',
              subtitle: 'Track leaderboard position and milestones.',
              icon: Icons.leaderboard,
              onTap: () => Get.toNamed(AppRoutes.leaderboard),
            ),
            RoleActionTile(
              title: 'Circle Profile',
              subtitle: 'Maintain professional identity and activity settings.',
              icon: Icons.badge,
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
