import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:impactknowledge_app/config/service_locator.dart';
import 'package:impactknowledge_app/providers/classroom_controller.dart';
import 'package:impactknowledge_app/screens/classroom/facilitator_classroom_screen.dart';
import 'package:impactknowledge_app/services/api/api_service.dart';

class _TestClassroomController extends ClassroomController {
  @override
  Future<void> loadExperience() async {
    // No network calls in widget smoke test.
    return;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    if (!getIt.isRegistered<ApiService>()) {
      getIt.registerSingleton<ApiService>(ApiService());
    }
  });

  tearDown(() async {
    Get.reset();
    await getIt.reset();
  });

  testWidgets('Create Activity supports Blueprint Track switching to Senior Secondary', (
    tester,
  ) async {
    final controller = _TestClassroomController();

    controller.blueprint.assignAll({
      'fourLevelCurriculumFramework': [
        {
          'key': 'primary',
          'level': 'Primary',
          'ageGroup': '7-11',
          'coreOutcomes': ['Build money awareness'],
          'curriculumStrands': ['My Money Habits'],
          'suggestedTermStructure': [
            {
              'term': 'Term 1',
              'focus': 'Foundation Habits',
              'illustrativeTopics': ['Needs vs wants'],
            },
          ],
          'liveClassroomFormat': {
            'frequency': 'One live class per week',
            'durationMinutes': 45,
            'methods': ['Guided discussion'],
          },
        },
        {
          'key': 'junior_secondary',
          'level': 'Junior Secondary',
          'ageGroup': '12-14',
          'coreOutcomes': ['Build practical financial habits'],
          'curriculumStrands': ['Enterprise Basics'],
          'suggestedTermStructure': [
            {
              'term': 'Term 1',
              'focus': 'Enterprise Foundations',
              'illustrativeTopics': ['Simple cost and price work'],
            },
          ],
          'liveClassroomFormat': {
            'frequency': 'One live class per week',
            'durationMinutes': 60,
            'methods': ['Scenario work'],
          },
        },
        {
          'key': 'senior_secondary',
          'level': 'Senior Secondary',
          'ageGroup': '15-18',
          'coreOutcomes': [
            'Write a basic business plan',
            'Prepare simple financial projections',
          ],
          'curriculumStrands': [
            'Venture Design',
            'Financial Planning and Projections',
          ],
          'suggestedTermStructure': [
            {
              'term': 'Term 1',
              'focus': 'Business Design',
              'illustrativeTopics': ['Opportunity identification'],
            },
          ],
          'liveClassroomFormat': {
            'frequency': 'One live class per week',
            'durationMinutes': 75,
            'methods': ['Pitch practice'],
          },
        },
      ],
    });

    controller.hierarchy.assignAll([
      {
        'name': 'Impact Classroom',
        'levels': [
          {
            'name': 'Primary',
            'cycles': [
              {
                'id': 'cycle-1',
                'name': 'Cycle 1',
                'modules': [
                  {
                    'title': 'Module 1',
                    'lessons': [
                      {
                        'id': 'lesson-1',
                        'title': 'Lesson 1',
                        'layer': 'learn',
                        'activities': [],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    ]);

    Get.put<ClassroomController>(controller);

    await tester.pumpWidget(
      const GetMaterialApp(home: FacilitatorClassroomScreen()),
    );
    await tester.pumpAndSettle();

    final createActivityButton = find.byKey(
      const Key('facilitator_create_activity_button'),
    );
    expect(createActivityButton, findsOneWidget);

    await tester.ensureVisible(createActivityButton);
    await tester.tap(createActivityButton);
    await tester.pumpAndSettle();

    final blueprintDropdown = find.byKey(
      const Key('create_activity_blueprint_track_dropdown'),
    );
    expect(
      blueprintDropdown,
      findsOneWidget,
      reason:
          'Blueprint Track dropdown should be visible in Create Activity sheet',
    );

    // Ensure dropdown field is visible before tapping
    await tester.ensureVisible(blueprintDropdown);
    await tester.pumpAndSettle();

    // Tap the dropdown to open it
    await tester.tap(blueprintDropdown);
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    // Find the Senior Secondary menu item in the dropdown overlay
    // The dropdown renders items in a scrollable menu overlay
    final seniorSecondaryTextFinder = find.text(
      'Level 3 - Senior Secondary (15-18)',
    );
    expect(
      seniorSecondaryTextFinder,
      findsWidgets,
      reason: 'Level 3 Senior Secondary option should exist in dropdown menu',
    );

    // Tap the Senior Secondary option - use last occurrence to get the menu item
    await tester.tap(seniorSecondaryTextFinder.last);
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    // After selecting Senior Secondary, the autofill should populate the title
    // The title controller should be set to: 'Venture Design - Business Design'
    final titleTextFinder = find.text('Venture Design - Business Design');
    expect(
      titleTextFinder,
      findsOneWidget,
      reason:
          'Title should be autofilled with "Venture Design - Business Design" after selecting Senior Secondary',
    );
  });
}
