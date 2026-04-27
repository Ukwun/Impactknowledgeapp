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
        final recommendations = (data['recommendations'] is List)
            ? (data['recommendations'] as List)
                  .map((item) => item.toString())
                  .toList()
            : const <String>[];
        final interventions = (data['interventions'] is List)
            ? (data['interventions'] as List)
                  .map((item) => item.toString())
                  .toList()
            : const <String>[];
        final attendanceRate = _pickInt(data, [
          'summary.cohortAttendanceRate',
          'institutionStats.attendanceRate',
        ], fallback: d.completionRate);
        final assignmentCompletion = _pickInt(data, [
          'summary.assignmentCompletionRate',
          'platformStats.assignmentCompletionRate',
        ], fallback: d.completionRate);
        final valuesRecognition = _pickInt(data, [
          'summary.valuesRecognitionCount',
          'platformStats.valuesRecognitionCount',
        ]);
        final monthlyProgress = _pickInt(data, [
          'summary.monthlyProgressSummary',
          'platformStats.monthlyProgressPercent',
        ], fallback: d.completionRate);

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
            const SizedBox(height: 12),
            RoleDashboardStats(
              stats: [
                (
                  'Cohort Attendance',
                  '$attendanceRate%',
                  Icons.groups_2_outlined,
                ),
                (
                  'Assignment Completion',
                  '$assignmentCompletion%',
                  Icons.assignment_turned_in_outlined,
                ),
                (
                  'Values Recognition',
                  '$valuesRecognition',
                  Icons.stars_outlined,
                ),
                (
                  'Monthly Progress',
                  '$monthlyProgress%',
                  Icons.query_stats_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            RoleDashboardInsightPanel(
              title: 'Recommended Actions',
              icon: Icons.lightbulb_outline,
              items: recommendations,
            ),
            RoleDashboardInsightPanel(
              title: 'Intervention Queue',
              icon: Icons.notifications_active_outlined,
              items: interventions,
            ),
            RoleActionTile(
              title: 'Platform Analytics',
              subtitle: 'Audit courses and system-wide performance.',
              icon: Icons.query_stats,
              onTap: () => Get.toNamed(AppRoutes.adminManagement),
            ),
            RoleActionTile(
              title: 'User Management',
              subtitle: 'Change roles, deactivate/reactivate accounts.',
              icon: Icons.manage_accounts,
              onTap: () => Get.toNamed(AppRoutes.adminManagement),
            ),
            RoleActionTile(
              title: 'Membership Tiers',
              subtitle: 'Create and delete membership tiers.',
              icon: Icons.workspace_premium,
              onTap: () => Get.toNamed(AppRoutes.adminManagement),
            ),
            RoleActionTile(
              title: 'Event Management',
              subtitle: 'Create, edit, and remove platform events.',
              icon: Icons.event_note,
              onTap: () => Get.toNamed(AppRoutes.events),
            ),
          ],
        );
      },
    );
  }
}

int _pickInt(
  Map<String, dynamic> data,
  List<String> paths, {
  int fallback = 0,
}) {
  for (final path in paths) {
    dynamic current = data;
    for (final key in path.split('.')) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        current = null;
        break;
      }
    }
    final value = _asInt(current);
    if (value != null) return value;
  }
  return fallback;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
