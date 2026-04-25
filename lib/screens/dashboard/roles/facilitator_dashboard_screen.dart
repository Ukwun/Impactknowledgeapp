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
              title: 'Create Course',
              subtitle: 'Launch authoring workflow for a new course.',
              icon: Icons.add_circle_outline,
              onTap: () => Get.toNamed(
                AppRoutes.courseManagement,
                arguments: {'action': 'create'},
              ),
            ),
            RoleActionTile(
              title: 'Edit Course',
              subtitle: 'Update curriculum, publish status, and metadata.',
              icon: Icons.edit_outlined,
              onTap: () => Get.toNamed(AppRoutes.courseManagement),
            ),
            RoleActionTile(
              title: 'View Analytics',
              subtitle:
                  'Inspect completion, enrollment, and engagement metrics.',
              icon: Icons.analytics,
              onTap: () => Get.toNamed(AppRoutes.courseManagement),
            ),
            RoleActionTile(
              title: 'Message Students',
              subtitle: 'Send announcements to enrolled learners.',
              icon: Icons.message_outlined,
              onTap: () => Get.toNamed(AppRoutes.courseManagement),
            ),
            RoleActionTile(
              title: 'View Reports',
              subtitle: 'Open progress and outcomes reports per course.',
              icon: Icons.assessment_outlined,
              onTap: () => Get.toNamed(AppRoutes.courseManagement),
            ),
          ],
        );
      },
    );
  }
}
