import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:impactknowledge_app/config/role_dashboard_resolver.dart';
import 'package:impactknowledge_app/config/service_locator.dart';
import 'package:impactknowledge_app/models/auth/user_model.dart';
import 'package:impactknowledge_app/screens/dashboard/roles/role_dashboard_switcher.dart';
import 'package:impactknowledge_app/services/api/api_service.dart';
import 'package:impactknowledge_app/services/dashboard/dashboard_cache_service.dart';
import 'package:impactknowledge_app/services/dashboard/dashboard_service.dart';

class _FakeApiService extends ApiService {
  @override
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final payload = <String, dynamic>{
      'summary': {
        'childrenLinked': 2,
        'avgProgress': 78,
        'attendanceRate': 92,
        'unreadMessages': 5,
        'activeClasses': 6,
        'pendingReviews': 18,
        'atRiskLearners': 4,
        'totalStudents': 1250,
        'totalFacilitators': 45,
        'completionRate': 72,
        'openAlerts': 3,
        'totalMentees': 14,
        'upcomingSessions': 7,
        'completedSessions': 52,
        'avgMenteeGrowth': 81,
        'connections': 238,
        'postsThisMonth': 12,
        'roundtables': 4,
        'profileReach': 1420,
        'ventureStage': 'Development',
        'teamMembers': 4,
        'mentorSessions': 9,
        'openOpportunities': 6,
        'totalUsers': 12480,
        'activeCourses': 173,
      },
    };

    if (fromJson != null) {
      return fromJson(payload);
    }

    return payload as T;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Provide an empty SharedPreferences store so DashboardCacheService
    // always sees a cache miss and falls through to _FakeApiService.
    SharedPreferences.setMockInitialValues({});
    getIt.allowReassignment = true;
    if (getIt.isRegistered<DashboardService>()) {
      getIt.unregister<DashboardService>();
    }
    getIt.registerSingleton<DashboardService>(
      DashboardService(
        apiService: _FakeApiService(),
        cacheService: DashboardCacheService(),
      ),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<DashboardService>()) {
      getIt.unregister<DashboardService>();
    }
  });

  group('RoleDashboardResolver', () {
    test('maps roles to expected dashboard experience', () {
      expect(
        RoleDashboardResolver.resolve(UserRole.parent),
        DashboardExperience.parent,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.facilitator),
        DashboardExperience.facilitator,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.schoolAdmin),
        DashboardExperience.schoolAdmin,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.mentor),
        DashboardExperience.mentor,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.circleMember),
        DashboardExperience.circleMember,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.uniMember),
        DashboardExperience.uniMember,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.admin),
        DashboardExperience.admin,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.student),
        DashboardExperience.learner,
      );
      expect(
        RoleDashboardResolver.resolve(UserRole.instructor),
        DashboardExperience.learner,
      );
    });
  });

  group('RoleDashboardSwitcher', () {
    Future<void> pumpRole(WidgetTester tester, UserRole role) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: RoleDashboardSwitcher(role: role, firstName: 'Alex'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lands parent user on Parent Dashboard', (tester) async {
      await pumpRole(tester, UserRole.parent);
      expect(find.text('Parent Dashboard'), findsOneWidget);
    });

    testWidgets('lands facilitator user on Facilitator Dashboard', (
      tester,
    ) async {
      await pumpRole(tester, UserRole.facilitator);
      expect(find.text('Facilitator Dashboard'), findsOneWidget);
    });

    testWidgets('lands school admin user on School Admin Dashboard', (
      tester,
    ) async {
      await pumpRole(tester, UserRole.schoolAdmin);
      expect(find.text('School Admin Dashboard'), findsOneWidget);
    });

    testWidgets('lands mentor user on Mentor Dashboard', (tester) async {
      await pumpRole(tester, UserRole.mentor);
      expect(find.text('Mentor Dashboard'), findsOneWidget);
    });

    testWidgets('lands circle member user on Circle Member Dashboard', (
      tester,
    ) async {
      await pumpRole(tester, UserRole.circleMember);
      expect(find.text('Circle Member Dashboard'), findsOneWidget);
    });

    testWidgets('lands uni member user on University Member Dashboard', (
      tester,
    ) async {
      await pumpRole(tester, UserRole.uniMember);
      expect(find.text('University Member Dashboard'), findsOneWidget);
    });

    testWidgets('lands admin user on Admin Dashboard', (tester) async {
      await pumpRole(tester, UserRole.admin);
      expect(find.text('Admin Dashboard'), findsOneWidget);
    });
  });
}
