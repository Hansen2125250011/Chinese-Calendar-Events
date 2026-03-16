import 'dart:convert';
import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';

extension TraditionalEventEntityMapper on TraditionalEventEntity {
  TraditionalEvent toDomain() {
    final Map<String, dynamic> names = jsonDecode(name);
    final Map<String, dynamic> descMap = jsonDecode(description);
    
    return TraditionalEvent(
      id: id,
      name: names['en'] ?? name,
      localizedNames: names,
      localizedDescriptions: descMap,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      isMajor: isMajor,
      notificationsEnabled: notificationsEnabled,
    );
  }
}

extension CustomEventEntityMapper on CustomEventEntity {
  CustomEvent toDomain() {
    return CustomEvent(
      id: id,
      name: name,
      isLunar: isLunar,
      year: year,
      month: month,
      day: day,
      isLeap: isLeap,
    );
  }
}
