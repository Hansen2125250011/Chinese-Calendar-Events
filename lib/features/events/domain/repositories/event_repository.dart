import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';

abstract class EventRepository {
  Future<List<TraditionalEvent>> getEventsForMonth(
      int lunarYear, int lunarMonth);
  Future<void> saveUserReminder(String eventId, int daysBefore, String time);
  Future<List<TraditionalEvent>> getAllTraditionalEvents();
  Future<void> toggleTraditionalNotification(String eventId, bool enabled);
  Future<TraditionalEvent?> getEventById(String eventId);
  Future<void> initialize();
}
