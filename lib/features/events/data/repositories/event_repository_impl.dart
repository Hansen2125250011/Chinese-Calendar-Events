import 'dart:convert';
import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:chinese_calendar/core/database/mappers.dart';
import 'package:chinese_calendar/features/events/domain/entities/traditional_event.dart';
import 'package:chinese_calendar/features/events/domain/repositories/event_repository.dart';
import 'package:chinese_calendar/features/events/data/sources/deity_events_data.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

class EventRepositoryImpl implements EventRepository {
  final AppDatabase _db;
  
  // In-memory cache for month-based event queries
  final Map<String, List<TraditionalEvent>> _monthCache = {};

  EventRepositoryImpl(this._db);

  @override
  Future<void> initialize() async {
    try {
      debugPrint('EventRepository: Initializing traditional events...');
      await (_db.delete(_db.traditionalEvents)
            ..where((t) => t.id.equals('deity_1_24_Test_Event')))
          .go();

      await _seedEvents();
      debugPrint('EventRepository: Traditional events initialized successfully.');
    } catch (e, stack) {
      debugPrint('EventRepository: Error during initialization: $e');
      debugPrint(stack.toString());
      rethrow; // Rethrow to let main.dart handle it
    }
  }

  Future<void> _seedEvents() async {
    try {
      debugPrint('EventRepository: Starting batch insert for traditional events...');
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
          mode: InsertMode.insertOrReplace,
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
          mode: InsertMode.insertOrReplace,
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
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      final count = await getAllTraditionalEvents();
      debugPrint('EventRepository: Seeding complete. Total traditional events in DB: ${count.length}');
      if (count.isNotEmpty) {
        final first = count.first;
        debugPrint('EventRepository: Sample Event - ID: ${first.id}, Month: ${first.lunarMonth}, Day: ${first.lunarDay}');
      }
    } catch (e) {
      debugPrint('EventRepository: Error during seeding: $e');
      rethrow;
    }
}

  @override
  Future<List<TraditionalEvent>> getEventsForMonth(
      int lunarYear, int lunarMonth) async {
    final cacheKey = '$lunarYear-$lunarMonth';
    if (_monthCache.containsKey(cacheKey)) {
      debugPrint('EventRepository: Returning cached events for $cacheKey');
      return _monthCache[cacheKey]!;
    }

    try {
      debugPrint('EventRepository: Fetching traditional events for month: $lunarMonth, year: $lunarYear');
      final query = _db.select(_db.traditionalEvents)
        ..where((tbl) => tbl.lunarMonth.equals(lunarMonth));

      final results = await query.get();
      debugPrint('EventRepository: Found ${results.length} traditional events for lunar month $lunarMonth');
      final mapped = results.map((e) => e.toDomain()).toList();
      
      // Save to cache
      _monthCache[cacheKey] = mapped;
      
      debugPrint('EventRepository: Mapped and cached ${mapped.length} events.');
      return mapped;
    } catch (e, stack) {
      debugPrint('EventRepository: Error fetching events for month $lunarMonth: $e');
      debugPrint(stack.toString());
      return [];
    }
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
    debugPrint('EventRepository: Fetching all traditional events...');
    final results = await _db.select(_db.traditionalEvents).get();
    debugPrint('EventRepository: Found ${results.length} traditional events total.');
    return results.map((e) => e.toDomain()).toList();
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
    return result?.toDomain();
  }
}
