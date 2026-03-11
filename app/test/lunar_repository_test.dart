import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_calendar/features/calendar/data/repositories/lunar_repository_impl.dart';

void main() {
  late LunarRepositoryImpl repository;

  setUp(() {
    repository = LunarRepositoryImpl();
  });

  group('LunarRepositoryImpl', () {
    test('getLunarDate should return a valid LunarDate', () async {
      final solarDate = DateTime(2024, 2, 10); // Chinese New Year 2024
      final lunarDate = await repository.getLunarDate(solarDate);

      expect(lunarDate.year, 2024);
      expect(lunarDate.month, 1);
      expect(lunarDate.day, 1);
      expect(lunarDate.isLeapMonth, false);
    });

    test('getSolarDate should handle leap months correctly', () async {
      // In 2023, there was a leap 2nd month
      // Solar Date: 2023-04-20 is Lunar 2023-闰2-1
      final solarDate = await repository.getSolarDate(
        year: 2023,
        month: 2,
        day: 1,
        isLeapMonth: true,
      );

      expect(solarDate.year, 2023);
      expect(solarDate.month, 4);
      expect(solarDate.day, 20);
    });

    test('getLunarDate should detect leap month correctly', () async {
      final solarDate = DateTime(2023, 4, 20);
      final lunarDate = await repository.getLunarDate(solarDate);

      expect(lunarDate.year, 2023);
      expect(lunarDate.month, 2);
      expect(lunarDate.isLeapMonth, true);
    });
  });
}
