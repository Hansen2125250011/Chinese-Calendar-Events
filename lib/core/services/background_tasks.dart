import 'package:workmanager/workmanager.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('BackgroundTasks: Executing task: $task');
    
    final container = ProviderContainer();
    
    try {
      if (task == 'sync_notifications') {
        // Essential: Initialize notifications and timezones for the background isolate
        await container.read(notificationServiceProvider).init();
        
        final notificationRepo = container.read(notificationRepositoryProvider);
        await notificationRepo.syncAllNotifications();
      }
      return true;
    } catch (e, stack) {
      debugPrint('BackgroundTasks: Error: $e');
      debugPrint(stack.toString());
      return false;
    } finally {
      container.dispose();
    }
  });
}

class BackgroundTasks {
  static const String syncNotificationsTask = 'sync_notifications';

  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static Future<void> scheduleSync() async {
    await Workmanager().registerOneOffTask(
      '1',
      syncNotificationsTask,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
