import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/service_locator.dart';
import '../../../config/routes.dart';
import '../../../models/auth/user_model.dart';
import '../../../models/dashboard/role_dashboard_contracts.dart';
import '../../../services/dashboard/dashboard_service.dart';
import '../../../services/dashboard/dashboard_sse_service.dart';
import 'role_dashboard_widgets.dart';

class FacilitatorDashboardScreen extends StatelessWidget {
  final String firstName;

  const FacilitatorDashboardScreen({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final dashboardService = getIt<DashboardService>();
    final sseStream = getIt.isRegistered<DashboardSseService>()
        ? getIt<DashboardSseService>().streamFor(UserRole.facilitator)
        : null;

    return LiveRoleDashboardData(
      loader: dashboardService.fetchFacilitatorDashboard,
      deltaStream: sseStream,
      refreshInterval: sseStream != null
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30),
      builder: (context, data, isRefreshing, lastUpdated, reload) {
        final d = FacilitatorDashboardData.fromJson(data);

        return RoleDashboardScaffold(
          title: 'Facilitator Dashboard',
          subtitle: 'Manage classes, assignments, and learner engagement.',
          roleLabel: 'Facilitator',
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
                ('Active Classes', d.activeClasses.toString(), Icons.class_),
                (
                  'Pending Reviews',
                  d.pendingReviews.toString(),
                  Icons.assignment_turned_in,
                ),
                (
                  'At-Risk Learners',
                  d.atRiskLearners.toString(),
                  Icons.warning_amber,
                ),
                (
                  'Messages',
                  d.unreadMessages.toString(),
                  Icons.mark_email_unread,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleActionTile(
              title: 'Class Management',
              subtitle: 'Open course list and manage curriculum delivery.',
              icon: Icons.menu_book,
              onTap: () => Get.toNamed(AppRoutes.courses),
            ),
            RoleActionTile(
              title: 'Review Learner Progress',
              subtitle: 'Check achievements and leaderboard movement.',
              icon: Icons.analytics,
              onTap: () => Get.toNamed(AppRoutes.achievements),
            ),
            RoleActionTile(
              title: 'Profile & Communication',
              subtitle: 'Manage profile and communication settings.',
              icon: Icons.person,
              onTap: () => Get.toNamed(AppRoutes.profile),
            ),
          ],
        );
      },
    );
  }
}
