import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../config/service_locator.dart';
import 'api/api_service.dart';

/// Firebase Cloud Messaging & Push Notifications Service
/// Handles FCM token management, message handling, and local notifications
class NotificationService {
  static final _instance = NotificationService._internal();
  static final _logger = Logger();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = getIt<ApiService>();

  String? _deviceToken;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize Push Notifications
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        _logger.i('✅ Notification service already initialized');
        return true;
      }

      // Request user permission for notifications
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        provisional: false,
        sound: true,
      );

      _logger.i(
        'User notification permission: ${settings.authorizationStatus}',
      );

      // Get FCM token
      _deviceToken = await _fcm.getToken();
      _logger.i('📱 FCM Token: $_deviceToken');
      if (_deviceToken != null && _deviceToken!.isNotEmpty) {
        await _apiService.registerDeviceToken(_deviceToken!);
      }

      // Keep backend token in sync when Firebase rotates it.
      _fcm.onTokenRefresh.listen((token) async {
        _deviceToken = token;
        await _apiService.registerDeviceToken(token);
        _logger.i('🔄 Registered refreshed FCM token');
      });

      // Setup message handlers
      await _setupMessageHandlers();

      // Initialize local notifications
      await _setupLocalNotifications();

      _isInitialized = true;
      _logger.i('✅ Notification service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Notification service initialization error: $e');
      return false;
    }
  }

  /// Setup Firebase Messaging Handlers
  Future<void> _setupMessageHandlers() async {
    // Handle message when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle terminated state (app was closed when message arrived)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }

    _logger.i('✅ Firebase messaging handlers configured');
  }

  /// Handle Foreground Messages (App Open)
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('📨 Foreground message received: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      payload: message.data,
    );

    // Optional: Handle in-app banner or dialog
    _showInAppNotification(message);
  }

  /// Handle Background Message Tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    _logger.i('📨 Background message tap: ${message.notification?.title}');

    // Handle deep link or navigate to specific page
    final action = message.data['action'];
    final resourceId = message.data['resource_id'];

    _handleNotificationAction(action, resourceId);
  }

  /// Handle notification actions
  void _handleNotificationAction(String? action, String? resourceId) {
    switch (action) {
      case 'achievement_unlock':
        Get.toNamed('/achievements', arguments: {'highlight': resourceId});
        break;
      case 'course_update':
        Get.toNamed('/courses', arguments: {'courseId': resourceId});
        break;
      case 'message':
        Get.toNamed('/messages', arguments: {'messageId': resourceId});
        break;
      case 'event':
        Get.toNamed('/events', arguments: {'eventId': resourceId});
        break;
      default:
        _logger.i('No action defined for: $action');
    }
  }

  /// Setup Local Notifications
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.i('Local notification tapped: ${response.payload}');
        // Handle notification tap
        if (response.payload != null) {
          // Parse payload and handle action
        }
      },
    );

    _logger.i('✅ Local notifications initialized');
  }

  /// Show Local Notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'impactknowledge_channel',
            'ImpactKnowledge Notifications',
            channelDescription:
                'Notifications for achievements, messages, and updates',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecond,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload.toString(),
      );

      _logger.i('✅ Local notification shown: $title');
    } catch (e) {
      _logger.e('❌ Error showing local notification: $e');
    }
  }

  /// Show In-App Notification (Banner)
  void _showInAppNotification(RemoteMessage message) {
    // You can implement a custom in-app notification/banner here
    // This could be a snackbar, overlay, or custom widget
    Get.snackbar(
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      colorText: Colors.white,
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 4),
    );
  }

  /// Send Test Notification (For Testing)
  void sendTestNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _showLocalNotification(title: title, body: body, payload: data ?? {});
    _logger.i('📨 Test notification sent: $title');
  }

  /// Get Device FCM Token
  String? getDeviceToken() => _deviceToken;

  /// Refresh FCM Token
  Future<String?> refreshToken() async {
    try {
      _deviceToken = await _fcm.getToken();
      _logger.i('🔄 FCM token refreshed: $_deviceToken');
      if (_deviceToken != null && _deviceToken!.isNotEmpty) {
        await _apiService.registerDeviceToken(_deviceToken!);
      }
      return _deviceToken;
    } catch (e) {
      _logger.e('❌ Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Subscribe to Topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      _logger.i('✅ Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      _logger.i('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to User-Specific Topics
  void subscribeToUserNotifications(String userId) {
    subscribeToTopic('user_$userId');
    subscribeToTopic('all_users');
    subscribeToTopic('announcements');
    _logger.i('📌 User subscribed to notification topics');
  }

  /// Unsubscribe from all user topics
  void unsubscribeFromUserNotifications(String userId) {
    unsubscribeFromTopic('user_$userId');
    unsubscribeFromTopic('all_users');
    unsubscribeFromTopic('announcements');
    _logger.i('📌 User unsubscribed from notification topics');
  }

  /// Notification Types Helper
  static Future<void> notifyAchievementUnlocked({
    required String userId,
    required String achievementName,
    required String achievementIcon,
  }) async {
    // This can be called from your achievement service
    // The backend would send an FCM message to user_$userId topic
  }

  static Future<void> notifyQuizScore({
    required String userId,
    required String quizName,
    required int score,
  }) async {
    // Backend sends notification about quiz completion
  }

  static Future<void> notifyMessage({
    required String userId,
    required String senderName,
    required String messagePreview,
  }) async {
    // Backend sends notification about new message
  }

  static Future<void> notifyEventReminder({
    required String userId,
    required String eventName,
    required String eventTime,
  }) async {
    // Backend sends event reminder notification
  }
}
