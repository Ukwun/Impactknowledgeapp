import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../services/api/api_service.dart';
import '../config/service_locator.dart';

final Logger _logger = Logger();

class EventController extends GetxController {
  final apiService = getIt<ApiService>();

  // Observable states
  final events = <Map<String, dynamic>>[].obs;
  final registeredEvents = <Map<String, dynamic>>[].obs;
  final upcomingEvents = <Map<String, dynamic>>[].obs;
  final currentEvent = Rx<Map<String, dynamic>?>(null);
  final isLoading = false.obs;
  final error = RxString('');

  Map<String, dynamic> _normalizeEvent(Map<String, dynamic> raw) {
    final startDate = raw['startDate'] ?? raw['start_date'] ?? raw['date'];
    final eventType = raw['eventType'] ?? raw['event_type'] ?? raw['type'];
    return {
      ...raw,
      'id': (raw['id'] ?? '').toString(),
      'date': startDate,
      'type': eventType,
      'registeredCount':
          raw['registeredCount'] ?? raw['registrations_count'] ?? 0,
    };
  }

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  /// Load all available events
  Future<void> loadEvents({Map<String, dynamic>? filters}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getEvents();
      if (response is List) {
        events.value = List<Map<String, dynamic>>.from(
          response,
        ).map(_normalizeEvent).toList();
      } else if (response is Map && response['success'] == true) {
        events.value = List<Map<String, dynamic>>.from(
          response['data'] as List,
        ).map(_normalizeEvent).toList();
      }

      // Separate upcoming events
      _updateUpcomingEvents();
    } catch (e) {
      error.value = 'Failed to load events: ${e.toString()}';
      _logger.e('Error loading events', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load events registered by current user
  Future<void> loadRegisteredEvents() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getRegisteredEvents();
      if (response is List) {
        registeredEvents.value = List<Map<String, dynamic>>.from(
          response,
        ).map(_normalizeEvent).toList();
      } else if (response is Map && response['success'] == true) {
        registeredEvents.value = List<Map<String, dynamic>>.from(
          response['data'] as List,
        ).map(_normalizeEvent).toList();
      }
    } catch (e) {
      error.value = 'Failed to load registered events: ${e.toString()}';
      _logger.e('Error loading registered events', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get upcoming events only
  Future<void> getUpcomingEvents() async {
    try {
      error.value = '';

      final response = await apiService.getUpcomingEvents();
      if (response is List) {
        upcomingEvents.value = List<Map<String, dynamic>>.from(
          response,
        ).map(_normalizeEvent).toList();
      } else if (response is Map && response['success'] == true) {
        upcomingEvents.value = List<Map<String, dynamic>>.from(
          response['data'] as List,
        ).map(_normalizeEvent).toList();
      }
    } catch (e) {
      error.value = 'Failed to load upcoming events: ${e.toString()}';
      _logger.e('Error loading upcoming events', error: e);
    }
  }

  /// Get event detail
  Future<void> loadEventDetail(String eventId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.getEventDetail(eventId);
      currentEvent.value = response is Map
          ? _normalizeEvent(Map<String, dynamic>.from(response))
          : <String, dynamic>{};
    } catch (e) {
      error.value = 'Failed to load event: ${e.toString()}';
      _logger.e('Error loading event', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Get event by ID from local list
  Map<String, dynamic>? getEventById(String eventId) {
    try {
      return events.firstWhereOrNull((e) => e['id'] == eventId);
    } catch (e) {
      _logger.e('Error getting event', error: e);
      return null;
    }
  }

  /// Register for an event
  Future<bool> registerEvent(String eventId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.registerEvent(eventId);

      if (response is Map && response['success'] == true) {
        // Update local event to show registered
        final index = events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          events[index]['isRegistered'] = true;
          events[index]['registeredCount'] =
              (events[index]['registeredCount'] ?? 0) + 1;
        }

        // Add to registered events
        final event = getEventById(eventId);
        if (event != null) {
          registeredEvents.add(event);
        }

        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to register: ${e.toString()}';
      _logger.e('Error registering for event', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Unregister from an event
  Future<bool> unregisterEvent(String eventId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await apiService.unregisterEvent(eventId);

      if (response is Map && response['success'] == true) {
        // Update local event to show unregistered
        final index = events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          events[index]['isRegistered'] = false;
          events[index]['registeredCount'] =
              ((events[index]['registeredCount'] ?? 1) - 1)
                  .clamp(0, double.infinity)
                  .toInt();
        }

        // Remove from registered events
        registeredEvents.removeWhere((e) => e['id'] == eventId);

        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to unregister: ${e.toString()}';
      _logger.e('Error unregistering from event', error: e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get event attendees
  Future<List<Map<String, dynamic>>?> getEventAttendees(String eventId) async {
    try {
      error.value = '';

      final response = await apiService.getEventAttendees(eventId);
      if (response != null) {
        return List<Map<String, dynamic>>.from(
          response.cast<Map<String, dynamic>>(),
        );
      }
      return null;
    } catch (e) {
      error.value = 'Failed to load attendees: ${e.toString()}';
      _logger.e('Error loading event attendees', error: e);
    }
    return null;
  }

  /// Get event analytics
  Future<Map<String, dynamic>?> getEventAnalytics(String eventId) async {
    try {
      error.value = '';

      final response = await apiService.getEventAnalytics(eventId);
      return response is Map ? response : <String, dynamic>{};
    } catch (e) {
      error.value = 'Failed to load analytics: ${e.toString()}';
      _logger.e('Error loading event analytics', error: e);
      return null;
    }
  }

  Future<bool> createEvent(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await apiService.createEvent(data);
      if (response?['success'] == true) {
        await loadEvents();
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to create event: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await apiService.updateEvent(eventId, data);
      if (response?['success'] == true) {
        await loadEvents();
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to update event: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await apiService.deleteEvent(eventId);
      if (response?['success'] == true) {
        events.removeWhere((e) => e['id'] == eventId);
        return true;
      }
      return false;
    } catch (e) {
      error.value = 'Failed to delete event: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Search events by title or description
  void searchEvents(String query) {
    if (query.isEmpty) {
      // Reload all events if query is cleared
      loadEvents();
      return;
    }

    final filtered = events
        .where(
          (e) =>
              (e['title']?.toString() ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              (e['description']?.toString() ?? '').toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();

    events.value = filtered;
  }

  /// Filter events by type
  void filterByType(String type) {
    if (type == 'all') {
      loadEvents();
      return;
    }

    final filtered = events
        .where(
          (e) =>
              (e['type']?.toString() ?? '').toLowerCase() == type.toLowerCase(),
        )
        .toList();

    events.value = filtered;
  }

  /// Sort events by date
  void sortByDate({bool ascending = true}) {
    final sorted = [...events];
    sorted.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date'] ?? '');
        final dateB = DateTime.parse(b['date'] ?? '');
        return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    events.value = sorted;
  }

  /// Helper to identify upcoming vs past events
  void _updateUpcomingEvents() {
    final now = DateTime.now();
    upcomingEvents.value = events.where((e) {
      try {
        final eventDate = DateTime.parse(e['date'] ?? '');
        return eventDate.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  void onClose() {
    events.clear();
    registeredEvents.clear();
    upcomingEvents.clear();
    super.onClose();
  }
}
