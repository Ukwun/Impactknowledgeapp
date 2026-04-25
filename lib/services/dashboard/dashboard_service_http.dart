import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/role_dashboard_resolver.dart';
import '../../config/app_config.dart';
import '../../models/auth/user_model.dart';
import '../api/api_service.dart';
import 'dashboard_cache_service.dart';

class DashboardService {
  final ApiService apiService;
  final DashboardCacheService cacheService;

  DashboardService({required this.apiService, required this.cacheService});

  Future<Map<String, dynamic>> fetchForRole(UserRole role) {
    switch (RoleDashboardResolver.resolve(role)) {
      case DashboardExperience.parent:
        return fetchParentDashboard();
      case DashboardExperience.facilitator:
        return fetchFacilitatorDashboard();
      case DashboardExperience.instructor:
        return fetchFacilitatorDashboard();
      case DashboardExperience.schoolAdmin:
        return fetchSchoolAdminDashboard();
      case DashboardExperience.mentor:
        return fetchMentorDashboard();
      case DashboardExperience.circleMember:
        return fetchCircleMemberDashboard();
      case DashboardExperience.uniMember:
        return fetchUniMemberDashboard();
      case DashboardExperience.admin:
        return fetchAdminDashboard();
      case DashboardExperience.learner:
        return fetchLearnerDashboard();
    }
  }

  Future<Map<String, dynamic>> fetchLearnerDashboard() =>
      _withCache('learner', () => _getFromEndpoints(['api/dashboard/student']));

  Future<Map<String, dynamic>> fetchParentDashboard() =>
      _withCache('parent', () => _getFromEndpoints(['api/dashboard/parent']));

  Future<Map<String, dynamic>> fetchFacilitatorDashboard() => _withCache(
    'facilitator',
    () => _getFromEndpoints(['api/dashboard/facilitator']),
  );

  Future<Map<String, dynamic>> fetchSchoolAdminDashboard() => _withCache(
    'school_admin',
    () => _getFromEndpoints(['api/dashboard/school-admin']),
  );

  Future<Map<String, dynamic>> fetchMentorDashboard() =>
      _withCache('mentor', () => _getFromEndpoints(['api/dashboard/mentor']));

  Future<Map<String, dynamic>> fetchCircleMemberDashboard() => _withCache(
    'circle_member',
    () => _getFromEndpoints(['api/dashboard/circle-member']),
  );

  Future<Map<String, dynamic>> fetchUniMemberDashboard() => _withCache(
    'uni_member',
    () => _getFromEndpoints(['api/dashboard/uni-member']),
  );

  Future<Map<String, dynamic>> fetchAdminDashboard() =>
      _withCache('admin', () => _getFromEndpoints(['api/dashboard/admin']));

  Future<Map<String, dynamic>> _withCache(
    String roleKey,
    Future<Map<String, dynamic>> Function() fetcher,
  ) async {
    final cached = await cacheService.read(roleKey);
    if (cached != null) {
      if (!cached.isFresh) {
        _backgroundRefresh(roleKey, fetcher);
      }
      return cached.data;
    }
    final fresh = await fetcher();
    await cacheService.write(roleKey, fresh);
    return fresh;
  }

  void _backgroundRefresh(
    String roleKey,
    Future<Map<String, dynamic>> Function() fetcher,
  ) {
    fetcher()
        .then((fresh) => cacheService.write(roleKey, fresh))
        .catchError((_) {});
  }

  // DIRECT HTTP - NO DIO!
  Future<Map<String, dynamic>> _getFromEndpoints(List<String> endpoints) async {
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        // Get token from apiService
        final token = await apiService.getToken();

        // Build URL directly
        final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
            ? AppConfig.apiBaseUrl
            : '${AppConfig.apiBaseUrl}/';
        final url = Uri.parse('$baseUrl$endpoint');

        print('→ DASHBOARD REQUEST: GET $url');

        final response = await http
            .get(
              url,
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw Exception('Dashboard request timeout'),
            );

        print('← DASHBOARD RESPONSE: ${response.statusCode} $url');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return _normalizeResponse(data);
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('✗ DASHBOARD ERROR: $e');
        lastError = e;
      }
    }

    throw Exception(
      'Unable to load dashboard data from role endpoints: '
      '${lastError ?? 'unknown error'}',
    );
  }

  Map<String, dynamic> _normalizeResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }
}
