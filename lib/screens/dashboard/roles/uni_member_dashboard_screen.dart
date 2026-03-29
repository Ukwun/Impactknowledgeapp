import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class UniMemberDashboardScreen extends StatelessWidget {
  final String firstName;

  const UniMemberDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.uniMember)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchUniMemberDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = UniMemberDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'University Member Dashboard',
          subtitle: 'Track venture growth, mentoring, and opportunity access.',
          roleLabel: 'University Member',
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
                ('Venture Stage', d.ventureStage, Icons.rocket_launch),
                ('Team Members', d.teamMembers.toString(), Icons.groups),
                (
                  'Mentor Sessions',
                  d.mentorSessions.toString(),
                  Icons.handshake,
                ),
                (
                  'Open Opportunities',
                  d.openOpportunities.toString(),
                  Icons.lightbulb,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Learning And Labs',
              subtitle: 'Open learning modules and practical labs.',
              icon: Icons.menu_book,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Venture Progress',
              subtitle: 'Track achievements and strategic milestones.',
              icon: Icons.insights,
              onTap: () => Get.toNamed(AppRoutes.achievements),
            ),
            RoleActionTile(
              title: 'University Profile',
              subtitle: 'Update your profile, goals, and collaboration links.',
              icon: Icons.person,
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
