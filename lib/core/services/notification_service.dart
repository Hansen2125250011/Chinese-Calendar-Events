import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chinese_calendar/core/constants/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle notification tap in background
  debugPrint('NotificationService: Background notification tapped: ${notificationResponse.id}');
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('NotificationService: Already initialized, skipping.');
      return;
    }
    if (_initFuture != null) {
      // Another caller is initializing; await the same future to avoid races.
      await _initFuture;
      return;
    }

    _initFuture = _initInternal();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _initInternal() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local timezone set to $timeZoneName');
      debugPrint(
          'NotificationService: Current TZ time: ${tz.TZDateTime.now(tz.local)}');
      debugPrint(
          'NotificationService: Current TZ time: ${tz.TZDateTime.now(tz.local)}');
    } catch (e) {
      dev.log(
          'NotificationService: Failed to get local timezone, falling back to UTC. Error: $e');
      debugPrint(
          'NotificationService: Failed to get local timezone, falling back to UTC. Error: $e');
      // CRITICAL: Must initialize tz.local even on failure to avoid LateInitializationError
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    await _createNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('NotificationService: Notification tapped in foreground: ${response.id}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _isInitialized = true;
    debugPrint('NotificationService: Initialization complete.');
  }

  Future<bool?> requestPermissions() async {
    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    debugPrint('NotificationService: Permission request result: $granted');
    return granted;
  }

  Future<bool> isPermissionGranted() async {
    final androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      final bool? enabled = await androidImpl?.areNotificationsEnabled();
      if (enabled != null) return enabled;
    } catch (_) {}
    return false;
  }

  /// Checks if the app is allowed to schedule exact alarms (Android 12+).
  Future<bool> canScheduleExactAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    try {
      // For Android 14+ (SDK 34+), we need to check this specifically
      // Permission.scheduleExactAlarm is available in permission_handler 11+
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      debugPrint('NotificationService: Error checking exact alarm permission: $e');
      return true; // Fallback to assuming true if error
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('NotificationService: Skipping past date: $scheduledDate');
      return;
    }

    debugPrint(
        'NotificationService: Scheduling notification ID $id at $scheduledDate');
    
    // Determine schedule mode based on permissions
    final bool canExact = await canScheduleExactAlarms();
    final AndroidScheduleMode mode = canExact 
        ? AndroidScheduleMode.exactAllowWhileIdle 
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (!canExact) {
      debugPrint('NotificationService: Exact alarm permission not granted, using inexact mode for ID $id');
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: AppConstants.notificationChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: mode,
      );
      debugPrint('NotificationService: Notification scheduled successfully (mode: ${mode.name})');
    } catch (e) {
      debugPrint('NotificationService: Scheduling failed: $e');
    }
  }

  /// Debug helper: show an immediate notification and schedule another a few
  /// minutes later to test background delivery. Only active in debug mode.
  Future<void> scheduleDebugNotifications() async {
    if (!kDebugMode) return;
    await showInstantNotification(
      id: 999999,
      title: 'Debug Notification (Immediate)',
      body: 'This is an immediate debug notification',
    );

    final scheduled = DateTime.now().add(const Duration(minutes: 2));
    await scheduleNotification(
      id: 999998,
      title: 'Debug Notification (Scheduled)',
      body: 'This notification was scheduled 2 minutes earlier for testing',
      scheduledDate: scheduled,
    );
    debugPrint('NotificationService: Debug notifications scheduled.');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
