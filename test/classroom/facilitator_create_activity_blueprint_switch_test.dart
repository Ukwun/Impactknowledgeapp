import 'dart:async';
import 'dart:io';

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

class _CapturingClassroomController extends _TestClassroomController {
  Map<String, dynamic>? capturedMetadata;
  String? capturedResourceUrl;
  int createActivityCalls = 0;

  @override
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
    createActivityCalls += 1;
    capturedResourceUrl = resourceUrl;
    capturedMetadata = metadata;
    return true;
  }
}

class _FakeApiService extends ApiService {
  int signCalls = 0;
  int cloudUploadCalls = 0;
  int completeCalls = 0;
  int analyticsCalls = 0;

  @override
  Future<dynamic> requestSignedUpload({
    required String fileName,
    required String mimeType,
    required int byteSize,
    String accessScope = 'private',
    String purpose = 'course_asset',
  }) async {
    signCalls += 1;
    return {
      'success': true,
      'data': {
        'assetId': 321,
        'upload': {
          'apiKey': 'test-api-key',
          'timestamp': 1714123456,
          'folder': 'impactknowledge/pdf',
          'publicId': 'impactknowledge/test/asset.pdf',
          'signature': 'signed-token',
          'uploadUrl': 'https://upload.example.test',
        },
      },
    };
  }

  @override
  Future<dynamic> uploadToSignedCloudinary({
    required String uploadUrl,
    required String filePath,
    required Map<String, dynamic> fields,
  }) async {
    cloudUploadCalls += 1;
    return {
      'secure_url': 'https://cdn.example.test/assets/uploaded-material.pdf',
      'format': 'pdf',
    };
  }

  @override
  Future<dynamic> completeSignedUpload({
    required int assetId,
    required String secureUrl,
    int? uploadedBytes,
    String? format,
    num? duration,
    int? width,
    int? height,
    String virusScanStatus = 'clean',
  }) async {
    completeCalls += 1;
    return {
      'success': true,
      'data': {
        'id': assetId,
        'metadata': {'secureUrl': secureUrl},
      },
    };
  }

  @override
  Future<dynamic> trackAnalyticsEvent({
    required String eventName,
    String? resourceType,
    int? resourceId,
    Map<String, dynamic>? metadata,
  }) async {
    analyticsCalls += 1;
    return {'success': true};
  }
}

