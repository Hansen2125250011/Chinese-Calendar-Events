import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:chinese_calendar/features/events/domain/entities/custom_event.dart';
import 'package:chinese_calendar/features/events/domain/repositories/custom_event_repository.dart';
import 'package:drift/drift.dart';

class CustomEventRepositoryImpl implements CustomEventRepository {
  final AppDatabase _db;

  CustomEventRepositoryImpl(this._db);

  @override
  Future<List<CustomEvent>> getAllEvents() async {
    final results = await _db.select(_db.customEvents).get();
    return results
        .map((e) => CustomEvent(
              id: e.id,
              name: e.name,
              isLunar: e.isLunar,
              year: e.year,
              month: e.month,
              day: e.day,
              isLeap: e.isLeap,
            ))
        .toList();
  }

  @override
  Future<int> addEvent(CustomEvent event) async {
    return _db.into(_db.customEvents).insert(CustomEventsCompanion.insert(
          name: event.name,
          isLunar: event.isLunar,
          year: Value(event.year),
          month: event.month,
          day: event.day,
          isLeap: Value(event.isLeap),
        ));
  }

  @override
  Future<void> updateEvent(CustomEvent event) async {
    await (_db.update(_db.customEvents)
          ..where((tbl) => tbl.id.equals(event.id)))
        .write(
      CustomEventsCompanion(
        name: Value(event.name),
        isLunar: Value(event.isLunar),
        year: Value(event.year),
        month: Value(event.month),
        day: Value(event.day),
        isLeap: Value(event.isLeap),
      ),
    );
  }

  @override
  Future<void> deleteEvent(int id) async {
    await (_db.delete(_db.customEvents)..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
