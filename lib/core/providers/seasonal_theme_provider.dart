import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lunar/lunar.dart';

part 'seasonal_theme_provider.g.dart';

enum FestivalType {
  none,
  springFestival, // CNY
  dragonBoat,
  qixi,
  midAutumn,
}

class SeasonalThemeInfo {
  final FestivalType type;
  final Color seedColor;
  final String festivalName;

  SeasonalThemeInfo({
    required this.type,
    required this.seedColor,
    required this.festivalName,
  });

  static final none = SeasonalThemeInfo(
    type: FestivalType.none,
    seedColor: const Color(0xFFD32F2F),
    festivalName: '',
  );
}

@riverpod
SeasonalThemeInfo seasonalTheme(Ref ref) {
  final now = DateTime.now();

  // Check next 7 days
  for (int i = 0; i <= 7; i++) {
    final date = now.add(Duration(days: i));
    final solar = Solar.fromDate(date);
    final lunar = solar.getLunar();
    final month = lunar.getMonth();
    final day = lunar.getDay();

    // Chinese New Year: 1/1
    if (month == 1 && day == 1) {
      return SeasonalThemeInfo(
        type: FestivalType.springFestival,
        seedColor: const Color(0xFFE53935), // Vibrant Festival Red
        festivalName: 'Spring Festival',
      );
    }

    // Dragon Boat: 5/5
    if (month == 5 && day == 5) {
      return SeasonalThemeInfo(
        type: FestivalType.dragonBoat,
        seedColor: const Color(0xFF43A047), // Bamboo Green
        festivalName: 'Dragon Boat Festival',
      );
    }

    // Qixi: 7/7
    if (month == 7 && day == 7) {
      return SeasonalThemeInfo(
        type: FestivalType.qixi,
        seedColor: const Color(0xFF9C27B0), // Romantic Purple
        festivalName: 'Qixi Festival',
      );
    }

    // Mid-Autumn: 8/15
    if (month == 8 && day == 15) {
      return SeasonalThemeInfo(
        type: FestivalType.midAutumn,
        seedColor: const Color(0xFFFF9800), // Moon Orange/Gold
        festivalName: 'Mid-Autumn Festival',
      );
    }
  }

  return SeasonalThemeInfo.none;
}
