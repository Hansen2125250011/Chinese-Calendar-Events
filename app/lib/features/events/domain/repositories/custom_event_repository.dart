import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';

abstract class CustomEventRepository {
  Future<List<CustomEvent>> getAllEvents();
  Future<int> addEvent(CustomEvent event);
  Future<void> updateEvent(CustomEvent event);
  Future<void> deleteEvent(int id);
}
