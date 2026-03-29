import 'package:flutter/material.dart';
import 'dart:async';

class RoleDashboardScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String roleLabel;
  final String firstName;
  final List<Widget> children;

  const RoleDashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.firstName,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue[100],
                child: Text(
                  firstName.isEmpty ? 'U' : firstName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Chip(
            label: Text(roleLabel),
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.25)),
            labelStyle: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class RoleDashboardStats extends StatelessWidget {
  final List<(String, String, IconData)> stats;

  const RoleDashboardStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(stat.$3, color: Colors.blue[700]),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.$1,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      stat.$2,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RoleActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const RoleActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class LiveRoleDashboardData extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() loader;

  /// Optional stream of partial metric deltas pushed by the SSE service.
  ///
  /// When provided, each emitted [Map] is shallow-merged into the widget's
  /// data map and triggers an immediate rebuild — delivering real-time metric
  /// updates without waiting for the next periodic poll.  The periodic poll
  /// continues at [refreshInterval] as a fallback full-refresh.
  ///
  /// When [deltaStream] is supplied consider using a longer [refreshInterval]
  /// (e.g. `Duration(minutes: 5)`) since SSE handles the real-time path.
  final Stream<Map<String, dynamic>>? deltaStream;

  final Widget Function(
    BuildContext context,
    Map<String, dynamic> data,
    bool isRefreshing,
    DateTime? lastUpdated,
    Future<void> Function() reload,
  )
  builder;
  final Duration refreshInterval;

  const LiveRoleDashboardData({
    super.key,
    required this.loader,
    required this.builder,
    this.deltaStream,
    this.refreshInterval = const Duration(seconds: 30),
  });

  @override
  State<LiveRoleDashboardData> createState() => _LiveRoleDashboardDataState();
}

class _LiveRoleDashboardDataState extends State<LiveRoleDashboardData> {
  final Map<String, dynamic> _data = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _sseSub;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _timer = Timer.periodic(widget.refreshInterval, (_) => _load());
    _subscribeToDeltas();
  }

  void _subscribeToDeltas() {
    if (widget.deltaStream == null) return;
    _sseSub = widget.deltaStream!.listen(
      (delta) {
        if (!mounted) return;
        setState(() {
          _data.addAll(delta);
          _lastUpdated = DateTime.now();
        });
      },
      onError: (_) {}, // Reconnection is handled inside DashboardSseService.
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sseSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    if (!mounted) return;

    setState(() {
      if (initial && _data.isEmpty) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
      _error = null;
    });

    try {
      final response = await widget.loader();
      if (!mounted) return;
      setState(() {
        _data
          ..clear()
          ..addAll(response);
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Could not load live dashboard data.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.builder(context, _data, _isRefreshing, _lastUpdated, _load);
  }
}

class DashboardDataReader {
  static dynamic pick(Map<String, dynamic> data, List<List<String>> paths) {
    for (final path in paths) {
      dynamic current = data;
      bool found = true;

      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          found = false;
          break;
        }
      }

      if (found && current != null) {
        return current;
      }
    }

    return null;
  }

  static int intValue(
    Map<String, dynamic> data,
    List<List<String>> paths,
    int fallback,
  ) {
    final value = pick(data, paths);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String stringValue(
    Map<String, dynamic> data,
    List<List<String>> paths,
    String fallback,
  ) {
    final value = pick(data, paths);
    if (value is String && value.isNotEmpty) return value;
    if (value != null) return value.toString();
    return fallback;
  }
}
