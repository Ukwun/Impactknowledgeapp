import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/classroom_controller.dart';

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

        if (classroomController.error.value.isNotEmpty &&
            classroomController.hierarchy.isEmpty) {
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
        final cmsFields = classroomController.contentObjectFields;
        final pathways = classroomController.subscriptionPathways;
        final blend = classroomController.recommendedDeliveryBlend;
        final rhythm = classroomController.weeklyClassroomRhythm;
        final curriculum = classroomController.fourLevelCurriculumFramework;
        final currentCurriculum =
            classroomController.currentCurriculumLevelProfile;
        final primaryBlueprint = classroomController.levelOnePrimaryBlueprint;
        final juniorBlueprint =
            classroomController.levelTwoJuniorSecondaryBlueprint;
        final seniorBlueprint =
            classroomController.levelThreeSeniorSecondaryBlueprint;

        return RefreshIndicator(
          color: AppTheme.primary500,
          onRefresh: classroomController.loadExperience,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildHero(sessions, tasks, badges),
              const SizedBox(height: 16),
              _buildFeedbackBanner(),
              if (classroomController.actionMessage.value.isNotEmpty ||
                  classroomController.error.value.isNotEmpty)
                const SizedBox(height: 16),
              _buildActionConsole(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Delivery Model Readiness',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Four-layer delivery is active for this classroom blueprint and can be scheduled directly from this screen.',
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
                    const SizedBox(height: 12),
                    if (blend.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BlendPill(
                            label: 'Self-paced',
                            value:
                                '${blend['selfPacedStructuredContent'] ?? 0}%',
                            color: AppTheme.info500,
                          ),
                          _BlendPill(
                            label: 'Live / Mentoring',
                            value:
                                '${blend['liveClassroomMentoringFacilitation'] ?? 0}%',
                            color: AppTheme.success500,
                          ),
                          _BlendPill(
                            label: 'Projects / Showcase',
                            value:
                                '${blend['projectsSimulationsShowcasesCommunity'] ?? 0}%',
                            color: AppTheme.secondary500,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Subscription Delivery Modes',
                child: pathways.isEmpty
                    ? const Text(
                        'Subscription delivery pathways will appear once the blueprint is available.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: pathways.map((pathway) {
                          final features = pathway['requiredFeatures'];
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
                                  pathway['mode']?.toString() ?? 'Mode',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pathway['primaryUser']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: features is List
                                      ? features
                                            .map(
                                              (feature) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.dark700,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  feature.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList()
                                      : [],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Four-Level Curriculum Framework',
                child: curriculum.isEmpty
                    ? const Text(
                        'Curriculum framework configuration is not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentCurriculum.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.success500.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.success500.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Current classroom pathway: ${currentCurriculum['level'] ?? classroomController.currentLevelName} (${currentCurriculum['ageGroup'] ?? ''}) - ${currentCurriculum['primaryOutcome'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ...curriculum.map((item) {
                            final isCurrent =
                                currentCurriculum['key']?.toString() ==
                                item['key']?.toString();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.dark600,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppTheme.success500.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppTheme.dark500,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item['level'] ?? 'Level'} (${item['ageGroup'] ?? ''})',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppTheme.success500,
                                          size: 17,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Primary outcome: ${item['primaryOutcome'] ?? ''}',
                                    style: const TextStyle(
                                      color: AppTheme.primary400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['signatureShift']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
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
                title: 'Level 1 - Primary Implementation Blueprint',
                child: primaryBlueprint.isEmpty
                    ? const Text(
                        'Primary level implementation details are not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlock(
                            'Purpose',
                            primaryBlueprint['purpose']?.toString() ??
                                'Build habits, values, awareness, and confidence.',
                          ),
                          _chipList(
                            title: 'Core Outcomes',
                            values: primaryBlueprint['coreOutcomes'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Curriculum Strands',
                            values: primaryBlueprint['curriculumStrands'],
                            color: AppTheme.secondary500,
                          ),
                          const SizedBox(height: 10),
                          _termStructurePanel(
                            primaryBlueprint['suggestedTermStructure'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Signature Experiences',
                            values: primaryBlueprint['signatureExperiences'],
                            color: AppTheme.success500,
                          ),
                          const SizedBox(height: 10),
                          _liveFormatPanel(
                            primaryBlueprint['liveClassroomFormat'],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Level 2 - Junior Secondary Implementation Blueprint',
                child: juniorBlueprint.isEmpty
                    ? const Text(
                        'Junior Secondary implementation details are not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlock(
                            'Purpose',
                            juniorBlueprint['purpose']?.toString() ??
                                'Build practical financial and enterprise habits.',
                          ),
                          _chipList(
                            title: 'Core Outcomes',
                            values: juniorBlueprint['coreOutcomes'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Curriculum Strands',
                            values: juniorBlueprint['curriculumStrands'],
                            color: AppTheme.secondary500,
                          ),
                          const SizedBox(height: 10),
                          _termStructurePanel(
                            juniorBlueprint['suggestedTermStructure'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Signature Experiences',
                            values: juniorBlueprint['signatureExperiences'],
                            color: AppTheme.success500,
                          ),
                          const SizedBox(height: 10),
                          _liveFormatPanel(
                            juniorBlueprint['liveClassroomFormat'],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Level 3 - Senior Secondary Implementation Blueprint',
                child: seniorBlueprint.isEmpty
                    ? const Text(
                        'Senior Secondary implementation details are not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlock(
                            'Purpose',
                            seniorBlueprint['purpose']?.toString() ??
                                'Build enterprise readiness, financial confidence, and presentation ability.',
                          ),
                          _chipList(
                            title: 'Core Outcomes',
                            values: seniorBlueprint['coreOutcomes'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Curriculum Strands',
                            values: seniorBlueprint['curriculumStrands'],
                            color: AppTheme.secondary500,
                          ),
                          const SizedBox(height: 10),
                          _termStructurePanel(
                            seniorBlueprint['suggestedTermStructure'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Signature Experiences',
                            values: seniorBlueprint['signatureExperiences'],
                            color: AppTheme.success500,
                          ),
                          const SizedBox(height: 10),
                          _liveFormatPanel(
                            seniorBlueprint['liveClassroomFormat'],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Weekly Classroom Rhythm',
                child: rhythm.isEmpty
                    ? const Text(
                        'Weekly rhythm data is not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: rhythm.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppTheme.primary400,
                              size: 18,
                            ),
                            title: Text(
                              item['dayStage']?.toString() ?? 'Stage',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${item['learnerExperience'] ?? ''}\n${item['systemFunction'] ?? ''}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            isThreeLine: true,
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'CMS Content Object Fields',
                child: cmsFields.isEmpty
                    ? const Text(
                        'CMS field guidance is not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: cmsFields.map((field) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.dark600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field['label']?.toString() ?? 'Field',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  field['description']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Live Session Operations',
                actionLabel: 'Open Events',
                onAction: () => Get.toNamed(AppRoutes.events),
                child: sessions.isEmpty
                    ? const Text(
                        'No sessions scheduled yet. Use Create Live Session to publish one immediately.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: sessions.take(8).map((s) {
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
                    ...tasks.take(8).map((task) {
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title']?.toString() ?? 'Task',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${task['moduleTitle'] ?? 'Module'} • ${task['lessonTitle'] ?? 'Lesson'}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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
                        'No badge triggers have been configured yet for this cycle. Use Create Badge Rule to attach one to an assessment or showcase.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: badges.take(8).map((badge) {
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

  Widget _buildHero(
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> tasks,
    List<Map<String, dynamic>> badges,
  ) {
    return Container(
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
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
    );
  }

  Widget _buildFeedbackBanner() {
    final success = classroomController.actionMessage.value;
    final error = classroomController.error.value;

    if (success.isEmpty && error.isEmpty) {
      return const SizedBox.shrink();
    }

    final isError = error.isNotEmpty;
    final text = isError ? error : success;
    final color = isError ? AppTheme.danger500 : AppTheme.success500;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () {
              classroomController.error.value = '';
              classroomController.clearActionMessage();
            },
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildActionConsole() {
    return _SectionCard(
      title: 'Facilitator Action Console',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Run the classroom directly from here: publish live sessions, attach CMS-rich activities, and define badge/certificate rules.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PrimaryActionButton(
                label: 'Create Live Session',
                icon: Icons.video_call_outlined,
                isBusy: classroomController.isSubmitting.value,
                onTap: _openCreateLiveSessionSheet,
              ),
              _PrimaryActionButton(
                label: 'Create Activity',
                icon: Icons.task_alt_outlined,
                isBusy: classroomController.isSubmitting.value,
                buttonKey: const Key('facilitator_create_activity_button'),
                onTap: _openCreateActivitySheet,
              ),
              _PrimaryActionButton(
                label: 'Create Badge Rule',
                icon: Icons.workspace_premium_outlined,
                isBusy: classroomController.isSubmitting.value,
                onTap: _openCreateBadgeSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.dark600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipList({
    required String title,
    required dynamic values,
    Color color = AppTheme.primary500,
  }) {
    final list = values is List ? values : const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    item.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _termStructurePanel(dynamic value) {
    final terms = value is List ? value : const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested Term Structure',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        ...terms.map((entry) {
          if (entry is! Map) {
            return const SizedBox.shrink();
          }
          final topics = entry['illustrativeTopics'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.dark600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['term'] ?? 'Term'} - ${entry['focus'] ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                if (topics is List)
                  ...topics.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '- ${topic.toString()}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _liveFormatPanel(dynamic value) {
    final data = value is Map ? Map<String, dynamic>.from(value) : {};
    final methods = data['methods'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.success500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.success500.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Classroom Format',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${data['frequency'] ?? 'One live class per week'} • ${data['durationMinutes'] ?? 45} minutes',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            data['format']?.toString() ?? 'Visual and highly interactive',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
          if (methods is List) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methods
                  .map(
                    (method) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.dark700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        method.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCreateLiveSessionSheet() async {
    final cycleOptions = classroomController.cycleOptions;
    if (cycleOptions.isEmpty) {
      Get.snackbar(
        'No Cycle Available',
        'Create or link a classroom cycle before scheduling live sessions.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final joinCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    String selectedCycleId = cycleOptions.first['id'].toString();
    String sessionType = 'facilitator_class';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.dark700,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Live Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dropdownField(
                        label: 'Cycle',
                        value: selectedCycleId,
                        items: cycleOptions,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedCycleId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Session Type',
                        value: sessionType,
                        items: const [
                          {
                            'id': 'facilitator_class',
                            'title': 'Facilitator Class',
                          },
                          {'id': 'workshop', 'title': 'Workshop'},
                          {'id': 'clinic', 'title': 'Clinic'},
                          {'id': 'simulation', 'title': 'Simulation'},
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => sessionType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: titleCtrl,
                        label: 'Session Title',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: startCtrl,
                        label: 'Start DateTime (ISO or YYYY-MM-DD HH:MM)',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _textField(controller: endCtrl, label: 'End DateTime'),
                      const SizedBox(height: 12),
                      _textField(controller: joinCtrl, label: 'Join URL'),
                      const SizedBox(height: 12),
                      _textField(
                        controller: capacityCtrl,
                        label: 'Capacity',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: notesCtrl,
                        label: 'Facilitator Notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _submitButton(
                        label: 'Publish Session',
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final success = await classroomController
                              .createLiveSession(
                                cycleId: selectedCycleId,
                                title: titleCtrl.text.trim(),
                                startsAt: _normalizeDateTimeInput(
                                  startCtrl.text,
                                ),
                                endsAt: endCtrl.text.trim().isEmpty
                                    ? null
                                    : _normalizeDateTimeInput(endCtrl.text),
                                joinUrl: joinCtrl.text.trim(),
                                notes: notesCtrl.text.trim(),
                                capacity: int.tryParse(
                                  capacityCtrl.text.trim(),
                                ),
                                sessionType: sessionType,
                              );

                          if (success) {
                            Get.back();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateActivitySheet() async {
    final lessonOptions = classroomController.lessonOptions;
    if (lessonOptions.isEmpty) {
      Get.snackbar(
        'No Lesson Available',
        'Create or link lessons before adding classroom activities.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    final resourceCtrl = TextEditingController();
    final shortDescCtrl = TextEditingController();
    final programmeCtrl = TextEditingController(
      text:
          '${classroomController.programmeName} / ${classroomController.currentLevelName}',
    );
    final ageBandCtrl = TextEditingController();
    final subjectStrandCtrl = TextEditingController();
    final termCycleCtrl = TextEditingController(
      text: classroomController.currentCycleName,
    );
    final lessonTypeCtrl = TextEditingController();
    final learningObjectivesCtrl = TextEditingController();
    final coreContentCtrl = TextEditingController();
    final facilitatorNotesCtrl = TextEditingController();
    final learnerInstructionsCtrl = TextEditingController();
    final downloadableCtrl = TextEditingController();
    final quizItemsCtrl = TextEditingController();
    final submissionTypeCtrl = TextEditingController();
    final liveSessionRefCtrl = TextEditingController();
    final assessmentWeightCtrl = TextEditingController();
    final badgeTriggerCtrl = TextEditingController();
    final prerequisiteCtrl = TextEditingController();
    final completionStatusCtrl = TextEditingController(text: 'draft');
    final primaryBlueprint = classroomController.levelOnePrimaryBlueprint;
    final juniorBlueprint =
        classroomController.levelTwoJuniorSecondaryBlueprint;
    final seniorBlueprint =
        classroomController.levelThreeSeniorSecondaryBlueprint;

    final templateBlueprints = <Map<String, dynamic>>[
      if (primaryBlueprint.isNotEmpty)
        {
          'id': 'primary',
          'title': 'Level 1 - Primary (7-11)',
          'blueprint': primaryBlueprint,
        },
      if (juniorBlueprint.isNotEmpty)
        {
          'id': 'junior_secondary',
          'title': 'Level 2 - Junior Secondary (12-14)',
          'blueprint': juniorBlueprint,
        },
      if (seniorBlueprint.isNotEmpty)
        {
          'id': 'senior_secondary',
          'title': 'Level 3 - Senior Secondary (15-18)',
          'blueprint': seniorBlueprint,
        },
    ];

    String selectedLessonId = lessonOptions.first['id'].toString();
    String selectedLayer = lessonOptions.first['layer']?.toString() ?? 'learn';
    String activityType = 'worksheet';
    bool isRequired = true;
    String selectedTemplateId = templateBlueprints.isNotEmpty
        ? templateBlueprints.first['id']?.toString() ?? 'primary'
        : 'primary';

    Map<String, dynamic> resolveSelectedBlueprint() {
      for (final item in templateBlueprints) {
        if (item['id']?.toString() == selectedTemplateId) {
          final blueprint = item['blueprint'];
          if (blueprint is Map<String, dynamic>) return blueprint;
          if (blueprint is Map) return Map<String, dynamic>.from(blueprint);
        }
      }
      return const {};
    }

    List<Map<String, dynamic>> resolveTermOptions() {
      final selectedBlueprint = resolveSelectedBlueprint();
      final terms = selectedBlueprint['suggestedTermStructure'];
      if (terms is! List) return const [];
      return terms
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    List<String> resolveStrands() {
      final selectedBlueprint = resolveSelectedBlueprint();
      final strands = selectedBlueprint['curriculumStrands'];
      if (strands is! List) return const [];
      return strands
          .map((item) => item.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList();
    }

    List<String> resolveOutcomes() {
      final selectedBlueprint = resolveSelectedBlueprint();
      final outcomes = selectedBlueprint['coreOutcomes'];
      if (outcomes is! List) return const [];
      return outcomes
          .map((item) => item.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList();
    }

    var termOptions = resolveTermOptions();
    var strandOptions = resolveStrands();
    String selectedTemplateTerm = termOptions.isNotEmpty
        ? (termOptions.first['focus']?.toString() ?? 'Term 1')
        : 'Term 1';
    String selectedTemplateStrand = strandOptions.isNotEmpty
        ? strandOptions.first
        : '';

    void applyTemplate({bool forceOverwrite = false}) {
      final selectedBlueprint = resolveSelectedBlueprint();
      final selectedTermTemplate = termOptions.firstWhere(
        (item) => (item['focus']?.toString() ?? '') == selectedTemplateTerm,
        orElse: () => termOptions.isNotEmpty ? termOptions.first : {},
      );
      final selectedTopics = selectedTermTemplate['illustrativeTopics'];
      final topicsText = selectedTopics is List
          ? selectedTopics.map((item) => item.toString()).join(', ')
          : '';
      final outcomeText = resolveOutcomes()
          .take(3)
          .map((item) => '- $item')
          .join('\n');
      final blueprintLevel =
          selectedBlueprint['level']?.toString() ?? 'Classroom';

      if (forceOverwrite || titleCtrl.text.trim().isEmpty) {
        titleCtrl.text = '$selectedTemplateStrand - $selectedTemplateTerm';
      }
      if (forceOverwrite || shortDescCtrl.text.trim().isEmpty) {
        shortDescCtrl.text =
            '$blueprintLevel classroom activity focused on $selectedTemplateStrand within $selectedTemplateTerm.';
      }
      if (forceOverwrite || ageBandCtrl.text.trim().isEmpty) {
        ageBandCtrl.text = selectedBlueprint['ageGroup']?.toString() ?? '';
      }
      if (forceOverwrite || subjectStrandCtrl.text.trim().isEmpty) {
        subjectStrandCtrl.text = selectedTemplateStrand;
      }
      if (forceOverwrite || termCycleCtrl.text.trim().isEmpty) {
        termCycleCtrl.text =
            '${classroomController.currentCycleName} • $selectedTemplateTerm';
      }
      if (forceOverwrite || lessonTypeCtrl.text.trim().isEmpty) {
        lessonTypeCtrl.text =
            '$blueprintLevel practical lesson with facilitator guidance';
      }
      if (forceOverwrite || learningObjectivesCtrl.text.trim().isEmpty) {
        learningObjectivesCtrl.text = outcomeText;
      }
      if (forceOverwrite || coreContentCtrl.text.trim().isEmpty) {
        coreContentCtrl.text =
            'Focus: $selectedTemplateTerm\nStrand: $selectedTemplateStrand\nTopics: $topicsText';
      }
      if (forceOverwrite || facilitatorNotesCtrl.text.trim().isEmpty) {
        final liveFormat = selectedBlueprint['liveClassroomFormat'];
        final methods = (liveFormat is Map && liveFormat['methods'] is List)
            ? (liveFormat['methods'] as List)
                  .map((item) => item.toString())
                  .join(', ')
            : 'guided interaction';
        facilitatorNotesCtrl.text =
            'Use $methods to reinforce practical application and ethical decision-making.';
      }
      if (forceOverwrite || learnerInstructionsCtrl.text.trim().isEmpty) {
        learnerInstructionsCtrl.text =
            'Complete the task, share one example from home/school, and reflect on one choice you will apply this week.';
      }
      if (forceOverwrite || quizItemsCtrl.text.trim().isEmpty) {
        quizItemsCtrl.text =
            '$selectedTemplateStrand quick checks with short scenario-based prompts.';
      }
      if (forceOverwrite || submissionTypeCtrl.text.trim().isEmpty) {
        submissionTypeCtrl.text = 'worksheet_or_reflection';
      }
      if (forceOverwrite || liveSessionRefCtrl.text.trim().isEmpty) {
        final liveFormat = selectedBlueprint['liveClassroomFormat'];
        final frequency = liveFormat is Map
            ? (liveFormat['frequency']?.toString() ?? 'One live class per week')
            : 'One live class per week';
        final duration = liveFormat is Map
            ? (liveFormat['durationMinutes']?.toString() ?? '45')
            : '45';
        liveSessionRefCtrl.text =
            '$frequency • $duration-minute session with interactive scenario support.';
      }
      if (forceOverwrite || assessmentWeightCtrl.text.trim().isEmpty) {
        assessmentWeightCtrl.text = '20';
      }
      if (forceOverwrite || badgeTriggerCtrl.text.trim().isEmpty) {
        badgeTriggerCtrl.text =
            'Recognition for consistent responsible choices, collaboration, and completion quality.';
      }
      if (forceOverwrite || prerequisiteCtrl.text.trim().isEmpty) {
        prerequisiteCtrl.text =
            'Previous lesson and baseline concept check for current strand.';
      }
    }

    if (templateBlueprints.isNotEmpty) {
      applyTemplate();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.dark700,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Activity with CMS Fields',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (templateBlueprints.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primary500.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Curriculum Blueprint Autofill',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _dropdownField(
                                label: 'Blueprint Track',
                                fieldKey: const Key(
                                  'create_activity_blueprint_track_dropdown',
                                ),
                                value: selectedTemplateId,
                                items: templateBlueprints
                                    .map(
                                      (item) => {
                                        'id': item['id']?.toString() ?? '',
                                        'title':
                                            item['title']?.toString() ?? '',
                                      },
                                    )
                                    .where(
                                      (item) => (item['id']?.toString() ?? '')
                                          .isNotEmpty,
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedTemplateId = value;
                                    termOptions = resolveTermOptions();
                                    strandOptions = resolveStrands();
                                    selectedTemplateTerm =
                                        termOptions.isNotEmpty
                                        ? (termOptions.first['focus']
                                                  ?.toString() ??
                                              'Term 1')
                                        : 'Term 1';
                                    selectedTemplateStrand =
                                        strandOptions.isNotEmpty
                                        ? strandOptions.first
                                        : '';
                                    applyTemplate(forceOverwrite: true);
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _dropdownField(
                                label: 'Term Focus',
                                fieldKey: const Key(
                                  'create_activity_term_focus_dropdown',
                                ),
                                value: selectedTemplateTerm,
                                items: termOptions
                                    .map(
                                      (item) => {
                                        'id': item['focus']?.toString() ?? '',
                                        'title':
                                            '${item['term'] ?? 'Term'} • ${item['focus'] ?? ''}',
                                      },
                                    )
                                    .where(
                                      (item) => (item['id']?.toString() ?? '')
                                          .isNotEmpty,
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedTemplateTerm = value;
                                    applyTemplate(forceOverwrite: true);
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              _dropdownField(
                                label: 'Strand',
                                fieldKey: const Key(
                                  'create_activity_strand_dropdown',
                                ),
                                value: selectedTemplateStrand,
                                items: strandOptions
                                    .map((item) => {'id': item, 'title': item})
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    selectedTemplateStrand = value;
                                    applyTemplate(forceOverwrite: true);
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setSheetState(() {
                                      applyTemplate(forceOverwrite: true);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.auto_fix_high,
                                    size: 16,
                                  ),
                                  label: const Text('Re-apply Template'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _dropdownField(
                        label: 'Lesson',
                        value: selectedLessonId,
                        items: lessonOptions,
                        onChanged: (value) {
                          if (value == null) return;
                          final selected = lessonOptions.firstWhere(
                            (item) => item['id'] == value,
                          );
                          setSheetState(() {
                            selectedLessonId = value;
                            selectedLayer =
                                selected['layer']?.toString() ?? 'learn';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Activity Type',
                        value: activityType,
                        items: const [
                          {'id': 'worksheet', 'title': 'Worksheet'},
                          {'id': 'reflection', 'title': 'Reflection'},
                          {'id': 'quiz', 'title': 'Quiz'},
                          {'id': 'assignment', 'title': 'Assignment'},
                          {'id': 'simulation', 'title': 'Simulation'},
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => activityType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Learning Layer',
                        value: selectedLayer,
                        items: const [
                          {'id': 'learn', 'title': 'Learn'},
                          {'id': 'apply', 'title': 'Apply'},
                          {'id': 'engage', 'title': 'Engage'},
                          {'id': 'show_progress', 'title': 'Show Progress'},
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedLayer = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isRequired,
                        onChanged: (value) {
                          setSheetState(() => isRequired = value);
                        },
                        title: const Text(
                          'Required for learner progression',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _textField(
                        controller: titleCtrl,
                        label: 'Title',
                        validator: _required,
                        fieldKey: const Key('create_activity_title_input'),
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: shortDescCtrl,
                        label: 'Short Description',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: programmeCtrl,
                        label: 'Programme and Level',
                      ),
                      const SizedBox(height: 12),
                      _textField(controller: ageBandCtrl, label: 'Age Band'),
                      const SizedBox(height: 12),
                      _textField(
                        controller: subjectStrandCtrl,
                        label: 'Subject Strand',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: termCycleCtrl,
                        label: 'Term / Cycle and Module Number',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: lessonTypeCtrl,
                        label: 'Lesson Type',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: learningObjectivesCtrl,
                        label: 'Learning Objectives',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: coreContentCtrl,
                        label: 'Core Content Body',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: facilitatorNotesCtrl,
                        label: 'Facilitator Notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: learnerInstructionsCtrl,
                        label: 'Learner Instructions',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: downloadableCtrl,
                        label: 'Downloadable Resources / Worksheets',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: quizItemsCtrl,
                        label: 'Quiz Items and Answer Rules',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: submissionTypeCtrl,
                        label: 'Assignment Submission Type',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: liveSessionRefCtrl,
                        label: 'Live Session Reference and Replay Link',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: assessmentWeightCtrl,
                        label: 'Assessment Weighting',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: badgeTriggerCtrl,
                        label: 'Badge Trigger and Certificate Rule',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: prerequisiteCtrl,
                        label: 'Prerequisite Content',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: completionStatusCtrl,
                        label: 'Completion Status',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: instructionsCtrl,
                        label: 'Activity Instructions',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: resourceCtrl,
                        label: 'Primary Resource URL',
                      ),
                      const SizedBox(height: 16),
                      _submitButton(
                        label: 'Publish Activity',
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final metadata = {
                            'shortDescription': shortDescCtrl.text.trim(),
                            'programme': programmeCtrl.text.trim(),
                            'ageBand': ageBandCtrl.text.trim(),
                            'subjectStrand': subjectStrandCtrl.text.trim(),
                            'termCycleModule': termCycleCtrl.text.trim(),
                            'lessonType': lessonTypeCtrl.text.trim(),
                            'learningObjectives': learningObjectivesCtrl.text
                                .trim(),
                            'coreContentBody': coreContentCtrl.text.trim(),
                            'facilitatorNotes': facilitatorNotesCtrl.text
                                .trim(),
                            'learnerInstructions': learnerInstructionsCtrl.text
                                .trim(),
                            'downloadableResources': downloadableCtrl.text
                                .trim(),
                            'quizItems': quizItemsCtrl.text.trim(),
                            'assignmentSubmissionType': submissionTypeCtrl.text
                                .trim(),
                            'liveSessionReference': liveSessionRefCtrl.text
                                .trim(),
                            'assessmentWeighting': assessmentWeightCtrl.text
                                .trim(),
                            'badgeTrigger': badgeTriggerCtrl.text.trim(),
                            'prerequisiteContent': prerequisiteCtrl.text.trim(),
                            'completionStatus': completionStatusCtrl.text
                                .trim(),
                            'status': 'pending',
                          };

                          final success = await classroomController
                              .createActivity(
                                lessonId: selectedLessonId,
                                title: titleCtrl.text.trim(),
                                activityType: activityType,
                                learningLayer: selectedLayer,
                                isRequired: isRequired,
                                instructions: instructionsCtrl.text.trim(),
                                resourceUrl: resourceCtrl.text.trim(),
                                metadata: metadata,
                              );

                          if (success) {
                            Get.back();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateBadgeSheet() async {
    final assessments = classroomController.assessmentOptions;
    final showcases = classroomController.showcaseOptions;

    if (assessments.isEmpty && showcases.isEmpty) {
      Get.snackbar(
        'No Badge Source Available',
        'Create an assessment or showcase first, then attach a badge or certificate rule.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final criteriaCtrl = TextEditingController();
    final certificateCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '0');
    String badgeType = 'completion_badge';
    String sourceType = assessments.isNotEmpty ? 'assessment' : 'showcase';
    String? selectedAssessmentId = assessments.isNotEmpty
        ? assessments.first['id']?.toString()
        : null;
    String? selectedShowcaseId = showcases.isNotEmpty
        ? showcases.first['id']?.toString()
        : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.dark700,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final options = sourceType == 'assessment'
                ? assessments
                : showcases;
            final selectedValue = sourceType == 'assessment'
                ? selectedAssessmentId
                : selectedShowcaseId;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Badge Rule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dropdownField(
                        label: 'Badge Type',
                        value: badgeType,
                        items: const [
                          {
                            'id': 'completion_badge',
                            'title': 'Completion Badge',
                          },
                          {
                            'id': 'attendance_badge',
                            'title': 'Attendance Badge',
                          },
                          {
                            'id': 'certificate_rule',
                            'title': 'Certificate Rule',
                          },
                          {
                            'id': 'project_showcase',
                            'title': 'Project Showcase Badge',
                          },
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => badgeType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Rule Source',
                        value: sourceType,
                        items: [
                          if (assessments.isNotEmpty)
                            const {'id': 'assessment', 'title': 'Assessment'},
                          if (showcases.isNotEmpty)
                            const {'id': 'showcase', 'title': 'Showcase'},
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => sourceType = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      if (options.isNotEmpty)
                        _dropdownField(
                          label: sourceType == 'assessment'
                              ? 'Assessment'
                              : 'Showcase',
                          value: selectedValue,
                          items: options,
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              if (sourceType == 'assessment') {
                                selectedAssessmentId = value;
                              } else {
                                selectedShowcaseId = value;
                              }
                            });
                          },
                        ),
                      if (options.isEmpty)
                        const Text(
                          'No valid source available for this rule type.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: titleCtrl,
                        label: 'Badge / Certificate Title',
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: criteriaCtrl,
                        label: 'Trigger Criteria',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: certificateCtrl,
                        label: 'Certificate Template URL',
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: pointsCtrl,
                        label: 'Points Reward',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _submitButton(
                        label: 'Save Badge Rule',
                        onPressed: options.isEmpty
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }

                                final success = await classroomController
                                    .createBadgeRule(
                                      title: titleCtrl.text.trim(),
                                      badgeType: badgeType,
                                      criteria: criteriaCtrl.text.trim(),
                                      certificateTemplateUrl: certificateCtrl
                                          .text
                                          .trim(),
                                      pointsReward:
                                          int.tryParse(
                                            pointsCtrl.text.trim(),
                                          ) ??
                                          0,
                                      assessmentId: sourceType == 'assessment'
                                          ? selectedAssessmentId
                                          : null,
                                      showcaseId: sourceType == 'showcase'
                                          ? selectedShowcaseId
                                          : null,
                                    );

                                if (success) {
                                  Get.back();
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Key? fieldKey,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.darkInput(hint: label),
    );
  }

  Widget _dropdownField({
    Key? fieldKey,
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.any((item) => item['id']?.toString() == value)
        ? value
        : (items.isNotEmpty ? items.first['id']?.toString() : null);

    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: safeValue,
      dropdownColor: AppTheme.dark700,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.darkInput(hint: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['id']?.toString(),
              child: Text(
                item['title']?.toString() ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _submitButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: classroomController.isSubmitting.value ? null : onPressed,
        icon: classroomController.isSubmitting.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(label),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String _normalizeDateTimeInput(String value) {
    final trimmed = value.trim();
    final parsed = DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    return parsed?.toIso8601String() ?? trimmed;
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

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isBusy;
  final Key? buttonKey;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isBusy,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: buttonKey,
      onPressed: isBusy ? null : onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _BlendPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BlendPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
