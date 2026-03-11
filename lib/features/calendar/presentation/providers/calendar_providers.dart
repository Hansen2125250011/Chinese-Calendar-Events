import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';
import 'package:chinese_calendar/core/di/providers.dart';

part 'calendar_providers.g.dart';

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
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
Future<LunarDate> currentLunarDate(CurrentLunarDateRef ref) async {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(lunarRepositoryProvider);
  return repo.getLunarDate(date);
}
