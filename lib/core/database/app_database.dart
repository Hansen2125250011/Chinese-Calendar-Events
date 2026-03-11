import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
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
