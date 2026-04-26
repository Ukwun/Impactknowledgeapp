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
        final attendanceRate = _pickInt(data, [
          'summary.cohortAttendanceRate',
          'summary.attendanceRate',
        ], fallback: d.completionRate);
        final assignmentCompletion = _pickInt(data, [
          'summary.assignmentCompletionRate',
        ], fallback: d.completionRate);
        final valuesRecognition = _pickInt(data, [
          'summary.valuesRecognitionCount',
          'summary.behaviourRecognitionCount',
        ]);
        final monthlyProgress = _pickInt(data, [
          'summary.monthlyProgressSummary',
          'summary.monthlyProgressPercent',
        ], fallback: d.completionRate);

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
            const SizedBox(height: 12),
            RoleDashboardStats(
              stats: [
                (
                  'Cohort Attendance',
                  '$attendanceRate%',
                  Icons.how_to_reg_outlined,
                ),
                (
                  'Assignment Completion',
                  '$assignmentCompletion%',
                  Icons.assignment_turned_in_outlined,
                ),
                (
                  'Values Recognition',
                  '$valuesRecognition',
                  Icons.volunteer_activism_outlined,
                ),
                (
                  'Monthly Progress',
                  '$monthlyProgress%',
                  Icons.calendar_month_outlined,
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
