import 'dart:convert';
import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/features/events/domain/repositories/event_repository.dart';
import 'package:chinese_calendar/features/events/data/sources/deity_events_data.dart';
import 'package:drift/drift.dart';

class EventRepositoryImpl implements EventRepository {
  final AppDatabase _db;

  EventRepositoryImpl(this._db);

  @override
  Future<void> initialize() async {
    // Cleanup old test event if exists
    await (_db.delete(_db.traditionalEvents)
          ..where((t) => t.id.equals('deity_1_24_Test_Event')))
        .go();

    // Always seed to ensure new events are added.
    // Existing ones will be ignored due to batch insertOrIgnore.
    await _seedEvents();
  }

  Future<void> _seedEvents() async {
    await _db.batch((batch) {
      // Basic seeding
      batch.insert(
        _db.traditionalEvents,
        TraditionalEventsCompanion.insert(
          id: 'cny',
          name: jsonEncode(
              {'en': 'Chinese New Year', 'id': 'Tahun Baru Imlek', 'zh': '春节'}),
          description: jsonEncode({
            'en': 'First day of first lunar month',
            'id': 'Hari pertama bulan lunar pertama',
            'zh': '农历正月初一'
          }),
          lunarMonth: 1,
          lunarDay: 1,
          isMajor: const Value(true),
        ),
        mode: InsertMode.insertOrIgnore,
      );

      batch.insert(
        _db.traditionalEvents,
        TraditionalEventsCompanion.insert(
          id: 'mid_autumn',
          name: jsonEncode({
            'en': 'Mid-Autumn Festival',
            'id': 'Festival Kue Bulan',
            'zh': '中秋节'
          }),
          description: jsonEncode({
            'en': '15th day of 8th lunar month',
            'id': 'Hari ke-15 bulan ke-8',
            'zh': '农历八月十五'
          }),
          lunarMonth: 8,
          lunarDay: 15,
          isMajor: const Value(true),
        ),
        mode: InsertMode.insertOrIgnore,
      );

      // Seed Deity Events
      for (final event in DeityEventsData.all) {
        final Map<String, dynamic> names = event['name'];
        final enName = names['en'] ?? 'Unknown';
        final String id =
            'deity_${event['month']}_${event['day']}_${enName.replaceAll(' ', '_')}';

        batch.insert(
          _db.traditionalEvents,
          TraditionalEventsCompanion.insert(
            id: id,
            name: jsonEncode(event['name']),
            description: jsonEncode(event['desc']),
            lunarMonth: event['month'] as int,
            lunarDay: event['day'] as int,
            isMajor: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  TraditionalEvent _mapToEntity(TraditionalEventEntity row) {
    Map<String, dynamic> names;
    Map<String, dynamic> descs;

    try {
      names = jsonDecode(row.name);
    } catch (_) {
      names = {'en': row.name};
    }

    try {
      descs = jsonDecode(row.description);
    } catch (_) {
      descs = {'en': row.description};
    }

    return TraditionalEvent(
      id: row.id,
      name: names['en'] ?? row.name, // Fallback
      localizedNames: names,
      localizedDescriptions: descs,
      lunarMonth: row.lunarMonth,
      lunarDay: row.lunarDay,
      isMajor: row.isMajor,
      notificationsEnabled: row.notificationsEnabled,
    );
  }

  @override
  Future<List<TraditionalEvent>> getEventsForMonth(
      int lunarYear, int lunarMonth) async {
    final query = _db.select(_db.traditionalEvents)
      ..where((tbl) => tbl.lunarMonth.equals(lunarMonth));

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  @override
  Future<void> saveUserReminder(
      String eventId, int daysBefore, String time) async {
    await _db.into(_db.userReminders).insert(
          UserRemindersCompanion(
            eventId: Value(eventId),
            daysBefore: Value(daysBefore),
            time: Value(time),
          ),
        );
  }

  @override
  Future<List<TraditionalEvent>> getAllTraditionalEvents() async {
    final results = await _db.select(_db.traditionalEvents).get();
    return results.map(_mapToEntity).toList();
  }

  @override
  Future<void> toggleTraditionalNotification(
      String eventId, bool enabled) async {
    await (_db.update(_db.traditionalEvents)
          ..where((t) => t.id.equals(eventId)))
        .write(
            TraditionalEventsCompanion(notificationsEnabled: Value(enabled)));
  }

  @override
  Future<TraditionalEvent?> getEventById(String eventId) async {
    final query = _db.select(_db.traditionalEvents)
      ..where((t) => t.id.equals(eventId));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }
}
