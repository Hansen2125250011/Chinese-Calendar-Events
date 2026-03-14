import 'package:flutter_riverpod/flutter_riverpod.dart';
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
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

// Data Sources / Services
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  // Return service instance; initialization is performed explicitly by the
  // application (see `main.dart`) to ensure initialization is awaited and not
  // started twice concurrently.
  return NotificationService();
}

// Repositories
@riverpod
LunarRepository lunarRepository(Ref ref) {
  return LunarRepositoryImpl();
}

@riverpod
EventRepository eventRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return EventRepositoryImpl(db);
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  final service = ref.watch(notificationServiceProvider);
  final lunarRepo = ref.watch(lunarRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  return NotificationRepositoryImpl(service, lunarRepo, db);
}

@riverpod
CustomEventRepository customEventRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CustomEventRepositoryImpl(db);
}
