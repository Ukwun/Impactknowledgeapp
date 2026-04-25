import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/classroom_controller.dart';
import '../../config/routes.dart';

class FacilitatorClassroomScreen extends StatefulWidget {
  const FacilitatorClassroomScreen({super.key});

  @override
  State<FacilitatorClassroomScreen> createState() =>
      _FacilitatorClassroomScreenState();
}

class _FacilitatorClassroomScreenState
    extends State<FacilitatorClassroomScreen> {
  late ClassroomController classroomController;

  @override
  void initState() {
    super.initState();
    classroomController = Get.isRegistered<ClassroomController>()
        ? Get.find<ClassroomController>()
        : Get.put(ClassroomController(), permanent: false);
    classroomController.loadExperience();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(title: const Text('Facilitator Classroom')),
      body: Obx(() {
        if (classroomController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (classroomController.error.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                classroomController.error.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textLight),
              ),
            ),
          );
        }

        final sessions = classroomController.upcomingLiveSessions;
        final tasks = classroomController.learnerTasks;
        final badges = classroomController.badgesAndCertificates;
        final layers = classroomController.learningLayers;

        return RefreshIndicator(
          color: AppTheme.primary500,
          onRefresh: classroomController.loadExperience,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.dark600, AppTheme.primary700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Facilitator Framework',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${classroomController.programmeName} • ${classroomController.currentLevelName} • ${classroomController.currentCycleName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricChip(
                            title: 'Live Sessions',
                            value: sessions.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricChip(
                            title: 'Learning Tasks',
                            value: tasks.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricChip(
                            title: 'Badges/Certs',
                            value: badges.length.toString(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Delivery Model Readiness',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Four-layer delivery is active for this classroom blueprint.',
                      style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: layers.map((layer) {
                        final name = (layer['key']?.toString() ?? 'layer')
                            .replaceAll('_', ' ');
                        return Chip(
                          label: Text(name.toUpperCase()),
                          backgroundColor: AppTheme.dark600,
                          side: BorderSide(
                            color: AppTheme.primary400.withValues(alpha: 0.5),
                          ),
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Live Session Operations',
                actionLabel: 'Open Events',
                onAction: () => Get.toNamed(AppRoutes.events),
                child: sessions.isEmpty
                    ? const Text(
                        'No sessions scheduled yet. Use your planning flow to create session slots.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: sessions.take(6).map((s) {
                          final startsAt = s['starts_at']?.toString() ?? '';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.videocam_outlined,
                              color: AppTheme.primary400,
                            ),
                            title: Text(
                              s['title']?.toString() ?? 'Live session',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${s['cycleName'] ?? 'Cycle'} • ${_formatDate(startsAt)}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () {
                                final joinUrl = s['join_url']?.toString() ?? '';
                                final msg = joinUrl.isEmpty
                                    ? 'Join link not configured yet for this session.'
                                    : 'Join URL: $joinUrl';
                                Get.snackbar(
                                  'Session Details',
                                  msg,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: const Text('Access'),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Task & Assessment Pipeline',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${classroomController.completedTaskCount} completed of ${classroomController.totalTaskCount} mapped tasks',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: classroomController.taskProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.dark400.withValues(
                          alpha: 0.3,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.success500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...tasks.take(6).map((task) {
                      final pending = task['status']?.toString() != 'completed';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.dark600,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: pending
                                ? AppTheme.warning500.withValues(alpha: 0.35)
                                : AppTheme.success500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pending
                                  ? Icons.pending_actions
                                  : Icons.check_circle,
                              color: pending
                                  ? AppTheme.warning500
                                  : AppTheme.success500,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task['title']?.toString() ?? 'Task',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              (task['layer']?.toString() ?? 'learn')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Badge & Certificate Visibility',
                child: badges.isEmpty
                    ? const Text(
                        'No badge triggers have been configured yet for this cycle.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: badges.take(6).map((badge) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.workspace_premium,
                              color: AppTheme.secondary500,
                            ),
                            title: Text(
                              badge['title']?.toString() ?? 'Badge',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${badge['sourceType'] ?? 'rule'} • ${badge['sourceTitle'] ?? ''}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Time not set';
    final d = date.toLocal();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} $hh:$mm';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;

  const _MetricChip({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
