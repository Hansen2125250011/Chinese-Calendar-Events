import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';

part 'custom_event_providers.g.dart';

@riverpod
Future<List<CustomEvent>> customEvents(Ref ref) async {
  final repo = ref.watch(customEventRepositoryProvider);
  return repo.getAllEvents();
}

@riverpod
Future<List<CustomEvent>> customEventsForDate(
    Ref ref, DateTime gregorianDate, LunarDate lunarDate) async {
  final allEvents = await ref.watch(customEventsProvider.future);

  return allEvents.where((e) {
    if (e.isLunar) {
      return e.month == lunarDate.month &&
          e.day == lunarDate.day &&
          (e.year == null || e.year == lunarDate.year);
    } else {
      return e.month == gregorianDate.month &&
          e.day == gregorianDate.day &&
          (e.year == null || e.year == gregorianDate.year);
    }
  }).toList();
}
