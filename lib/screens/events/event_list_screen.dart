import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_controller.dart';
import '../../providers/event_controller.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  late EventController _eventController;
  late AuthController _authController;
  String _filterType = 'all';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _eventController = Get.put(EventController());
    _authController = Get.find<AuthController>();
    _searchController = TextEditingController();
    _eventController.loadEvents();
  }

  bool get _canManageEvents {
    final role = _authController.currentUser.value?.role?.name;
    return role == 'admin' || role == 'instructor' || role == 'facilitator';
  }

  Future<void> _showCreateOrEditEventDialog({
    Map<String, dynamic>? existing,
  }) async {
    final titleController = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final typeController = TextEditingController(
      text: existing?['type']?.toString() ?? 'workshop',
    );
    final locationController = TextEditingController(
      text: existing?['location']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: (existing?['date']?.toString() ?? '').replaceFirst('Z', ''),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Create Event' : 'Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (workshop/webinar/meetup)',
                ),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Start Date (ISO)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final payload = {
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'eventType': typeController.text.trim(),
                'location': locationController.text.trim(),
                'startDate': dateController.text.trim(),
              };
              bool success;
              if (existing == null) {
                success = await _eventController.createEvent(payload);
              } else {
                success = await _eventController.updateEvent(
                  existing['id'].toString(),
                  payload,
                );
              }

              if (success && mounted) {
                Get.back();
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    var events = List<Map<String, dynamic>>.from(_eventController.events);

    if (_filterType != 'all') {
      events = events
          .where((e) => e['type']?.toLowerCase() == _filterType.toLowerCase())
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      events = events
          .where(
            (e) =>
                e['title']?.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    // Sort by date - upcoming first
    events.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '');
      final dateB = DateTime.tryParse(b['date'] ?? '');
      if (dateA == null || dateB == null) {
        return 0;
      }
      return dateA.compareTo(dateB);
    });

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: _canManageEvents
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrEditEventDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              cursorColor: AppTheme.primary500,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {}),
              decoration: AppTheme.darkInput(
                hint: 'Search events...',
                prefix: const Icon(Icons.search),
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Workshop',
                  isActive: _filterType == 'workshop',
                  onTap: () => setState(() => _filterType = 'workshop'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Webinar',
                  isActive: _filterType == 'webinar',
                  onTap: () => setState(() => _filterType = 'webinar'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Meetup',
                  isActive: _filterType == 'meetup',
                  onTap: () => setState(() => _filterType = 'meetup'),
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: Obx(() {
              if (_eventController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = _getFilteredEvents();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final event = filtered[index];
                  return _EventCard(
                    event: event,
                    canManage: _canManageEvents,
                    onEdit: () => _showCreateOrEditEventDialog(existing: event),
                    onDelete: () =>
                        _eventController.deleteEvent(event['id'].toString()),
                    onTap: () {
                      Get.toNamed('/event-detail', arguments: event['id']);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return Colors.blue;
      case 'webinar':
        return Colors.purple;
      case 'meetup':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = formatDate(event['date'] ?? '');
    final time = formatTime(event['date'] ?? '');
    final registeredCount = event['registeredCount'] ?? 0;
    final capacity = event['capacity'] ?? 100;
    final typeColor = _getTypeColor(event['type'] ?? 'other');
    final isRegistered = event['isRegistered'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.darkCard(radius: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor, width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.split(' ')[0],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                        Text(
                          date.split(' ')[1].substring(0, 3),
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              event['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['type'] ?? 'Event',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          if (canManage)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit();
                                } else if (value == 'delete') {
                                  onDelete();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Event'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Event'),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.people,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$registeredCount/$capacity',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isRegistered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppTheme.success500,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Registered',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.success500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary500 : AppTheme.dark400,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary500 : AppTheme.dark400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
