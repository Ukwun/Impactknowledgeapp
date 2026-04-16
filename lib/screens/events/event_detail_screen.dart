import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';
import '../../providers/event_controller.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventController _eventController;
  Map<String, dynamic>? _event;

  @override
  void initState() {
    super.initState();
    _eventController = Get.find<EventController>();
    _loadEventDetail();
  }

  Future<void> _loadEventDetail() async {
    _event = _eventController.getEventById(widget.eventId);
    setState(() {});
  }

  void _toggleRegistration() {
    if (_event!['isRegistered'] ?? false) {
      _eventController.unregisterEvent(widget.eventId);
      _event!['isRegistered'] = false;
    } else {
      _eventController.registerEvent(widget.eventId);
      _event!['isRegistered'] = true;
    }
    setState(() {});
    Get.snackbar(
      'Success',
      _event!['isRegistered'] ?? false
          ? 'Registered for event'
          : 'Unregistered from event',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final registeredCount = _event!['registeredCount'] ?? 0;
    final capacity = _event!['capacity'] ?? 100;
    final isFull = registeredCount >= capacity;
    final isRegistered = _event!['isRegistered'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image/header
            Container(
              height: 250,
              width: double.infinity,
              color: AppTheme.dark400,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_event!['imageUrl'] != null)
                    Image.network(_event!['imageUrl'], fit: BoxFit.cover)
                  else
                    Container(
                      color: AppTheme.dark400,
                      child: Center(
                        child: Icon(
                          Icons.event,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.darkGradient.colors.first,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Event info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _event!['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary500.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _event!['type'] ?? 'Event',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRegistered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppTheme.success500,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Registered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Event details grid
                  Container(
                    decoration: AppTheme.darkCard(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Date & Time',
                          value: _formatDateTime(_event!['date'] ?? ''),
                        ),
                        const Divider(color: AppTheme.dark400),
                        _DetailRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: _event!['location'] ?? 'TBD',
                        ),
                        const Divider(color: AppTheme.dark400),
                        _DetailRow(
                          icon: Icons.people,
                          label: 'Attendees',
                          value: '$registeredCount/$capacity',
                        ),
                        const Divider(color: AppTheme.dark400),
                        _DetailRow(
                          icon: Icons.person,
                          label: 'Organizer',
                          value: _event!['organizer'] ?? 'Unknown',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About This Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event!['fullDescription'] ??
                        _event!['description'] ??
                        'No description provided.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Topics/Tags
                  if (_event!['topics'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Topics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_event!['topics'] as List).map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.dark400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isFull && !isRegistered
                          ? null
                          : _toggleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered
                            ? AppTheme.danger500
                            : AppTheme.success500,
                        disabledBackgroundColor: Colors.grey[600],
                      ),
                      child: Text(
                        isFull && !isRegistered
                            ? 'Event is Full'
                            : isRegistered
                            ? 'Unregister'
                            : 'Register Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
