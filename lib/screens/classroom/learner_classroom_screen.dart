import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/classroom_controller.dart';

class LearnerClassroomScreen extends StatefulWidget {
  const LearnerClassroomScreen({super.key});

  @override
  State<LearnerClassroomScreen> createState() => _LearnerClassroomScreenState();
}

class _LearnerClassroomScreenState extends State<LearnerClassroomScreen> {
  late ClassroomController classroomController;

  @override
  void initState() {
    super.initState();
    classroomController = Get.put(ClassroomController(), permanent: false);
    classroomController.loadExperience();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(title: const Text('Learner Classroom')),
      body: Obx(() {
        if (classroomController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (classroomController.error.value.isNotEmpty) {
          return _ErrorView(
            message: classroomController.error.value,
            onRetry: classroomController.loadExperience,
          );
        }

        return RefreshIndicator(
          color: AppTheme.primary500,
          onRefresh: classroomController.loadExperience,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroPanel(controller: classroomController),
              const SizedBox(height: 16),
              _LayerPanel(controller: classroomController),
              const SizedBox(height: 16),
              _TaskProgressPanel(controller: classroomController),
              const SizedBox(height: 16),
              _LiveSessionsPanel(controller: classroomController),
              const SizedBox(height: 16),
              _BadgePanel(controller: classroomController),
            ],
          ),
        );
      }),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final ClassroomController controller;

  const _HeroPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary700, AppTheme.primary500],
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
            'Guided Learning Journey',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${controller.programmeName} • ${controller.currentLevelName} • ${controller.currentCycleName}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Stay on track with live facilitation, practical tasks, and visible progress milestones.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerPanel extends StatelessWidget {
  final ClassroomController controller;

  const _LayerPanel({required this.controller});

  Color _layerColor(String key) {
    switch (key) {
      case 'learn':
        return AppTheme.info500;
      case 'apply':
        return AppTheme.secondary500;
      case 'engage':
        return AppTheme.success500;
      case 'show_progress':
        return AppTheme.primary500;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layers = controller.learningLayers;

    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Architecture',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (layers.isEmpty)
            const Text(
              'No learning layers available yet.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ...layers.map((layer) {
            final key = layer['key']?.toString() ?? 'layer';
            final purpose = layer['purpose']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dark600,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _layerColor(key).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: _layerColor(key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          purpose,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TaskProgressPanel extends StatelessWidget {
  final ClassroomController controller;

  const _TaskProgressPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tasks = controller.learnerTasks;
    final progress = controller.taskProgress;

    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Progression',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.completedTaskCount}/${controller.totalTaskCount} tasks completed',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.dark400.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primary500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Text(
              'No tasks mapped for this cycle yet.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ...tasks.take(6).map((task) {
            final status = task['status']?.toString() ?? 'pending';
            final completed = status == 'completed' || status == 'done';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed ? AppTheme.success500 : AppTheme.textMuted,
              ),
              title: Text(
                task['title']?.toString() ?? 'Task',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                '${task['layer'] ?? 'learn'} • ${task['moduleTitle'] ?? 'Module'}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed
                      ? AppTheme.success500.withValues(alpha: 0.2)
                      : AppTheme.warning500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  completed ? 'Done' : 'Pending',
                  style: TextStyle(
                    color: completed
                        ? AppTheme.success500
                        : AppTheme.warning500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LiveSessionsPanel extends StatelessWidget {
  final ClassroomController controller;

  const _LiveSessionsPanel({required this.controller});

  String _formatSessionTime(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return 'Time not set';
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final sessions = controller.upcomingLiveSessions;

    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Facilitator Sessions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const Text(
              'No live sessions scheduled yet. Check back after facilitator scheduling.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ...sessions.take(4).map((session) {
            final joinUrl = session['join_url']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dark600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['title']?.toString() ?? 'Live Session',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session['cycleName'] ?? 'Cycle'} • ${_formatSessionTime(session['starts_at']?.toString() ?? '')}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final text = joinUrl.isEmpty
                            ? 'Join link will be shared by your facilitator shortly.'
                            : 'Join from this link: $joinUrl';
                        Get.snackbar(
                          'Session Access',
                          text,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.video_call_outlined, size: 18),
                      label: const Text('Join Session'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BadgePanel extends StatelessWidget {
  final ClassroomController controller;

  const _BadgePanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final badges = controller.badgesAndCertificates;

    return Container(
      decoration: AppTheme.darkCard(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Badges & Certificates',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${badges.length} available',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (badges.isEmpty)
            const Text(
              'No badge rules published for this cycle yet.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ...badges.take(6).map((badge) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.secondary500.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppTheme.secondary500,
                  size: 18,
                ),
              ),
              title: Text(
                badge['title']?.toString() ?? 'Badge',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${badge['badge_type'] ?? 'recognition'} • ${badge['sourceTitle'] ?? ''}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.danger500,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
