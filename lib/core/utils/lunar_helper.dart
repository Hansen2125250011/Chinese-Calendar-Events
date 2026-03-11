class LunarHelper {
  static const List<String> chineseMonths = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月'
  ];

  static const List<String> chineseDays = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿vi',
    '廿七',
    '廿八',
    '廿九',
    '三十'
  ];

  // Note: 廿vi should be 廿六 or simplified 廿六. Let's use correct characters.
  static const List<String> chineseDaysCorrect = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十'
  ];

  static String getLunarDayName(int day) {
    if (day < 1 || day > 30) return day.toString();
    return chineseDaysCorrect[day - 1];
  }

  static String getLunarMonthName(int month) {
    bool isLeap = month < 0;
    int absMonth = month.abs();
    if (absMonth < 1 || absMonth > 12) return month.toString();
    String name = chineseMonths[absMonth - 1];
    return isLeap ? '闰$name' : name;
  }
}
