import '../../config/role_dashboard_resolver.dart';
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

  Future<Map<String, dynamic>> fetchLearnerDashboard() => _withCache(
    'learner',
    () => _getFromEndpoints([
      '/progress',
      '/dashboard/student',
      '/dashboard/learner',
    ]),
  );

  Future<Map<String, dynamic>> fetchParentDashboard() => _withCache(
    'parent',
    () => _getFromEndpoints([
      '/parent/dashboard',
      '/dashboard/parent',
      '/parent',
    ]),
  );

  Future<Map<String, dynamic>> fetchFacilitatorDashboard() => _withCache(
    'facilitator',
    () => _getFromEndpoints([
      '/facilitator/dashboard',
      '/dashboard/facilitator',
      '/facilitator',
      '/progress',
    ]),
  );

  Future<Map<String, dynamic>> fetchSchoolAdminDashboard() => _withCache(
    'school_admin',
    () => _getFromEndpoints([
      '/school-admin/dashboard',
      '/dashboard/school-admin',
      '/school-admin',
    ]),
  );

  Future<Map<String, dynamic>> fetchMentorDashboard() => _withCache(
    'mentor',
    () => _getFromEndpoints(['/mentor/dashboard', '/mentor']),
  );

  Future<Map<String, dynamic>> fetchCircleMemberDashboard() => _withCache(
    'circle_member',
    () => _getFromEndpoints(['/circle-member/dashboard', '/circle-member']),
  );

  Future<Map<String, dynamic>> fetchUniMemberDashboard() => _withCache(
    'uni_member',
    () => _getFromEndpoints([
      '/uni-member/dashboard',
      '/dashboard/uni-member',
      '/university-member/dashboard',
      '/university-member',
    ]),
  );

  Future<Map<String, dynamic>> fetchAdminDashboard() => _withCache(
    'admin',
    () => _getFromEndpoints(['/admin/dashboard', '/dashboard/admin']),
  );

  // ─── Stale-while-revalidate ───────────────────────────────────────────────

  /// Returns cached data immediately (even if stale) and triggers a background
  /// refresh when the entry is older than [DashboardCacheService.freshnessTtl].
  /// If no cached entry exists the call blocks on a live network fetch.
  Future<Map<String, dynamic>> _withCache(
    String roleKey,
    Future<Map<String, dynamic>> Function() fetcher,
  ) async {
    final cached = await cacheService.read(roleKey);
    if (cached != null) {
      if (!cached.isFresh) {
        // Serve stale immediately; the SSE stream or periodic poll will bring
        // fresh data. Schedule a background network refresh to repopulate cache.
        _backgroundRefresh(roleKey, fetcher);
      }
      return cached.data;
    }
    // Cache miss: block on live fetch and prime the cache.
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

  Future<Map<String, dynamic>> _getFromEndpoints(List<String> endpoints) async {
    Object? lastError;

    for (final endpoint in endpoints) {
      try {
        final response = await apiService.get<dynamic>(endpoint);
        return _normalizeResponse(response);
      } catch (e) {
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

    if (response is Map) {
      final casted = Map<String, dynamic>.from(response);
      if (casted['data'] is Map) {
        return Map<String, dynamic>.from(casted['data'] as Map);
      }
      return casted;
    }

    return <String, dynamic>{'data': response};
  }
}
