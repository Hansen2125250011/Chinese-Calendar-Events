import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';
import 'package:chinese_calendar/features/calendar/domain/repositories/lunar_repository.dart';
import 'package:lunar/lunar.dart';

class LunarRepositoryImpl implements LunarRepository {
  @override
  Future<LunarDate> getLunarDate(DateTime solarDate) async {
    final solar = Solar.fromDate(solarDate);
    final lunar = solar.getLunar();
    final int absMonth = lunar.getMonth().abs();
    final bool isLeap = lunar.getMonth() < 0;

    return LunarDate(
      year: lunar.getYear(),
      month: absMonth,
      day: lunar.getDay(),
      isLeapMonth: isLeap,
      heavenlyStem: lunar.getYearGan(),
      earthlyBranch: lunar.getYearZhi(),
      zodiac: lunar.getYearShengXiao(),
      solarTerm: lunar.getJieQi(),
      yearPillar: lunar.getYearInGanZhi(),
      monthPillar: lunar.getMonthInGanZhi(),
      dayPillar: lunar.getDayInGanZhi(),
      yi: lunar.getDayYi(),
      ji: lunar.getDayJi(),
    );
  }

  @override
  Future<DateTime> getSolarDate({
    required int year,
    required int month,
    required int day,
    bool isLeapMonth = false,
  }) async {
    // 6tails lunar: negative month represents leap month
    final int lunarMonth = isLeapMonth ? -month.abs() : month.abs();
    final lunar = Lunar.fromYmd(year, lunarMonth, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  @override
  Future<String?> getSolarTerm(DateTime solarDate) async {
    final solar = Solar.fromDate(solarDate);
    final lunar = solar.getLunar();
    final term = lunar.getJieQi();
    return term.isNotEmpty ? term : null;
  }
}
