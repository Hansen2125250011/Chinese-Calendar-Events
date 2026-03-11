class LunarDate {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;
  final String heavenlyStem;
  final String earthlyBranch;
  final String zodiac;
  final String? solarTerm;

  // Ba Zi (Pillars)
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;

  // Fortune
  final List<String> yi; // Lucky activities
  final List<String> ji; // Unlucky activities

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.zodiac,
    this.solarTerm,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.yi,
    required this.ji,
  });

  @override
  String toString() {
    return 'LunarDate($year-$month-$day, $yearPillar, $monthPillar, $dayPillar)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LunarDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          isLeapMonth == other.isLeapMonth;

  @override
  int get hashCode =>
      year.hashCode ^ month.hashCode ^ day.hashCode ^ isLeapMonth.hashCode;
}
