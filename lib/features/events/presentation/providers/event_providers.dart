import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventsForMonth(year, month);
}

@riverpod
Future<List<TraditionalEvent>> eventsForLunarDate(
    Ref ref, LunarDate date) async {
  final events = await ref
      .watch(eventsForLunarMonthProvider(date.year, date.month).future);
  return events.where((e) => e.lunarDay == date.day).toList();
}
