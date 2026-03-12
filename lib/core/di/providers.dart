import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/core/database/app_database.dart';
import 'package:chinese_calendar/features/calendar/data/repositories/lunar_repository_impl.dart';
import 'package:chinese_calendar/features/calendar/domain/repositories/lunar_repository.dart';
import 'package:chinese_calendar/features/events/data/repositories/event_repository_impl.dart';
import 'package:chinese_calendar/features/events/domain/repositories/event_repository.dart';
import 'package:chinese_calendar/core/services/notification_service.dart';
import 'package:chinese_calendar/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:chinese_calendar/features/notifications/domain/repositories/notification_repository.dart';

import 'package:chinese_calendar/features/events/domain/repositories/custom_event_repository.dart';
import 'package:chinese_calendar/features/events/data/repositories/custom_event_repository_impl.dart';

part 'providers.g.dart';

// Database
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

// Data Sources / Services
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService()
    ..init(); // Initialize on creation? Or separate init logic.
}

// Repositories
@riverpod
LunarRepository lunarRepository(LunarRepositoryRef ref) {
  return LunarRepositoryImpl();
}

@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return EventRepositoryImpl(db);
}

@riverpod
NotificationRepository notificationRepository(NotificationRepositoryRef ref) {
  final service = ref.watch(notificationServiceProvider);
  final lunarRepo = ref.watch(lunarRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  return NotificationRepositoryImpl(service, lunarRepo, db);
}

@riverpod
CustomEventRepository customEventRepository(CustomEventRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return CustomEventRepositoryImpl(db);
}
