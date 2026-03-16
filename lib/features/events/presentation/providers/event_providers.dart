import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/core/di/providers.dart';
// content of lunar_date.dart has to be imported for the type, but let's just pass ints to avoid complex object as family key if possible?
// LunarDate as key is fine if hashcode is implemented (which I did).
import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';

part 'event_providers.g.dart';

@riverpod
Future<List<TraditionalEvent>> eventsForLunarMonth(
    Ref ref, int year, int month) async {
  print('Provider: Fetching events for month $month, year $year');
  final repo = ref.watch(eventRepositoryProvider);
  try {
    final results = await repo.getEventsForMonth(year, month);
    print('Provider: Fetched ${results.length} events for lunar month $month, lunar year $year');
    if (results.isEmpty) {
      final all = await repo.getAllTraditionalEvents();
      print('Provider: DB has ${all.length} total events. Query for month $month returned 0.');
    }
    return results;
  } catch (e, stack) {
    print('Provider: Error fetching events for month $month: $e');
    print(stack);
    return [];
  }
}

@riverpod
Future<List<TraditionalEvent>> eventsForLunarDate(
    Ref ref, LunarDate date) async {
  print('Provider: Fetching events for lunar date: $date');
  try {
    final events = await ref
        .watch(eventsForLunarMonthProvider(date.year, date.month).future);
    final filtered = events.where((e) => e.lunarDay == date.day).toList();
    print('Provider: Found ${filtered.length} traditional events for ${date.month}-${date.day}');
    return filtered;
  } catch (e, stack) {
    print('Provider: Error for date ${date.month}-${date.day}: $e');
    print(stack);
    return [];
  }
}
