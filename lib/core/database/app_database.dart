import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

@DataClassName('TraditionalEventEntity')
class TraditionalEvents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get lunarMonth => integer()();
  IntColumn get lunarDay => integer()();
  BoolColumn get isMajor => boolean().withDefault(const Constant(false))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserReminder')
class UserReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text()();
  IntColumn get daysBefore => integer()();
  TextColumn get time => text()(); // "HH:mm" format
}

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get defaultDaysBefore => integer().withDefault(const Constant(1))();
  TextColumn get reminderTime => text().withDefault(const Constant('09:00'))();
  BoolColumn get enableTraditionalReminders =>
      boolean().withDefault(const Constant(true))();
}

@DataClassName('CustomEventEntity')
class CustomEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isLunar => boolean()();
  IntColumn get year => integer().nullable()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  BoolColumn get isLeap => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
    tables: [TraditionalEvents, UserReminders, CustomEvents, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(customEvents);
          }
          if (from < 3) {
            await m.addColumn(
                traditionalEvents, traditionalEvents.notificationsEnabled);
          }
          if (from < 4) {
            await m.createTable(appSettings);
            await m.createTable(userReminders);
          }
          if (from < 5) {
            debugPrint('Upgrading database from schema $from to $to...');
            final tableNames =
                (await customSelect("SELECT name FROM sqlite_master WHERE type='table'").get())
                    .map((row) => row.read<String>('name'))
                    .toList();

            if (!tableNames.contains('app_settings')) {
              debugPrint('Creating app_settings table...');
              await m.createTable(appSettings);
            }
            if (!tableNames.contains('user_reminders')) {
              debugPrint('Creating user_reminders table...');
              await m.createTable(userReminders);
            }

            if (tableNames.contains('custom_events')) {
              debugPrint('Migrating custom_events table...');
              if (tableNames.contains('custom_events_old')) {
                await customStatement('DROP TABLE custom_events_old');
              }
              
              await customStatement('ALTER TABLE custom_events RENAME TO custom_events_old');
              await m.createTable(customEvents);
              try {
                final oldColumns = (await customSelect("PRAGMA table_info(custom_events_old)").get())
                    .map((row) => row.read<String>('name'))
                    .toList();

                String selectQuery;
                if (oldColumns.contains('is_leap')) {
                  selectQuery = 'SELECT id, name, is_lunar, year, month, day, is_leap FROM custom_events_old';
                } else {
                  selectQuery = 'SELECT id, name, is_lunar, year, month, day, 0 as is_leap FROM custom_events_old';
                }

                await customStatement(
                  'INSERT INTO custom_events (id, name, is_lunar, year, month, day, is_leap) $selectQuery',
                );
                await customStatement('DROP TABLE custom_events_old');
                debugPrint('custom_events migration successful.');
              } catch (e) {
                debugPrint('Error migrating custom_events: $e');
                // Ensure the table exists even if data migration fails
                final currentTables = (await customSelect("SELECT name FROM sqlite_master WHERE type='table'").get())
                    .map((row) => row.read<String>('name'))
                    .toList();
                if (!currentTables.contains('custom_events')) {
                  await m.createTable(customEvents);
                }
              }
            } else {
              debugPrint('Creating custom_events table...');
              await m.createTable(customEvents);
            }
          }
        },
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chinese_calendar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
