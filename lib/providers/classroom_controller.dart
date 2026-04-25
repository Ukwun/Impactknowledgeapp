import 'package:get/get.dart';
import '../config/service_locator.dart';
import '../services/api/api_service.dart';

class ClassroomController extends GetxController {
  final ApiService _apiService = getIt<ApiService>();

  final isLoading = false.obs;
  final error = ''.obs;
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
}
