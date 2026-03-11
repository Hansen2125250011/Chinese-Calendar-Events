import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/features/events/presentation/providers/event_providers.dart';
import 'dart:developer' as dev;

part 'event_notification_controller.g.dart';

@riverpod
class EventNotificationController extends _$EventNotificationController {
  @override
  void build() {}

  Future<void> toggleNotification(String eventId, bool enable) async {
    final eventRepo = ref.read(eventRepositoryProvider);
    final notificationRepo = ref.read(notificationRepositoryProvider);

    dev.log(
        'EventNotificationController: Toggling notification for $eventId to $enable');

    try {
      // 1. Update Database
      await eventRepo.toggleTraditionalNotification(eventId, enable);

      // 2. Schedule/Cancel Notification
      if (enable) {
        final event = await eventRepo.getEventById(eventId);
        if (event != null) {
          final settings = await notificationRepo.getSettings();
          await notificationRepo.scheduleEventNotification(event, settings);
        }
      } else {
        await notificationRepo.cancelEventNotification(eventId);
      }

      // 3. Invalidate relevant providers to update UI
      ref.invalidate(eventsForLunarMonthProvider);

      dev.log('EventNotificationController: Toggle successful for $eventId');
    } catch (e, stack) {
      dev.log('EventNotificationController: Error toggling notification',
          error: e, stackTrace: stack);
    }
  }
}
