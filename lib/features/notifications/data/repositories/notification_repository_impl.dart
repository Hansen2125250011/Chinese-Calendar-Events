import 'package:chinese_calendar/core/services/notification_service.dart';
import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/features/notifications/domain/entities/notification_settings.dart';
import 'package:chinese_calendar/features/notifications/domain/repositories/notification_repository.dart';
import 'package:chinese_calendar/features/calendar/domain/repositories/lunar_repository.dart';
import 'dart:developer' as dev;

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _service;
  final LunarRepository _lunarRepository;

  NotificationRepositoryImpl(this._service, this._lunarRepository);

  @override
  Future<void> scheduleEventNotification(
      TraditionalEvent event, NotificationSettings settings) async {
    final int id = _generateNotificationId(event.id);
    final now = DateTime.now();

    // Parse reminder time "HH:mm"
    int hour = 9;
    int minute = 0;
    try {
      final parts = settings.reminderTime.split(':');
      if (parts.length == 2) {
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }
    } catch (_) {}

    // Schedule for current year and next 2 years
    for (int i = 0; i < 3; i++) {
      final int checkYear = now.year + i;
      DateTime? solarDate;
      try {
        solarDate = await _lunarRepository.getSolarDate(
          year: checkYear,
          month: event.lunarMonth,
          day: event.lunarDay,
        );
      } catch (_) {
        continue;
      }

      final reminderDate =
          solarDate.subtract(Duration(days: settings.daysBefore));
      final scheduledTime = DateTime(reminderDate.year, reminderDate.month,
          reminderDate.day, hour, minute);

      dev.log(
          'NotificationRepository: Traditional Event "${event.id}" checkYear $checkYear calculated $scheduledTime',
          name: 'NotificationRepository');

      if (scheduledTime.isAfter(now)) {
        dev.log(
            'NotificationRepository: Scheduling Traditional Event "${event.id}" for $scheduledTime (ID: $id)',
            name: 'NotificationRepository');
        await _service.scheduleNotification(
          id: id,
          title: event.localizedNames['en'] ?? event.name,
          body: event.localizedDescriptions['en'] ?? 'Traditional Festival',
          scheduledDate: scheduledTime,
        );
        break; // Only schedule the next upcoming one
      } else if (i == 0 &&
          scheduledTime.isAfter(now.subtract(const Duration(days: 1)))) {
        // Fallback for today if just missed (like custom events)
        final fallbackTime = now.add(const Duration(minutes: 1));
        dev.log(
            'NotificationRepository: Traditional Event "${event.id}" was earlier today. Scheduling fallback: $fallbackTime',
            name: 'NotificationRepository');
        await _service.scheduleNotification(
          id: id,
          title: event.localizedNames['en'] ?? event.name,
          body: 'Upcoming today: ${event.localizedNames['en'] ?? event.name}',
          scheduledDate: fallbackTime,
        );
        break;
      } else {
        dev.log(
            'NotificationRepository: Traditional Event "${event.id}" in past ($scheduledTime). Checking next year.',
            name: 'NotificationRepository');
      }
    }
  }

  Future<void> scheduleTraditionalEvents(List<TraditionalEvent> events,
      bool enable, NotificationSettings settings) async {
    if (!enable) {
      final List<Future<void>> cancelFutures = events
          .map((event) =>
              _service.cancelNotification(_generateNotificationId(event.id)))
          .toList();
      await Future.wait(cancelFutures);
      return;
    }

    dev.log(
        'NotificationRepository: Syncing ${events.length} traditional events',
        name: 'NotificationRepository');

    // Only schedule enabled events in parallel
    final enabledEvents = events.where((e) => e.notificationsEnabled).toList();
    final List<Future<void>> scheduleFutures = enabledEvents
        .map((event) => scheduleEventNotification(event, settings))
        .toList();

    await Future.wait(scheduleFutures);
  }

  int _generateNotificationId(String key) {
    // Simple FNV-1a style hash to reduce collisions compared to hashCode.abs()
    var hash = 2166136261;
    for (var i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash *= 16777619;
      // Keep it as 32-bit signed int for notification ID compatibility
      hash &= 0x7FFFFFFF;
    }
    return hash;
  }

  @override
  Future<void> scheduleCustomEvent(
      int id,
      String name,
      bool isLunar,
      int month,
      int day,
      int? year,
      bool isLeap,
      int daysBefore,
      int hour,
      int minute) async {
    final now = DateTime.now();
    DateTime? nextDate;

    if (year != null) {
      // One-time event
      if (isLunar) {
        nextDate = await _lunarRepository.getSolarDate(
            year: year, month: month, day: day, isLeapMonth: isLeap);
      } else {
        nextDate = DateTime(year, month, day);
      }

      final reminderDate = nextDate.subtract(Duration(days: daysBefore));
      final scheduledTime = DateTime(reminderDate.year, reminderDate.month,
          reminderDate.day, hour, minute);

      final int notificationId = 1000000 + id; // Offset for custom events
      dev.log(
          'NotificationRepository: Custom Event "$name" (One-time) calculated $scheduledTime');

      if (scheduledTime.isAfter(now)) {
        dev.log(
            'NotificationRepository: Scheduling Custom Event "$name" for $scheduledTime (ID: $notificationId)');
        await _service.scheduleNotification(
          id: notificationId,
          title: 'Upcoming Event: $name',
          body: 'Your event "$name" is coming up in $daysBefore days!',
          scheduledDate: scheduledTime,
        );
      } else if (scheduledTime.isAfter(now.subtract(const Duration(days: 1)))) {
        // SPECIAL CASE: If scheduled time was EARLIER today, schedule for 1 minute from now
        // so the user gets notified for their newly created event.
        final fallbackTime = now.add(const Duration(minutes: 1));
        dev.log(
            'NotificationRepository: Custom Event "$name" was earlier today ($scheduledTime). Scheduling for fallback: $fallbackTime');
        await _service.scheduleNotification(
          id: notificationId,
          title: 'Upcoming Event (Today): $name',
          body:
              'Your event "$name" is coming up! (Reminder was set for earlier today)',
          scheduledDate: fallbackTime,
        );
      } else {
        dev.log(
            'NotificationRepository: Custom Event "$name" in past ($scheduledTime). Not scheduling.');
      }
    } else {
      // Annual event
      for (int i = 0; i < 3; i++) {
        final checkYear = now.year + i;
        DateTime? candidateDate;

        if (isLunar) {
          try {
            candidateDate = await _lunarRepository.getSolarDate(
                year: checkYear, month: month, day: day, isLeapMonth: isLeap);
          } catch (_) {
            continue;
          }
        } else {
          if (month == 2 && day == 29 && !(_isLeapYear(checkYear))) {
            candidateDate = DateTime(checkYear, 3, 1);
          } else {
            candidateDate = DateTime(checkYear, month, day);
          }
        }

        final reminderDate = candidateDate.subtract(Duration(days: daysBefore));
        final scheduledTime = DateTime(reminderDate.year, reminderDate.month,
            reminderDate.day, hour, minute);

        final int notificationId = 1000000 + id; // Offset for custom events
        dev.log(
            'NotificationRepository: Custom Event "$name" (Annual) checkYear $checkYear calculated $scheduledTime');

        if (scheduledTime.isAfter(now)) {
          dev.log(
              'NotificationRepository: Scheduling Custom Event "$name" for $scheduledTime (ID: $notificationId)');
          await _service.scheduleNotification(
            id: notificationId,
            title: 'Upcoming Event: $name',
            body: 'Your event "$name" is coming up in $daysBefore days!',
            scheduledDate: scheduledTime,
          );
          break;
        } else if (i == 0 &&
            scheduledTime.isAfter(now.subtract(const Duration(days: 1)))) {
          // SPECIAL CASE for current year: if reminder was for earlier today, fire soon.
          final fallbackTime = now.add(const Duration(minutes: 1));
          dev.log(
              'NotificationRepository: Custom Event "$name" annual reminder was earlier today. Scheduling fallback: $fallbackTime');
          await _service.scheduleNotification(
            id: notificationId,
            title: 'Upcoming Event (Today): $name',
            body:
                'Your event "$name" is coming up! (Reminder was set for earlier today)',
            scheduledDate: fallbackTime,
          );
          break; // Stop after scheduling for this year
        } else {
          dev.log(
              'NotificationRepository: Custom Event "$name" checkYear $checkYear is past ($scheduledTime). Checking next year.');
        }
      }
    }
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  @override
  Future<void> cancelEventNotification(String eventId) async {
    final int id = _generateNotificationId(eventId);
    dev.log(
        'NotificationRepository: Canceling notification for event "$eventId" (ID: $id)',
        name: 'NotificationRepository');
    await _service.cancelNotification(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _service.cancelAll();
  }

  @override
  Future<bool> requestPermissions() async {
    final result = await _service.requestPermissions();
    return result ?? false;
  }

  @override
  Future<NotificationSettings> getSettings() async {
    // Fetch from SharedPreferences or Drift
    return const NotificationSettings();
  }

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    // Save to DB
  }
}
