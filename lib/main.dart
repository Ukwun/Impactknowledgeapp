import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'config/app_bindings.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'config/service_locator.dart';
import 'services/notification_service.dart';
import 'services/startup_diagnostics.dart';

final Logger _logger = Logger();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _logger.i('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupReport = StartupDiagnostics.validateRoleFlows(AppPages.pages);
  if (!startupReport.isValid) {
    _logger.w(
      'Startup diagnostics detected missing role routes: ${startupReport.missingRoutes.join(', ')}',
    );
  }

  // Initialize Firebase first
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i('Firebase initialized successfully');
    } else {
      Firebase.app();
      _logger.i('Firebase already initialized, reusing default app');
    }

    // Setup Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught async errors that aren't already handled by Flutter to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      _logger.e(
        'Uncaught async error during runtime',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    _logger.i('Firebase Crashlytics initialized successfully');

    // Initialize Firebase Analytics
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    _logger.i('Firebase Analytics initialized successfully');
  } catch (e, stack) {
    _logger.e('Firebase initialization error', error: e, stackTrace: stack);
  }

  try {
    setupServiceLocator();
    _logger.i('Service locator initialized successfully');

    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    _logger.i('Notification service initialized successfully');
  } catch (e, stack) {
    _logger.e('Service initialization error', error: e, stackTrace: stack);
    rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.darkTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
