import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:drift/drift.dart';

class ReminderSettings {
  final int defaultDaysBefore;
  final TimeOfDay defaultTime;
  final bool enableTraditionalReminders;

  ReminderSettings({
    this.defaultDaysBefore = 1,
    this.defaultTime = const TimeOfDay(hour: 9, minute: 0),
    this.enableTraditionalReminders = true,
  });

  ReminderSettings copyWith({
    int? defaultDaysBefore,
    TimeOfDay? defaultTime,
    bool? enableTraditionalReminders,
  }) {
    return ReminderSettings(
      defaultDaysBefore: defaultDaysBefore ?? this.defaultDaysBefore,
      defaultTime: defaultTime ?? this.defaultTime,
      enableTraditionalReminders:
          enableTraditionalReminders ?? this.enableTraditionalReminders,
    );
  }

  String get reminderTimeStr =>
      '${defaultTime.hour.toString().padLeft(2, '0')}:${defaultTime.minute.toString().padLeft(2, '0')}';
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  final AppDatabase _db;

  ReminderSettingsNotifier(this._db) : super(ReminderSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.select(_db.appSettings).getSingleOrNull();
    if (settings != null) {
      final timeParts = settings.reminderTime.split(':');
      final time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      state = ReminderSettings(
        defaultDaysBefore: settings.defaultDaysBefore,
        defaultTime: time,
        enableTraditionalReminders: settings.enableTraditionalReminders,
      );
    }
  }

  Future<void> _saveSettings() async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(1), // Always use ID 1 for single settings row
            defaultDaysBefore: Value(state.defaultDaysBefore),
            reminderTime: Value(state.reminderTimeStr),
            enableTraditionalReminders: Value(state.enableTraditionalReminders),
          ),
        );
  }

  void setDaysBefore(int days) {
    state = state.copyWith(defaultDaysBefore: days);
    _saveSettings();
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(defaultTime: time);
    _saveSettings();
  }

  void toggleTraditional(bool enable) {
    state = state.copyWith(enableTraditionalReminders: enable);
    _saveSettings();
  }
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReminderSettingsNotifier(db);
});
