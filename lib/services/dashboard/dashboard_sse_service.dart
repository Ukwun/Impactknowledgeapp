import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../config/app_config.dart';
import '../../config/role_dashboard_resolver.dart';
import '../../models/auth/user_model.dart';

/// Manages per-role Server-Sent Events (SSE) streams for real-time metric
/// deltas pushed from the backend.
///
/// **Backend contract** — the server should expose:
///   `GET /api/dashboard/stream?role=<webRoleKey>`
///   with `Content-Type: text/event-stream`.
///
/// Each `data:` line must carry a JSON object containing **only the changed**
/// metric fields (a delta). The receiving [LiveRoleDashboardData] widget
/// shallow-merges each delta into its cached data map and re-renders.
///
/// A full snapshot payload is equally valid — the merge is idempotent.
///
/// **Reconnection** — the service reconnects automatically with exponential
/// back-off capped at 60 s.  A `404` response permanently stops retrying
/// for that role to avoid log spam when the endpoint is not yet deployed.
///
/// **Lifecycle** — the SSE connection for a role is started when the first
/// listener subscribes via [streamFor] and torn down when the last listener
/// cancels.  Call [dispose] during app shutdown to close all connections.
class DashboardSseService {
  static const Duration _minReconnect = Duration(seconds: 2);
  static const Duration _maxReconnect = Duration(seconds: 60);

  final _storage = const FlutterSecureStorage();
  final _log = Logger();

  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<String, http.Client> _clients = {};
  final Map<String, bool> _active = {};

  /// Returns a broadcast [Stream] of delta payloads for [role].
  ///
  /// Multiple calls with the same role reuse the same underlying SSE
  /// connection and return the same broadcast stream.
  Stream<Map<String, dynamic>> streamFor(UserRole role) {
    final key = RoleDashboardResolver.toWebRoleKey(role);
    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _teardown(key),
    );
    _controllers[key] = controller;
    _active[key] = true;
    _connect(key, controller);
    return controller.stream;
  }

  // ─── internals ────────────────────────────────────────────────────────────

  /// Connects (and reconnects) to the SSE endpoint for [roleKey].
  void _connect(
    String roleKey,
    StreamController<Map<String, dynamic>> controller,
  ) async {
    var delay = _minReconnect;

    while ((_active[roleKey] ?? false) && !controller.isClosed) {
      final client = http.Client();
      _clients[roleKey] = client;

      try {
        final token = await _storage.read(key: AppConfig.tokenKey);
        final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/dashboard/stream?role=$roleKey',
        );

        final request = http.Request('GET', uri)
          ..headers['Accept'] = 'text/event-stream'
          ..headers['Cache-Control'] = 'no-cache'
          // Disable nginx/proxy response buffering so events arrive in real time.
          ..headers['X-Accel-Buffering'] = 'no';
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        final response = await client.send(request);

        if (response.statusCode == 200) {
          delay = _minReconnect; // reset back-off on a healthy open
          await _consumeStream(roleKey, response.stream, controller);
        } else if (response.statusCode == 404) {
          // Endpoint not yet deployed — stop retrying silently.
          _log.i(
            'SSE: /dashboard/stream?role=$roleKey returned 404 — disabling',
          );
          break;
        } else {
          _log.w('SSE: HTTP ${response.statusCode} for role $roleKey');
        }
      } catch (e) {
        if (!(_active[roleKey] ?? false)) break;
        _log.w(
          'SSE ($roleKey) error: $e — reconnecting in ${delay.inSeconds}s',
        );
      } finally {
        client.close();
        _clients.remove(roleKey);
      }

      if (!(_active[roleKey] ?? false) || controller.isClosed) break;

      await Future<void>.delayed(delay);
      // Exponential back-off: 2 → 4 → 8 → … → 60 s.
      delay = Duration(
        seconds: (delay.inSeconds * 2).clamp(
          _minReconnect.inSeconds,
          _maxReconnect.inSeconds,
        ),
      );
    }
  }

  /// Reads the SSE byte stream and emits parsed JSON delta objects.
  Future<void> _consumeStream(
    String roleKey,
    Stream<List<int>> raw,
    StreamController<Map<String, dynamic>> controller,
  ) async {
    var buffer = '';
    await for (final chunk in raw.transform(utf8.decoder)) {
      if (!(_active[roleKey] ?? false) || controller.isClosed) break;
      buffer += chunk;

      // Split on newlines, keeping any partial last line in the buffer.
      while (buffer.contains('\n')) {
        final idx = buffer.indexOf('\n');
        final line = buffer.substring(0, idx).trimRight();
        buffer = buffer.substring(idx + 1);

        if (line.startsWith('data: ') && line.length > 6) {
          try {
            final decoded = jsonDecode(line.substring(6));
            if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
              if (!controller.isClosed) controller.add(decoded);
            }
          } catch (_) {
            // Skip malformed data line — stream continues.
          }
        }
        // event:, id:, retry:, and comment lines are intentionally ignored.
      }
    }
  }

  /// Stops the SSE connection for [roleKey] and cleans up resources.
  void _teardown(String roleKey) {
    _active[roleKey] = false;
    _clients[roleKey]?.close();
    _clients.remove(roleKey);
    _controllers.remove(roleKey);
    _active.remove(roleKey);
  }

  /// Closes all active SSE connections and releases resources.
  ///
  /// Call this when the app is shutting down or the service is deregistered.
  void dispose() {
    for (final key in _active.keys.toList()) {
      _active[key] = false;
    }
    for (final client in _clients.values) {
      client.close();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _clients.clear();
    _active.clear();
  }
}