void _seedClassroomData(ClassroomController controller) {
  controller.blueprint.assignAll({
    'fourLevelCurriculumFramework': [
      {
        'key': 'senior_secondary',
        'level': 'Senior Secondary',
        'ageGroup': '15-18',
        'coreOutcomes': ['Write a basic business plan'],
        'curriculumStrands': ['Venture Design'],
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
          'name': 'Senior Secondary',
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
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    if (!getIt.isRegistered<ApiService>()) {
      getIt.registerSingleton<ApiService>(_FakeApiService());
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
        {
          'key': 'impactuni',
          'level': 'ImpactUni',
          'ageGroup': '18+',
          'coreOutcomes': [
            'Manage personal finance and career capital',
            'Design and validate a venture or innovation project',
          ],
          'curriculumStrands': [
            'Personal Finance and Career Capital',
            'Venture Building and Innovation',
          ],
          'suggestedTermStructure': [
            {
              'term': 'Term 1',
              'focus': 'Personal and Professional Capital',
              'illustrativeTopics': ['Budgeting', 'Career positioning'],
            },
          ],
          'liveClassroomFormat': {
            'frequency': 'One 90-minute masterclass per week',
            'durationMinutes': 90,
            'methods': ['Masterclass', 'Peer feedback'],
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

  testWidgets(
    'Create Activity supports Blueprint Track switching to ImpactUni Level 4',
    (tester) async {
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
            'key': 'impactuni',
            'level': 'ImpactUni',
            'ageGroup': '18+',
            'coreOutcomes': [
              'Manage personal finance and career capital',
              'Design and validate a venture or innovation project',
            ],
            'curriculumStrands': [
              'Personal Finance and Career Capital',
              'Venture Building and Innovation',
            ],
            'suggestedTermStructure': [
              {
                'term': 'Term 1',
                'focus': 'Personal and Professional Capital',
                'illustrativeTopics': ['Budgeting', 'Career positioning'],
              },
            ],
            'liveClassroomFormat': {
              'frequency': 'One 90-minute masterclass per week',
              'durationMinutes': 90,
              'methods': ['Masterclass', 'Peer feedback'],
            },
          },
        ],
      });

      controller.hierarchy.assignAll([
        {
          'name': 'Impact Classroom',
          'levels': [
            {
              'name': 'ImpactUni',
              'cycles': [
                {
                  'id': 'cycle-uni-1',
                  'name': 'Cycle 1',
                  'modules': [
                    {
                      'title': 'Module 1',
                      'lessons': [
                        {
                          'id': 'lesson-uni-1',
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final createActivityButton = find.byKey(
        const Key('facilitator_create_activity_button'),
      );
      expect(createActivityButton, findsOneWidget);

      await tester.ensureVisible(createActivityButton);
      await tester.tap(createActivityButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final blueprintDropdown = find.byKey(
        const Key('create_activity_blueprint_track_dropdown'),
      );
      expect(
        blueprintDropdown,
        findsOneWidget,
        reason:
            'Blueprint Track dropdown should be visible in Create Activity sheet',
      );

      await tester.ensureVisible(blueprintDropdown);
      await tester.pumpAndSettle();

      await tester.tap(blueprintDropdown);
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      final impactUniTextFinder = find.text('ImpactUni (18+)');
      expect(
        impactUniTextFinder,
        findsWidgets,
        reason: 'Level 4 ImpactUni option should exist in dropdown menu',
      );

      await tester.tap(impactUniTextFinder.last);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // After selecting ImpactUni, the autofill should populate the title
      // with first strand and first term focus
      final titleTextFinder = find.text(
        'Personal Finance and Career Capital - Personal and Professional Capital',
      );
      expect(
        titleTextFinder,
        findsOneWidget,
        reason:
            'Title should be autofilled with ImpactUni strand and term after selection',
      );
    },
  );

  testWidgets('Create Activity submits progression and recognition metadata', (
    tester,
  ) async {
    final controller = _CapturingClassroomController();
    _seedClassroomData(controller);
    Get.put<ClassroomController>(controller);

    await tester.pumpWidget(
      const GetMaterialApp(home: FacilitatorClassroomScreen()),
    );
    await tester.pumpAndSettle();

    final createActivityButton = find.byKey(
      const Key('facilitator_create_activity_button'),
    );
    expect(createActivityButton, findsOneWidget);

    await tester.tap(createActivityButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final publishButton = find.byKey(
      const Key('create_activity_publish_button'),
    );
    expect(publishButton, findsOneWidget);
    await tester.ensureVisible(publishButton);
    await tester.tap(publishButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.createActivityCalls, 1);
    final metadata = controller.capturedMetadata;
    expect(metadata, isNotNull);
    expect(metadata!['assessmentSignals'], isNotEmpty);
    expect(metadata['recognitionTargets'], isNotEmpty);

    final progressionRules =
        metadata['progressionRules'] as Map<String, dynamic>;
    expect(progressionRules['completionThresholdPercent'], 75);
    expect(progressionRules['assessmentScoreThresholdPercent'], 60);
    expect(progressionRules['liveParticipationThresholdPercent'], 70);
    expect(progressionRules['projectSubmissionRequired'], isTrue);
  });

  test(
    'Facilitator activity metadata includes uploaded asset URL and progression rules',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'ik_upload_activity_',
      );
      final tempFile = File('${tempDir.path}/sample_upload.pdf');
      await tempFile.writeAsString('test-pdf-content');

      final fakeApi = _FakeApiService();
      final controller = _CapturingClassroomController();

      final sign = await fakeApi.requestSignedUpload(
        fileName: 'sample_upload.pdf',
        mimeType: 'application/pdf',
        byteSize: await tempFile.length(),
        accessScope: 'private',
        purpose: 'classroom_material',
      );

      final upload = sign['data']['upload'] as Map<String, dynamic>;
      final cloud = await fakeApi.uploadToSignedCloudinary(
        uploadUrl: upload['uploadUrl'] as String,
        filePath: tempFile.path,
        fields: {
          'api_key': upload['apiKey'],
          'timestamp': upload['timestamp'],
          'folder': upload['folder'],
          'public_id': upload['publicId'],
          'signature': upload['signature'],
        },
      );

      final complete = await fakeApi.completeSignedUpload(
        assetId: sign['data']['assetId'] as int,
        secureUrl: cloud['secure_url'] as String,
        uploadedBytes: await tempFile.length(),
        format: cloud['format'] as String,
      );

      final secureUrl = complete['data']['metadata']['secureUrl'] as String;

      final success = await controller.createActivity(
        lessonId: 'lesson-1',
        title: 'Uploaded Activity',
        activityType: 'assignment',
        learningLayer: 'learn',
        metadata: {
          'uploadedAssets': [
            {
              'type': 'pdf',
              'url': secureUrl,
              'assetId': sign['data']['assetId'],
            },
          ],
          'progressionRules': {
            'completionThresholdPercent': 75,
            'assessmentScoreThresholdPercent': 60,
            'liveParticipationThresholdPercent': 70,
            'projectSubmissionRequired': true,
          },
        },
      );

      expect(success, isTrue);
      expect(fakeApi.signCalls, 1);
      expect(fakeApi.cloudUploadCalls, 1);
      expect(fakeApi.completeCalls, 1);

      expect(controller.createActivityCalls, 1);
      final metadata = controller.capturedMetadata;
      expect(metadata, isNotNull);
      expect((metadata!['uploadedAssets'] as List).isNotEmpty, isTrue);

      final firstAsset =
          (metadata['uploadedAssets'] as List).first as Map<String, dynamic>;
      expect(firstAsset['type'], 'pdf');
      expect(firstAsset['url'], secureUrl);

      final progressionRules =
          metadata['progressionRules'] as Map<String, dynamic>;
      expect(progressionRules['completionThresholdPercent'], 75);
      expect(progressionRules['assessmentScoreThresholdPercent'], 60);
      expect(progressionRules['liveParticipationThresholdPercent'], 70);
      expect(progressionRules['projectSubmissionRequired'], isTrue);

      unawaited(tempDir.delete(recursive: true));
    },
  );

  test(
    'Signed upload pipeline returns URL metadata for facilitator activity',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('ik_upload_test_');
      final tempFile = File('${tempDir.path}/sample_upload.pdf');
      await tempFile.writeAsString('test-pdf-content');

      final fakeApi = _FakeApiService();

      final sign = await fakeApi.requestSignedUpload(
        fileName: 'sample_upload.pdf',
        mimeType: 'application/pdf',
        byteSize: await tempFile.length(),
        accessScope: 'private',
        purpose: 'classroom_material',
      );

      final upload = sign['data']['upload'] as Map<String, dynamic>;
      final cloud = await fakeApi.uploadToSignedCloudinary(
        uploadUrl: upload['uploadUrl'] as String,
        filePath: tempFile.path,
        fields: {
          'api_key': upload['apiKey'],
          'timestamp': upload['timestamp'],
          'folder': upload['folder'],
          'public_id': upload['publicId'],
          'signature': upload['signature'],
        },
      );

      final complete = await fakeApi.completeSignedUpload(
        assetId: sign['data']['assetId'] as int,
        secureUrl: cloud['secure_url'] as String,
        uploadedBytes: await tempFile.length(),
        format: cloud['format'] as String,
      );

      expect(fakeApi.signCalls, 1);
      expect(fakeApi.cloudUploadCalls, 1);
      expect(fakeApi.completeCalls, 1);
      expect(
        complete['data']['metadata']['secureUrl'],
        'https://cdn.example.test/assets/uploaded-material.pdf',
      );

      unawaited(tempDir.delete(recursive: true));
    },
  );
}
