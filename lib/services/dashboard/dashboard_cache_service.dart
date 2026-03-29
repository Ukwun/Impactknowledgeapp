import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stale-while-revalidate (SWR) cache for role dashboard payloads.
///
/// Entries are stored in [SharedPreferences] as JSON with an embedded
/// timestamp.  A cached entry is "fresh" when its age is under
/// [freshnessTtl]; stale entries are still returned immediately so the UI
/// shows data right away, and the caller should kick off a background
/// network refresh to repopulate the cache.
///
/// The cache is intentionally tolerant of corrupted entries — a JSON decode
/// failure silently evicts the bad entry and returns null.
class DashboardCacheService {
  static const String _prefix = 'dashboard_cache__';

  /// Maximum age before a cache entry is considered stale.
  static const Duration freshnessTtl = Duration(minutes: 5);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Returns the cached [CachedDashboard] for [roleKey], or `null` when the
  /// cache holds nothing for that role.
  Future<CachedDashboard?> read(String roleKey) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_prefix$roleKey');
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(wrapper['data'] as Map);
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(
        wrapper['cachedAt'] as int,
      );
      final isFresh = DateTime.now().difference(cachedAt) < freshnessTtl;
      return CachedDashboard(data: data, cachedAt: cachedAt, isFresh: isFresh);
    } catch (_) {
      await evict(roleKey);
      return null;
    }
  }

  /// Persists [data] for [roleKey] with the current UTC timestamp.
  Future<void> write(String roleKey, Map<String, dynamic> data) async {
    final prefs = await _getPrefs();
    final payload = jsonEncode({
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    });
    await prefs.setString('$_prefix$roleKey', payload);
  }

  /// Removes the entry for [roleKey].
  Future<void> evict(String roleKey) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_prefix$roleKey');
  }

  /// Removes all dashboard cache entries (e.g. on sign-out).
  Future<void> evictAll() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

/// A single cached dashboard payload with freshness metadata.
class CachedDashboard {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  /// `true` when the entry is younger than [DashboardCacheService.freshnessTtl].
  final bool isFresh;

  const CachedDashboard({
    required this.data,
    required this.cachedAt,
    required this.isFresh,
  });
}
