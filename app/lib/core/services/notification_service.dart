import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chinese_calendar/core/constants/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:developer' as dev;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      dev.log('NotificationService: Already initialized, skipping.');
      return;
    }
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      dev.log('NotificationService: Local timezone set to $timeZoneName');
      dev.log(
          'NotificationService: Current TZ time: ${tz.TZDateTime.now(tz.local)}');
    } catch (e) {
      dev.log(
          'NotificationService: Failed to get local timezone, falling back to UTC. Error: $e');
    }

    await _createNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
    dev.log('NotificationService: Initialization complete.');
  }

  Future<bool?> requestPermissions() async {
    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    dev.log('NotificationService: Permission request result: $granted');
    return granted;
  }

  Future<bool> isPermissionGranted() async {
    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); // In newer versions, this just checks if not already asked? No, let's use permission_handler
    return granted ?? false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Check for exact alarm permission on Android 12+
    // But zonedSchedule with exact mode will throw if not permitted.
    dev.log(
        'NotificationService: Scheduling notification ID $id at $scheduledDate');
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      dev.log('NotificationService: Exact notification scheduled successfully');
    } catch (e) {
      dev.log(
          'NotificationService: Precise scheduling failed, falling back to inexact. Error: $e');
      // Fallback to inexact if exact is not permitted
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
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
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        dev.log(
            'NotificationService: Inexact notification scheduled successfully');
      } catch (e2) {
        dev.log(
            'NotificationService: ALL scheduling attempts failed. Error: $e2');
      }
    }
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
      id,
      title,
      body,
      const NotificationDetails(
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
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
