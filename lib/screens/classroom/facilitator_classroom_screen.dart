import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../config/service_locator.dart';
import '../../providers/classroom_controller.dart';
import '../../services/api/api_service.dart';

class FacilitatorClassroomScreen extends StatefulWidget {
  const FacilitatorClassroomScreen({super.key});

  @override
  State<FacilitatorClassroomScreen> createState() =>
      _FacilitatorClassroomScreenState();
}

class _FacilitatorClassroomScreenState
    extends State<FacilitatorClassroomScreen> {
  late ClassroomController classroomController;
  final ApiService _apiService = getIt<ApiService>();
  final TextEditingController _incidentNoteCtrl = TextEditingController();
  final Set<String> _activeToolIds = <String>{};
  int _activeSessionStep = 9;
  int _engagementScore = 72;
  bool _sessionInProgress = false;
  bool _attendanceConfirmed = false;
  bool _lowBandwidthMode = true;
  bool _parentAccessEnabled = true;
  bool _moderationControlsEnabled = true;
  String _replayStatus = 'Pending';

  @override
  void dispose() {
    _incidentNoteCtrl.dispose();
    super.dispose();
  }

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
        final uniBlueprint = classroomController.levelFourImpactUniBlueprint;
        final liveRoles = classroomController.liveFacilitatorRoles;
        final sessionSequence = classroomController.liveSessionSequence;
        final toolRequirements =
            classroomController.facilitatorToolRequirements;
        final assessmentSignals = classroomController.assessmentSignals;
        final progressionRules = classroomController.progressionRules;
        final recognitionSystem = classroomController.recognitionSystem;
        final essentialRequirements =
            classroomController.essentialProductRequirements;
        final nextDevelopmentDocs =
            classroomController.recommendedNextDevelopmentDocuments;

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
              // ─── LIVE FACILITATOR FRAMEWORK ───────────────────────────
              _SectionCard(
                title: 'Live Facilitation Roles',
                child: liveRoles.isEmpty
                    ? const Text(
                        'Facilitator role definitions will appear once the blueprint is loaded.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: liveRoles.map((role) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.dark600,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.dark500),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary500.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: AppTheme.primary400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role['role']?.toString() ?? 'Role',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        role['responsibility']?.toString() ??
                                            '',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                title: 'Live Session Conductor',
                child: sessionSequence.isEmpty
                    ? const Text(
                        'Session sequence will appear once the blueprint is loaded.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : _liveSessionConductor(
                        sessionSequence: sessionSequence,
                        activeSessions: sessions,
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Facilitator Tool Panel',
                child: toolRequirements.isEmpty
                    ? const Text(
                        'Tool requirements will appear once the blueprint is loaded.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : _facilitatorToolPanel(tools: toolRequirements),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Assessment, Progression, and Recognition',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (assessmentSignals.isNotEmpty)
                      _chipList(
                        title: 'Assessment Signals',
                        values: assessmentSignals,
                        color: AppTheme.info500,
                      ),
                    if (progressionRules.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primary500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rule-based Progression Engine',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              progressionRules['ruleStatement']?.toString() ??
                                  'Learners progress when completion, assessment, project, and participation thresholds are met.',
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _BlendPill(
                                  label: 'Completion',
                                  value:
                                      '${progressionRules['completionThresholdPercent'] ?? 75}%',
                                  color: AppTheme.success500,
                                ),
                                _BlendPill(
                                  label: 'Assessment',
                                  value:
                                      '${progressionRules['assessmentScoreThresholdPercent'] ?? 60}%',
                                  color: AppTheme.info500,
                                ),
                                _BlendPill(
                                  label: 'Live Participation',
                                  value:
                                      '${progressionRules['liveParticipationThresholdPercent'] ?? 70}%',
                                  color: AppTheme.warning500,
                                ),
                                _BlendPill(
                                  label: 'Project',
                                  value:
                                      (progressionRules['projectSubmissionRequired'] ==
                                          true)
                                      ? 'Required'
                                      : 'Optional',
                                  color: AppTheme.secondary500,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (recognitionSystem.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _chipList(
                        title: 'Recognition System',
                        values: recognitionSystem,
                        color: AppTheme.success500,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Essential Product Requirements',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _lowBandwidthMode,
                      onChanged: (value) {
                        setState(() => _lowBandwidthMode = value);
                      },
                      title: const Text(
                        'Low-bandwidth viewing mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Optimized media loading and compact classroom layout for weak networks.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _parentAccessEnabled,
                      onChanged: (value) {
                        setState(() => _parentAccessEnabled = value);
                      },
                      title: const Text(
                        'Parent access for younger learners',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Enable guardian visibility, alerts, and progress tracking permissions.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _moderationControlsEnabled,
                      onChanged: (value) {
                        setState(() => _moderationControlsEnabled = value);
                      },
                      title: const Text(
                        'Moderation and code-of-conduct controls',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Keep classroom safety workflows active for facilitator and admin teams.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chipList(
                      title: 'Developer Requirements Checklist',
                      values: essentialRequirements,
                      color: AppTheme.secondary500,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Recommended Next Development Documents',
                child: nextDevelopmentDocs.isEmpty
                    ? const Text(
                        'No roadmap documents configured yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        children: nextDevelopmentDocs
                            .map(
                              (doc) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.description_outlined,
                                  color: AppTheme.primary400,
                                ),
                                title: Text(
                                  doc,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Recommended for delivery-quality implementation and team alignment.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              // ──────────────────────────────────────────────────────────
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
                title: 'Level 4 - ImpactUni Implementation Blueprint',
                child: uniBlueprint.isEmpty
                    ? const Text(
                        'ImpactUni implementation details are not available yet.',
                        style: TextStyle(color: AppTheme.textMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoBlock(
                            'Purpose',
                            uniBlueprint['purpose']?.toString() ??
                                'Move learners from knowledge to execution, employability, venture building, and capital awareness.',
                          ),
                          _chipList(
                            title: 'Core Outcomes',
                            values: uniBlueprint['coreOutcomes'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Curriculum Strands',
                            values: uniBlueprint['curriculumStrands'],
                            color: AppTheme.secondary500,
                          ),
                          const SizedBox(height: 10),
                          _termStructurePanel(
                            uniBlueprint['suggestedTermStructure'],
                          ),
                          const SizedBox(height: 10),
                          _chipList(
                            title: 'Signature Experiences',
                            values: uniBlueprint['signatureExperiences'],
                            color: AppTheme.success500,
                          ),
                          const SizedBox(height: 10),
                          _liveFormatPanel(uniBlueprint['liveClassroomFormat']),
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

  String _toolId(Map<String, dynamic> tool) {
    final raw = tool['tool']?.toString().toLowerCase().trim() ?? 'tool';
    return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  IconData _iconFromBlueprint(String? iconName) {
    switch (iconName) {
      case 'how_to_reg':
        return Icons.how_to_reg_outlined;
      case 'notes':
        return Icons.notes_outlined;
      case 'poll':
        return Icons.poll_outlined;
      case 'meeting_room':
        return Icons.meeting_room_outlined;
      case 'draw':
        return Icons.draw_outlined;
      case 'assignment_late':
        return Icons.assignment_late_outlined;
      case 'video_library':
        return Icons.video_library_outlined;
      case 'bar_chart':
        return Icons.bar_chart_outlined;
      case 'shield':
        return Icons.shield_outlined;
      default:
        return Icons.tune_outlined;
    }
  }

  void _activateTool(Map<String, dynamic> tool, {String? message}) {
    setState(() {
      _activeToolIds.add(_toolId(tool));
    });
    if (message != null && message.trim().isNotEmpty) {
      Get.snackbar(
        tool['tool']?.toString() ?? 'Tool Updated',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _advanceConductor(List<Map<String, dynamic>> sequence) {
    if (sequence.isEmpty) return;

    final ordered =
        sequence
            .map((entry) => int.tryParse(entry['step']?.toString() ?? '') ?? 0)
            .where((value) => value > 0)
            .toList()
          ..sort();
    if (ordered.isEmpty) return;

    if (!_sessionInProgress) {
      setState(() {
        _sessionInProgress = true;
        _activeSessionStep = ordered.first;
      });
      return;
    }

    final currentIndex = ordered.indexOf(_activeSessionStep);
    if (currentIndex >= 0 && currentIndex < ordered.length - 1) {
      setState(() {
        _activeSessionStep = ordered[currentIndex + 1];
        _engagementScore = (_engagementScore + 3).clamp(0, 100);
      });
      return;
    }

    setState(() {
      _attendanceConfirmed = true;
      _replayStatus = 'Ready for Publishing';
    });
    Get.snackbar(
      'Session Flow Complete',
      'All live session stages are completed. Publish replay and assignment reminders.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _toolActionLabel(String toolName) {
    final normalized = toolName.toLowerCase();
    if (normalized.contains('attendance')) return 'Take Attendance';
    if (normalized.contains('lesson plan')) return 'Open Notes';
    if (normalized.contains('poll')) return 'Launch Poll';
    if (normalized.contains('breakout')) return 'Create Breakouts';
    if (normalized.contains('whiteboard')) return 'Open Whiteboard';
    if (normalized.contains('assignment')) return 'Send Reminder';
    if (normalized.contains('replay')) return 'Publish Replay';
    if (normalized.contains('participation')) return 'Sync Score';
    if (normalized.contains('safeguarding')) return 'Log Note';
    return 'Activate';
  }

  void _triggerToolAction(Map<String, dynamic> tool) {
    final name = tool['tool']?.toString().toLowerCase() ?? '';
    if (name.contains('attendance')) {
      setState(() {
        _attendanceConfirmed = true;
      });
      _activateTool(
        tool,
        message:
            'Attendance tracker synchronized and session attendance confirmed.',
      );
      return;
    }
    if (name.contains('poll')) {
      setState(() {
        _engagementScore = (_engagementScore + 6).clamp(0, 100);
      });
      _activateTool(
        tool,
        message: 'Live poll launched. Participation score has been updated.',
      );
      return;
    }
    if (name.contains('replay')) {
      setState(() {
        _replayStatus = 'Published';
      });
      _activateTool(
        tool,
        message: 'Replay has been published to learner and school feeds.',
      );
      return;
    }
    if (name.contains('participation')) {
      setState(() {
        _engagementScore = (_engagementScore + 4).clamp(0, 100);
      });
      _activateTool(
        tool,
        message: 'Participation indicator has been recalculated.',
      );
      return;
    }
    if (name.contains('safeguarding')) {
      final note = _incidentNoteCtrl.text.trim();
      if (note.isEmpty) {
        Get.snackbar(
          'Safeguarding Note Required',
          'Enter a note before submitting safeguarding information.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _incidentNoteCtrl.clear();
      _activateTool(
        tool,
        message:
            'Safeguarding note saved and escalated to Programme Coordinator.',
      );
      return;
    }
    _activateTool(
      tool,
      message: 'Tool activated for this live classroom session.',
    );
  }

  Widget _liveSessionConductor({
    required List<Map<String, dynamic>> sessionSequence,
    required List<Map<String, dynamic>> activeSessions,
  }) {
    final orderedStages = [...sessionSequence]
      ..sort((a, b) {
        final sa = int.tryParse(a['step']?.toString() ?? '') ?? 0;
        final sb = int.tryParse(b['step']?.toString() ?? '') ?? 0;
        return sa.compareTo(sb);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BlendPill(
              label: 'Session',
              value: _sessionInProgress ? 'In Progress' : 'Not Started',
              color: AppTheme.info500,
            ),
            _BlendPill(
              label: 'Active Step',
              value: _activeSessionStep.toString(),
              color: AppTheme.primary500,
            ),
            _BlendPill(
              label: 'Attendance',
              value: _attendanceConfirmed ? 'Confirmed' : 'Pending',
              color: _attendanceConfirmed
                  ? AppTheme.success500
                  : AppTheme.warning500,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...orderedStages.map((stage) {
          final step = int.tryParse(stage['step']?.toString() ?? '') ?? 0;
          final isActive = _sessionInProgress && step == _activeSessionStep;
          final isCompleted = _sessionInProgress && step < _activeSessionStep;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary500.withValues(alpha: 0.14)
                  : AppTheme.dark600,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? AppTheme.primary500
                    : isCompleted
                    ? AppTheme.success500.withValues(alpha: 0.5)
                    : AppTheme.dark500,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success500.withValues(alpha: 0.2)
                        : AppTheme.dark700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['label']?.toString() ?? 'Session Stage',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stage['description']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _advanceConductor(orderedStages),
              icon: Icon(
                _sessionInProgress
                    ? Icons.playlist_add_check
                    : Icons.play_arrow,
              ),
              label: Text(
                _sessionInProgress ? 'Continue Session' : 'Start Session',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _attendanceConfirmed = true;
                });
                Get.snackbar(
                  'Attendance Confirmed',
                  'Attendance is confirmed and synced for this live session.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.how_to_reg_outlined),
              label: const Text('Confirm Attendance'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _replayStatus = 'Published';
                });
                Get.snackbar(
                  'Replay Published',
                  'Replay has been published and visible to enrolled learners.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Publish Replay'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Active sessions today: ${activeSessions.length} • Replay status: $_replayStatus',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _facilitatorToolPanel({required List<Map<String, dynamic>> tools}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BlendPill(
              label: 'Tools Active',
              value: '${_activeToolIds.length}/${tools.length}',
              color: AppTheme.primary500,
            ),
            _BlendPill(
              label: 'Engagement Score',
              value: '$_engagementScore%',
              color: AppTheme.success500,
            ),
            _BlendPill(
              label: 'Replay',
              value: _replayStatus,
              color: AppTheme.info500,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_engagementScore / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.dark500,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.success500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...tools.map((tool) {
          final toolName = tool['tool']?.toString() ?? 'Tool';
          final toolDesc = tool['description']?.toString() ?? '';
          final toolId = _toolId(tool);
          final isActive = _activeToolIds.contains(toolId);
          final isSafeguarding = toolName.toLowerCase().contains(
            'safeguarding',
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.dark600,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppTheme.success500.withValues(alpha: 0.45)
                    : AppTheme.dark500,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary500.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _iconFromBlueprint(tool['icon']?.toString()),
                        color: AppTheme.primary400,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toolName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            toolDesc,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.success500.withValues(alpha: 0.18)
                            : AppTheme.warning500.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Ready',
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.success500
                              : AppTheme.warning500,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSafeguarding) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _incidentNoteCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: AppTheme.darkInput(
                      hint:
                          'Incident / safeguarding note (captured with timestamp and escalation route)',
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _triggerToolAction(tool),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: Text(_toolActionLabel(toolName)),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
    final uniBlueprint = classroomController.levelFourImpactUniBlueprint;

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
      if (uniBlueprint.isNotEmpty)
        {
          'id': 'impactuni',
          'title': 'ImpactUni (18+)',
          'blueprint': uniBlueprint,
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
    final mediaPicker = ImagePicker();
    final selectedUploadedAssets = <Map<String, dynamic>>[];
    String selectedAssessmentTrack = 'quiz_short_test';
    String selectedRecognitionTrack = 'skill_badge';
    int completionThresholdPercent = 75;
    int assessmentThresholdPercent = 60;
    int liveParticipationThresholdPercent = 70;
    bool projectSubmissionRequired = true;

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
            Future<void> pickPdfAsset() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result == null || result.files.isEmpty) return;
              final file = result.files.first;
              final filePath = file.path;
              if (filePath == null) return;

              try {
                final bytes = await File(filePath).length();
                final signResponse = await _apiService.requestSignedUpload(
                  fileName: file.name,
                  mimeType: 'application/pdf',
                  byteSize: bytes,
                  accessScope: 'private',
                  purpose: 'classroom_material',
                );

                final uploadData =
                    (signResponse['data']?['upload'] ?? {})
                        as Map<String, dynamic>;
                final assetId = signResponse['data']?['assetId'];
                final uploadUrl = uploadData['uploadUrl']?.toString();
                if (assetId == null || uploadUrl == null || uploadUrl.isEmpty) {
                  throw Exception('Upload initialization failed');
                }

                final cloudResponse = await _apiService
                    .uploadToSignedCloudinary(
                      uploadUrl: uploadUrl,
                      filePath: filePath,
                      fields: {
                        'api_key': uploadData['apiKey'],
                        'timestamp': uploadData['timestamp'],
                        'folder': uploadData['folder'],
                        'public_id': uploadData['publicId'],
                        'signature': uploadData['signature'],
                      },
                    );

                final complete = await _apiService.completeSignedUpload(
                  assetId: assetId is int
                      ? assetId
                      : int.parse(assetId.toString()),
                  secureUrl: cloudResponse['secure_url']?.toString() ?? '',
                  uploadedBytes: bytes,
                  format: cloudResponse['format']?.toString(),
                );

                final secureUrl =
                    complete['data']?['metadata']?['secureUrl']?.toString() ??
                    cloudResponse['secure_url']?.toString() ??
                    '';

                setSheetState(() {
                  selectedUploadedAssets.add({
                    'type': 'pdf',
                    'name': file.name,
                    'source': 'cloudinary',
                    'assetId': assetId,
                    'url': secureUrl,
                  });
                  if (downloadableCtrl.text.trim().isEmpty) {
                    downloadableCtrl.text = file.name;
                  } else {
                    downloadableCtrl.text =
                        '${downloadableCtrl.text.trim()}, ${file.name}';
                  }
                  if (resourceCtrl.text.trim().isEmpty &&
                      secureUrl.isNotEmpty) {
                    resourceCtrl.text = secureUrl;
                  }
                });

                await _apiService.trackAnalyticsEvent(
                  eventName: 'assignment_submitted',
                  resourceType: 'media_asset',
                  resourceId: assetId is int
                      ? assetId
                      : int.tryParse(assetId.toString()),
                  metadata: {
                    'assetType': 'pdf',
                    'context': 'facilitator_create_activity',
                  },
                );
              } catch (error) {
                Get.snackbar(
                  'Upload Failed',
                  'PDF upload could not be completed. $error',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }

            Future<void> pickImageAsset() async {
              final file = await mediaPicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (file == null) return;

              final extension = file.name.toLowerCase().endsWith('.png')
                  ? 'image/png'
                  : file.name.toLowerCase().endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg';

              try {
                final bytes = await File(file.path).length();
                final signResponse = await _apiService.requestSignedUpload(
                  fileName: file.name,
                  mimeType: extension,
                  byteSize: bytes,
                  accessScope: 'private',
                  purpose: 'classroom_material',
                );

                final uploadData =
                    (signResponse['data']?['upload'] ?? {})
                        as Map<String, dynamic>;
                final assetId = signResponse['data']?['assetId'];
                final uploadUrl = uploadData['uploadUrl']?.toString();
                if (assetId == null || uploadUrl == null || uploadUrl.isEmpty) {
                  throw Exception('Upload initialization failed');
                }

                final cloudResponse = await _apiService
                    .uploadToSignedCloudinary(
                      uploadUrl: uploadUrl,
                      filePath: file.path,
                      fields: {
                        'api_key': uploadData['apiKey'],
                        'timestamp': uploadData['timestamp'],
                        'folder': uploadData['folder'],
                        'public_id': uploadData['publicId'],
                        'signature': uploadData['signature'],
                      },
                    );

                final complete = await _apiService.completeSignedUpload(
                  assetId: assetId is int
                      ? assetId
                      : int.parse(assetId.toString()),
                  secureUrl: cloudResponse['secure_url']?.toString() ?? '',
                  uploadedBytes: bytes,
                  format: cloudResponse['format']?.toString(),
                  width: cloudResponse['width'] is int
                      ? cloudResponse['width']
                      : int.tryParse((cloudResponse['width'] ?? '').toString()),
                  height: cloudResponse['height'] is int
                      ? cloudResponse['height']
                      : int.tryParse(
                          (cloudResponse['height'] ?? '').toString(),
                        ),
                );

                final secureUrl =
                    complete['data']?['metadata']?['secureUrl']?.toString() ??
                    cloudResponse['secure_url']?.toString() ??
                    '';

                setSheetState(() {
                  selectedUploadedAssets.add({
                    'type': 'image',
                    'name': file.name,
                    'source': 'cloudinary',
                    'assetId': assetId,
                    'url': secureUrl,
                  });
                  if (resourceCtrl.text.trim().isEmpty &&
                      secureUrl.isNotEmpty) {
                    resourceCtrl.text = secureUrl;
                  }
                });

                await _apiService.trackAnalyticsEvent(
                  eventName: 'assignment_submitted',
                  resourceType: 'media_asset',
                  resourceId: assetId is int
                      ? assetId
                      : int.tryParse(assetId.toString()),
                  metadata: {
                    'assetType': 'image',
                    'context': 'facilitator_create_activity',
                  },
                );
              } catch (error) {
                Get.snackbar(
                  'Upload Failed',
                  'Image upload could not be completed. $error',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }

            Future<void> pickVideoAsset() async {
              final file = await mediaPicker.pickVideo(
                source: ImageSource.gallery,
                maxDuration: const Duration(minutes: 20),
              );
              if (file == null) return;

              final lowerName = file.name.toLowerCase();
              final mimeType = lowerName.endsWith('.mov')
                  ? 'video/quicktime'
                  : lowerName.endsWith('.mkv')
                  ? 'video/x-matroska'
                  : 'video/mp4';

              try {
                final bytes = await File(file.path).length();
                final signResponse = await _apiService.requestSignedUpload(
                  fileName: file.name,
                  mimeType: mimeType,
                  byteSize: bytes,
                  accessScope: 'private',
                  purpose: 'classroom_recording',
                );

                final uploadData =
                    (signResponse['data']?['upload'] ?? {})
                        as Map<String, dynamic>;
                final assetId = signResponse['data']?['assetId'];
                final uploadUrl = uploadData['uploadUrl']?.toString();
                if (assetId == null || uploadUrl == null || uploadUrl.isEmpty) {
                  throw Exception('Upload initialization failed');
                }

                final cloudResponse = await _apiService
                    .uploadToSignedCloudinary(
                      uploadUrl: uploadUrl,
                      filePath: file.path,
                      fields: {
                        'api_key': uploadData['apiKey'],
                        'timestamp': uploadData['timestamp'],
                        'folder': uploadData['folder'],
                        'public_id': uploadData['publicId'],
                        'signature': uploadData['signature'],
                      },
                    );

                final complete = await _apiService.completeSignedUpload(
                  assetId: assetId is int
                      ? assetId
                      : int.parse(assetId.toString()),
                  secureUrl: cloudResponse['secure_url']?.toString() ?? '',
                  uploadedBytes: bytes,
                  format: cloudResponse['format']?.toString(),
                  duration: cloudResponse['duration'] is num
                      ? cloudResponse['duration']
                      : num.tryParse(
                          (cloudResponse['duration'] ?? '').toString(),
                        ),
                  width: cloudResponse['width'] is int
                      ? cloudResponse['width']
                      : int.tryParse((cloudResponse['width'] ?? '').toString()),
                  height: cloudResponse['height'] is int
                      ? cloudResponse['height']
                      : int.tryParse(
                          (cloudResponse['height'] ?? '').toString(),
                        ),
                );

                final secureUrl =
                    complete['data']?['metadata']?['secureUrl']?.toString() ??
                    cloudResponse['secure_url']?.toString() ??
                    '';

                setSheetState(() {
                  selectedUploadedAssets.add({
                    'type': 'video',
                    'name': file.name,
                    'source': 'cloudinary',
                    'assetId': assetId,
                    'url': secureUrl,
                  });
                  if (resourceCtrl.text.trim().isEmpty &&
                      secureUrl.isNotEmpty) {
                    resourceCtrl.text = secureUrl;
                  }
                });

                await _apiService.trackAnalyticsEvent(
                  eventName: 'assignment_submitted',
                  resourceType: 'media_asset',
                  resourceId: assetId is int
                      ? assetId
                      : int.tryParse(assetId.toString()),
                  metadata: {
                    'assetType': 'video',
                    'context': 'facilitator_create_activity',
                  },
                );
              } catch (error) {
                Get.snackbar(
                  'Upload Failed',
                  'Video upload could not be completed. $error',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }

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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.info500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.info500.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Course and Assessment Asset Upload',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Upload PDF, image, and video assets used for course content, assignments, and classroom replay references.',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: pickPdfAsset,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Upload PDF'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: pickImageAsset,
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Upload Image'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: pickVideoAsset,
                                  icon: const Icon(Icons.video_file_outlined),
                                  label: const Text('Upload Video'),
                                ),
                              ],
                            ),
                            if (selectedUploadedAssets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedUploadedAssets
                                    .map(
                                      (asset) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dark700,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          '${asset['type']?.toUpperCase() ?? 'ASSET'} • ${asset['name'] ?? ''}',
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
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Assessment Track',
                        value: selectedAssessmentTrack,
                        items: const [
                          {
                            'id': 'quiz_short_test',
                            'title': 'Quizzes and short tests',
                          },
                          {
                            'id': 'worksheet_practical',
                            'title': 'Worksheets and practical tasks',
                          },
                          {
                            'id': 'reflection_journal',
                            'title': 'Reflection journals',
                          },
                          {
                            'id': 'project_submission',
                            'title': 'Project submissions',
                          },
                          {
                            'id': 'live_attendance',
                            'title': 'Live classroom attendance',
                          },
                          {
                            'id': 'participation_presentation',
                            'title': 'Participation and presentation scores',
                          },
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedAssessmentTrack = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _dropdownField(
                        label: 'Recognition Trigger',
                        value: selectedRecognitionTrack,
                        items: const [
                          {'id': 'skill_badge', 'title': 'Skill badge'},
                          {'id': 'value_badge', 'title': 'Value badge'},
                          {
                            'id': 'attendance_recognition',
                            'title': 'Attendance recognition',
                          },
                          {
                            'id': 'term_certificate',
                            'title': 'Term certificate',
                          },
                          {
                            'id': 'level_certificate',
                            'title': 'Level completion certificate',
                          },
                          {'id': 'showcase_award', 'title': 'Showcase award'},
                          {
                            'id': 'facilitator_recommendation',
                            'title': 'Facilitator recommendation marker',
                          },
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedRecognitionTrack = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: projectSubmissionRequired,
                        onChanged: (value) {
                          setSheetState(
                            () => projectSubmissionRequired = value,
                          );
                        },
                        title: const Text(
                          'Require project submission for progression',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completion threshold: $completionThresholdPercent%',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      Slider(
                        min: 40,
                        max: 100,
                        divisions: 12,
                        value: completionThresholdPercent.toDouble(),
                        onChanged: (value) {
                          setSheetState(() {
                            completionThresholdPercent = value.round();
                          });
                        },
                      ),
                      Text(
                        'Assessment threshold: $assessmentThresholdPercent%',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      Slider(
                        min: 40,
                        max: 100,
                        divisions: 12,
                        value: assessmentThresholdPercent.toDouble(),
                        onChanged: (value) {
                          setSheetState(() {
                            assessmentThresholdPercent = value.round();
                          });
                        },
                      ),
                      Text(
                        'Live participation threshold: $liveParticipationThresholdPercent%',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      Slider(
                        min: 40,
                        max: 100,
                        divisions: 12,
                        value: liveParticipationThresholdPercent.toDouble(),
                        onChanged: (value) {
                          setSheetState(() {
                            liveParticipationThresholdPercent = value.round();
                          });
                        },
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
                        key: const Key('create_activity_publish_button'),
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
                            'uploadedAssets': selectedUploadedAssets,
                            'assessmentSignals': [selectedAssessmentTrack],
                            'progressionRules': {
                              'completionThresholdPercent':
                                  completionThresholdPercent,
                              'assessmentScoreThresholdPercent':
                                  assessmentThresholdPercent,
                              'liveParticipationThresholdPercent':
                                  liveParticipationThresholdPercent,
                              'projectSubmissionRequired':
                                  projectSubmissionRequired,
                            },
                            'recognitionTargets': [selectedRecognitionTrack],
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
                            await _apiService.trackAnalyticsEvent(
                              eventName: 'quiz_submitted',
                              resourceType: 'classroom_activity',
                              metadata: {
                                'activityType': activityType,
                                'learningLayer': selectedLayer,
                                'assessmentTrack': selectedAssessmentTrack,
                              },
                            );
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
      isExpanded: true,
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
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        key: key,
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
