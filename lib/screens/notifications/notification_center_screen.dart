import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/service_locator.dart';
import '../../services/api/api_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ApiService _apiService = getIt<ApiService>();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final response = await _apiService.getNotifications();
    final data = response['data'];
    setState(() {
      _notifications = (data is List)
          ? data
                .map<Map<String, dynamic>>((n) => Map<String, dynamic>.from(n))
                .toList()
          : [];
      _unreadCount = (response['unreadCount'] ?? 0) as int;
      _loading = false;
    });
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    await _apiService.markNotificationRead(notification['id'].toString());
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _apiService.markAllNotificationsRead();
    await _loadNotifications();
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    await _apiService.deleteNotification(notification['id'].toString());
    await _loadNotifications();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'course':
        return Icons.school_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark800,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.dark700,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  final isRead = n['is_read'] == true;
                  return Dismissible(
                    key: ValueKey('notification_${n['id']}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteNotification(n),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _markAsRead(n),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: AppTheme.darkCard(radius: 12).copyWith(
                          border: Border.all(
                            color: isRead
                                ? AppTheme.dark400
                                : AppTheme.primary500.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    (isRead
                                            ? AppTheme.textMuted
                                            : AppTheme.primary500)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForType((n['type'] ?? 'info').toString()),
                                color: isRead
                                    ? AppTheme.textMuted
                                    : AppTheme.primary500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (n['title'] ?? 'Notification')
                                              .toString(),
                                          style: TextStyle(
                                            color: AppTheme.textLight,
                                            fontWeight: isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primary500,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (n['message'] ?? '').toString(),
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
