import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';
import 'package:chinese_calendar/features/events/presentation/providers/event_providers.dart';
import 'package:chinese_calendar/features/events/presentation/providers/custom_event_providers.dart';
import 'package:chinese_calendar/core/di/providers.dart';

part 'calendar_providers.g.dart';

enum CalendarViewMode { month, year, decade }

@riverpod
class CalendarViewModeNotifier extends _$CalendarViewModeNotifier {
  @override
  CalendarViewMode build() => CalendarViewMode.month;

  void setMode(CalendarViewMode mode) => state = mode;
}

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

@riverpod
Future<bool> hasEventsForDate(Ref ref, DateTime date) async {
  final lunarRepo = ref.watch(lunarRepositoryProvider);
  final lunar = await lunarRepo.getLunarDate(date);

  // 1. Traditional & Deity Events (via existing provider)
  final traditionalEvents =
      await ref.watch(eventsForLunarDateProvider(lunar).future);
  if (traditionalEvents.isNotEmpty) return true;

  // 2. Custom Events
  final customEvents = await ref.watch(customEventsProvider.future);
  for (final event in customEvents) {
    if (event.isLunar) {
      if (event.month == lunar.month && event.day == lunar.day) {
        if (event.year == null || event.year == lunar.year) {
          if (!event.isLeap || lunar.isLeapMonth) return true;
        }
      }
    } else {
      if (event.month == date.month && event.day == date.day) {
        if (event.year == null || event.year == date.year) return true;
      }
    }
  }

  return false;
}

@riverpod
class CurrentMonth extends _$CurrentMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) => state = month;

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }
}

@riverpod
Future<LunarDate> currentLunarDate(Ref ref) async {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(lunarRepositoryProvider);
  return repo.getLunarDate(date);
}
