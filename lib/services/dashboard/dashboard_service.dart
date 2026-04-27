import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/role_dashboard_resolver.dart';
import '../../config/app_config.dart';
import '../../models/auth/user_model.dart';
import '../api/api_service.dart';
import 'dashboard_cache_service.dart';

class DashboardService {
  final ApiService apiService;
  final DashboardCacheService cacheService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
    () => _getDashboardBundle(
      dashboardEndpoints: ['api/dashboard/facilitator'],
      includeInsights: true,
      includeRecommendations: true,
    ),
  );

  Future<Map<String, dynamic>> fetchSchoolAdminDashboard() => _withCache(
    'school_admin',
    () => _getDashboardBundle(
      dashboardEndpoints: ['api/dashboard/school-admin'],
      includeInsights: true,
      includeRecommendations: true,
    ),
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

  Future<Map<String, dynamic>> fetchAdminDashboard() => _withCache(
    'admin',
    () => _getDashboardBundle(
      dashboardEndpoints: ['api/dashboard/admin'],
      includeInsights: true,
      includeRecommendations: true,
    ),
  );

  Future<Map<String, dynamic>> _getDashboardBundle({
    required List<String> dashboardEndpoints,
    bool includeInsights = false,
    bool includeRecommendations = false,
  }) async {
    final base = await _getFromEndpoints(dashboardEndpoints);
    final merged = Map<String, dynamic>.from(base);
    final summary = Map<String, dynamic>.from(
      merged['summary'] is Map<String, dynamic> ? merged['summary'] : {},
    );

    if (includeInsights) {
      final insights = await _tryGetFromEndpoint(
        'api/analytics/cohort-insights?daysBack=30',
      );
      final insightsSummary = insights['summary'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(insights['summary'])
          : <String, dynamic>{};
      summary.addAll(insightsSummary);
      if (insights.isNotEmpty) {
        merged['analytics'] = insights;
      }
    }

    if (includeRecommendations) {
      final guidance = await _tryGetFromEndpoint(
        'api/analytics/recommendations/me',
      );
      final recommendations = guidance['recommendations'];
      final interventions = guidance['interventions'];
      if (recommendations is List) {
        merged['recommendations'] = recommendations;
      }
      if (interventions is List) {
        merged['interventions'] = interventions;
        summary['interventionQueue'] = interventions.length;
      }
      if (guidance['analytics'] is Map<String, dynamic>) {
        merged['analyticsProfile'] = guidance['analytics'];
      }
    }

    if (summary.isNotEmpty) {
      merged['summary'] = summary;
    }

    return merged;
  }

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

  // DIRECT HTTP INSTEAD OF DIO
  Future<Map<String, dynamic>> _getFromEndpoints(List<String> endpoints) async {
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        // Get token directly from secure storage
        final token = await _secureStorage.read(key: AppConfig.tokenKey);

        debugPrint(
          '🔑 DASHBOARD TOKEN: ${token != null ? '${token.substring(0, 50)}...' : 'NULL'}',
        );

        // Build proper URL
        final baseUrl = AppConfig.apiBaseUrl.endsWith('/')
            ? AppConfig.apiBaseUrl
            : '${AppConfig.apiBaseUrl}/';
        final url = Uri.parse('$baseUrl$endpoint');

        debugPrint('→ DASHBOARD: GET $url with Authorization header');

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
              onTimeout: () => throw Exception('Dashboard timeout'),
            );

        debugPrint('← DASHBOARD: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return _normalizeResponse(data);
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('✗ DASHBOARD ERROR: $e');
        lastError = e;
      }
    }

    throw Exception(
      'Unable to load dashboard: ${lastError ?? 'unknown error'}',
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

  Future<Map<String, dynamic>> _tryGetFromEndpoint(String endpoint) async {
    try {
      return await _getFromEndpoints([endpoint]);
    } catch (_) {
      return {};
    }
  }
}
