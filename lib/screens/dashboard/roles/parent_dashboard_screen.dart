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
        final assignmentCompletion = _pickInt(data, [
          'summary.assignmentCompletionRate',
          'oversight.assignmentCompletionRate',
        ], fallback: d.avgProgress);
        final valuesRecognition = _pickInt(data, [
          'summary.valuesRecognitionCount',
          'oversight.valuesRecognitionCount',
        ]);
        final monthlyProgress = _pickInt(data, [
          'summary.monthlyProgressSummary',
          'summary.monthlyProgressPercent',
        ], fallback: d.avgProgress);

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
            const SizedBox(height: 12),
            RoleDashboardStats(
              stats: [
                (
                  'Cohort Attendance',
                  '${d.attendanceRate}%',
                  Icons.fact_check_outlined,
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
