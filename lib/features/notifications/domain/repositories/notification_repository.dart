import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/features/notifications/domain/entities/notification_settings.dart';

abstract class NotificationRepository {
  Future<void> scheduleEventNotification(
      TraditionalEvent event, NotificationSettings settings);
  Future<void> scheduleTraditionalEvents(List<TraditionalEvent> events,
      bool enable, NotificationSettings settings);
  Future<void> scheduleCustomEvent(int id, String name, bool isLunar, int month,
      int day, int? year, bool isLeap, int daysBefore, int hour, int minute);
  Future<void> cancelEventNotification(String eventId);
  Future<void> cancelAllNotifications();
  Future<bool> requestPermissions();
  Future<NotificationSettings> getSettings();
  Future<void> saveSettings(NotificationSettings settings);
  Future<void> syncAllNotifications();
}
