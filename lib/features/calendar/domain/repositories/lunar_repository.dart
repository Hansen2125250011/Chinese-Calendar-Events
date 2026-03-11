import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';

abstract class LunarRepository {
  /// Converts a Gregorian date to a Chinese Lunar Date.
  Future<LunarDate> getLunarDate(DateTime solarDate);

  /// Converts a Lunar Date to Gregorian Date.
  /// Note: A lunar date might correspond to a leap month, so isLeapMonth is important.
  Future<DateTime> getSolarDate({
    required int year,
    required int month,
    required int day,
    bool isLeapMonth = false,
  });

  /// Returns the Solar Term (Jieqi) for a given Gregorian date, if any.
  Future<String?> getSolarTerm(DateTime solarDate);
}
