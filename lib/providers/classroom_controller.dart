import 'package:get/get.dart';
import '../config/service_locator.dart';
import '../services/api/api_service.dart';

class ClassroomController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final error = ''.obs;
  final actionMessage = ''.obs;
  final blueprint = <String, dynamic>{}.obs;
  final hierarchy = <Map<String, dynamic>>[].obs;

  Future<void> loadExperience() async {
    isLoading.value = true;
    error.value = '';

    try {
      final results = await Future.wait([
        _apiService.getClassroomBlueprint(),
        _apiService.getClassroomHierarchy(),
      ]);

      final blueprintResponse = results[0];
      final hierarchyResponse = results[1];

      final blueprintData = blueprintResponse['data'];
      if (blueprintData is Map<String, dynamic>) {
        blueprint.assignAll(blueprintData);
      } else {
        blueprint.clear();
      }

      final hierarchyData = hierarchyResponse['data'];
      if (hierarchyData is List) {
        hierarchy.assignAll(
          hierarchyData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      } else {
        hierarchy.clear();
      }
    } catch (e) {
      error.value = 'Failed to load classroom experience: $e';
    } finally {
      isLoading.value = false;
    }
  }

  String get programmeName {
    if (hierarchy.isEmpty) return 'Impact Classroom';
    final name = hierarchy.first['name']?.toString();
    return (name == null || name.isEmpty) ? 'Impact Classroom' : name;
  }

  String get currentLevelName {
    if (hierarchy.isEmpty) return 'General Level';
    final levels = hierarchy.first['levels'];
    if (levels is! List || levels.isEmpty) return 'General Level';
    return levels.first['name']?.toString() ?? 'General Level';
  }

  String get currentCycleName {
    if (hierarchy.isEmpty) return 'Current Cycle';
    final levels = hierarchy.first['levels'];
    if (levels is! List || levels.isEmpty) return 'Current Cycle';
    final cycles = levels.first['cycles'];
    if (cycles is! List || cycles.isEmpty) return 'Current Cycle';
    return cycles.first['name']?.toString() ?? 'Current Cycle';
  }

  List<Map<String, dynamic>> get learningLayers {
    final source = blueprint['learningArchitecture'];
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get upcomingLiveSessions {
    final sessions = <Map<String, dynamic>>[];

    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;

      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;

        for (final cycle in cycles.whereType<Map>()) {
          final cycleName = cycle['name']?.toString() ?? 'Cycle';
          final liveSessions = cycle['liveSessions'];
          if (liveSessions is! List) continue;

          for (final session in liveSessions.whereType<Map>()) {
            sessions.add({
              ...Map<String, dynamic>.from(session),
              'cycleName': cycleName,
              'levelName': level['name']?.toString() ?? 'Level',
              'programmeName': programme['name']?.toString() ?? 'Programme',
            });
          }
        }
      }
    }

    sessions.sort((a, b) {
      final aTime = DateTime.tryParse(a['starts_at']?.toString() ?? '');
      final bTime = DateTime.tryParse(b['starts_at']?.toString() ?? '');
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return sessions;
  }

  List<Map<String, dynamic>> get learnerTasks {
    final tasks = <Map<String, dynamic>>[];

    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;

      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;

        for (final cycle in cycles.whereType<Map>()) {
          final modules = cycle['modules'];
          if (modules is! List) continue;

          for (final module in modules.whereType<Map>()) {
            final lessons = module['lessons'];
            if (lessons is! List) continue;

            for (final lesson in lessons.whereType<Map>()) {
              final layer = lesson['layer']?.toString() ?? 'learn';
              final activities = lesson['activities'];

              if (activities is List && activities.isNotEmpty) {
                for (final activity in activities.whereType<Map>()) {
                  tasks.add({
                    'title': activity['title']?.toString() ?? 'Activity',
                    'type': activity['activity_type']?.toString() ?? 'task',
                    'layer': layer,
                    'lessonTitle': lesson['title']?.toString() ?? 'Lesson',
                    'moduleTitle': module['title']?.toString() ?? 'Module',
                    'required': activity['is_required'] == true,
                    'status': (activity['metadata'] is Map)
                        ? (activity['metadata']['status']?.toString() ??
                              'pending')
                        : 'pending',
                  });
                }
              } else {
                tasks.add({
                  'title': lesson['title']?.toString() ?? 'Lesson task',
                  'type': 'lesson',
                  'layer': layer,
                  'lessonTitle': lesson['title']?.toString() ?? 'Lesson',
                  'moduleTitle': module['title']?.toString() ?? 'Module',
                  'required': true,
                  'status': 'pending',
                });
              }
            }
          }
        }
      }
    }

    return tasks;
  }

  List<Map<String, dynamic>> get badgesAndCertificates {
    final items = <Map<String, dynamic>>[];

    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;

      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;

        for (final cycle in cycles.whereType<Map>()) {
          final assessments = cycle['assessments'];
          if (assessments is List) {
            for (final assessment in assessments.whereType<Map>()) {
              final badges = assessment['badges'];
              if (badges is! List) continue;
              for (final badge in badges.whereType<Map>()) {
                items.add({
                  ...Map<String, dynamic>.from(badge),
                  'sourceType': 'assessment',
                  'sourceTitle':
                      assessment['title']?.toString() ?? 'Assessment',
                });
              }
            }
          }

          final showcases = cycle['showcases'];
          if (showcases is List) {
            for (final showcase in showcases.whereType<Map>()) {
              final badges = showcase['badges'];
              if (badges is! List) continue;
              for (final badge in badges.whereType<Map>()) {
                items.add({
                  ...Map<String, dynamic>.from(badge),
                  'sourceType': 'showcase',
                  'sourceTitle': showcase['title']?.toString() ?? 'Showcase',
                });
              }
            }
          }
        }
      }
    }

    return items;
  }

  int get totalTaskCount => learnerTasks.length;

  int get completedTaskCount {
    return learnerTasks
        .where(
          (task) =>
              (task['status']?.toString().toLowerCase() == 'completed') ||
              (task['status']?.toString().toLowerCase() == 'done'),
        )
        .length;
  }

  double get taskProgress {
    if (totalTaskCount == 0) return 0;
    return completedTaskCount / totalTaskCount;
  }

  List<Map<String, dynamic>> get contentObjectFields {
    final source = blueprint['contentObjectFields'];
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get subscriptionPathways {
    final source = blueprint['subscriptionDeliveryModel'];
    if (source is! Map<String, dynamic>) return [];
    final pathways = source['pathways'];
    if (pathways is! List) return [];
    return pathways
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> get recommendedDeliveryBlend {
    final source = blueprint['subscriptionDeliveryModel'];
    if (source is! Map<String, dynamic>) return {};
    final blend = source['recommendedBlend'];
    return blend is Map<String, dynamic>
        ? blend
        : blend is Map
        ? Map<String, dynamic>.from(blend)
        : {};
  }

  List<Map<String, dynamic>> get weeklyClassroomRhythm {
    final source = blueprint['weeklyClassroomRhythm'];
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> get liveFacilitatorFramework {
    final source = blueprint['liveFacilitatorFramework'];
    if (source is Map<String, dynamic>) return source;
    if (source is Map) return Map<String, dynamic>.from(source);
    return {};
  }

  List<Map<String, dynamic>> get liveFacilitatorRoles {
    final roles = liveFacilitatorFramework['roles'];
    if (roles is! List) return [];
    return roles
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get liveSessionSequence {
    final seq = liveFacilitatorFramework['standardSessionSequence'];
    if (seq is! List) return [];
    return seq
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get facilitatorToolRequirements {
    final tools = liveFacilitatorFramework['toolRequirements'];
    if (tools is! List) return [];
    return tools
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get fourLevelCurriculumFramework {
    final source = blueprint['fourLevelCurriculumFramework'];
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> get currentCurriculumLevelProfile {
    final framework = fourLevelCurriculumFramework;
    if (framework.isEmpty) return {};

    final current = currentLevelName.toLowerCase().trim();
    if (current.isEmpty) return framework.first;

    for (final item in framework) {
      final levelName = item['level']?.toString().toLowerCase().trim() ?? '';
      if (levelName.isNotEmpty &&
          (current.contains(levelName) || levelName.contains(current))) {
        return item;
      }

      final aliases = item['aliases'];
      if (aliases is List) {
        for (final alias in aliases) {
          final normalizedAlias = alias.toString().toLowerCase().trim();
          if (normalizedAlias.isNotEmpty &&
              (current.contains(normalizedAlias) ||
                  normalizedAlias.contains(current))) {
            return item;
          }
        }
      }
    }

    return framework.first;
  }

  Map<String, dynamic> get levelOnePrimaryBlueprint {
    final framework = fourLevelCurriculumFramework;
    for (final item in framework) {
      if (item['key']?.toString() == 'primary') {
        return item;
      }
    }
    return {};
  }

  Map<String, dynamic> get levelTwoJuniorSecondaryBlueprint {
    final framework = fourLevelCurriculumFramework;
    for (final item in framework) {
      if (item['key']?.toString() == 'junior_secondary') {
        return item;
      }
    }
    return {};
  }

  Map<String, dynamic> get levelThreeSeniorSecondaryBlueprint {
    final framework = fourLevelCurriculumFramework;
    for (final item in framework) {
      if (item['key']?.toString() == 'senior_secondary') {
        return item;
      }
    }
    return {};
  }

  Map<String, dynamic> get levelFourImpactUniBlueprint {
    final framework = fourLevelCurriculumFramework;
    for (final item in framework) {
      if (item['key']?.toString() == 'impactuni') {
        return item;
      }
    }
    return {};
  }

  List<Map<String, dynamic>> get cycleOptions {
    final items = <Map<String, dynamic>>[];
    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;
      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;
        for (final cycle in cycles.whereType<Map>()) {
          items.add({
            'id': cycle['id']?.toString() ?? '',
            'title': cycle['name']?.toString() ?? 'Cycle',
            'subtitle':
                '${programme['name'] ?? 'Programme'} • ${level['name'] ?? 'Level'}',
          });
        }
      }
    }
    return items.where((item) => (item['id'] as String).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get lessonOptions {
    final items = <Map<String, dynamic>>[];
    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;
      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;
        for (final cycle in cycles.whereType<Map>()) {
          final modules = cycle['modules'];
          if (modules is! List) continue;
          for (final module in modules.whereType<Map>()) {
            final lessons = module['lessons'];
            if (lessons is! List) continue;
            for (final lesson in lessons.whereType<Map>()) {
              items.add({
                'id': lesson['id']?.toString() ?? '',
                'title': lesson['title']?.toString() ?? 'Lesson',
                'subtitle':
                    '${cycle['name'] ?? 'Cycle'} • ${module['title'] ?? 'Module'}',
                'layer': lesson['layer']?.toString() ?? 'learn',
              });
            }
          }
        }
      }
    }
    return items.where((item) => (item['id'] as String).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get assessmentOptions {
    final items = <Map<String, dynamic>>[];
    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;
      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;
        for (final cycle in cycles.whereType<Map>()) {
          final assessments = cycle['assessments'];
          if (assessments is! List) continue;
          for (final assessment in assessments.whereType<Map>()) {
            items.add({
              'id': assessment['id']?.toString() ?? '',
              'title': assessment['title']?.toString() ?? 'Assessment',
              'subtitle':
                  '${cycle['name'] ?? 'Cycle'} • ${assessment['assessment_type'] ?? 'assessment'}',
            });
          }
        }
      }
    }
    return items.where((item) => (item['id'] as String).isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get showcaseOptions {
    final items = <Map<String, dynamic>>[];
    for (final programme in hierarchy) {
      final levels = programme['levels'];
      if (levels is! List) continue;
      for (final level in levels.whereType<Map>()) {
        final cycles = level['cycles'];
        if (cycles is! List) continue;
        for (final cycle in cycles.whereType<Map>()) {
          final showcases = cycle['showcases'];
          if (showcases is! List) continue;
          for (final showcase in showcases.whereType<Map>()) {
            items.add({
              'id': showcase['id']?.toString() ?? '',
              'title': showcase['title']?.toString() ?? 'Showcase',
              'subtitle':
                  '${cycle['name'] ?? 'Cycle'} • ${showcase['submission_type'] ?? 'project'}',
            });
          }
        }
      }
    }
    return items.where((item) => (item['id'] as String).isNotEmpty).toList();
  }

  void clearActionMessage() {
    actionMessage.value = '';
  }

  Future<bool> createLiveSession({
    required String cycleId,
    required String title,
    required String startsAt,
    String sessionType = 'facilitator_class',
    String? joinUrl,
    String? notes,
    String? endsAt,
    String? moduleId,
    int? capacity,
  }) async {
    return _runCreateAction(
      () async {
        final response = await _apiService.createClassroomLiveSession(cycleId, {
          'title': title,
          'startsAt': startsAt,
          'sessionType': sessionType,
          if (joinUrl != null && joinUrl.isNotEmpty) 'joinUrl': joinUrl,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (endsAt != null && endsAt.isNotEmpty) 'endsAt': endsAt,
          'moduleId': (moduleId != null && moduleId.isNotEmpty)
              ? int.tryParse(moduleId)
              : null,
          ...?(capacity != null ? {'capacity': capacity} : null),
        });

        return response['success'] == true;
      },
      successMessage:
          'Live session created and published to the classroom flow.',
    );
  }

  Future<bool> createActivity({
    required String lessonId,
    required String title,
    required String activityType,
    required String learningLayer,
    String? instructions,
    String? resourceUrl,
    bool isRequired = true,
    Map<String, dynamic>? metadata,
  }) async {
    return _runCreateAction(() async {
      final response = await _apiService.createClassroomActivity(lessonId, {
        'title': title,
        'activityType': activityType,
        'learningLayer': learningLayer,
        'isRequired': isRequired,
        if (instructions != null && instructions.isNotEmpty)
          'instructions': instructions,
        if (resourceUrl != null && resourceUrl.isNotEmpty)
          'resourceUrl': resourceUrl,
        ...?(metadata != null ? {'metadata': metadata} : null),
      });

      return response['success'] == true;
    }, successMessage: 'Learning activity added to the classroom sequence.');
  }

  Future<bool> createBadgeRule({
    required String title,
    required String badgeType,
    String? criteria,
    String? certificateTemplateUrl,
    String? assessmentId,
    String? showcaseId,
    int pointsReward = 0,
  }) async {
    return _runCreateAction(() async {
      final response = await _apiService.createClassroomBadgeRule({
        'title': title,
        'badgeType': badgeType,
        if (criteria != null && criteria.isNotEmpty) 'criteria': criteria,
        if (certificateTemplateUrl != null && certificateTemplateUrl.isNotEmpty)
          'certificateTemplateUrl': certificateTemplateUrl,
        'assessmentId': (assessmentId != null && assessmentId.isNotEmpty)
            ? int.tryParse(assessmentId)
            : null,
        'showcaseId': (showcaseId != null && showcaseId.isNotEmpty)
            ? int.tryParse(showcaseId)
            : null,
        'pointsReward': pointsReward,
      });

      return response['success'] == true;
    }, successMessage: 'Badge/certificate rule saved for this classroom.');
  }

  Future<bool> _runCreateAction(
    Future<bool> Function() action, {
    required String successMessage,
  }) async {
    isSubmitting.value = true;
    error.value = '';
    actionMessage.value = '';

    try {
      final success = await action();
      if (success) {
        await loadExperience();
        actionMessage.value = successMessage;
        return true;
      }
      error.value = 'The classroom action did not complete successfully.';
      return false;
    } catch (e) {
      error.value = 'Failed to complete classroom action: $e';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
