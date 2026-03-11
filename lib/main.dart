import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chinese_calendar/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/core/theme/app_theme.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/core/providers/locale_provider.dart';
import 'package:chinese_calendar/core/providers/theme_provider.dart';
import 'package:chinese_calendar/core/router/app_router.dart';

import 'package:chinese_calendar/core/providers/reminder_settings_provider.dart';
import 'package:chinese_calendar/features/notifications/domain/entities/notification_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Pre-initialize services
  await container.read(notificationServiceProvider).init();
  final eventRepo = container.read(eventRepositoryProvider);
  await eventRepo.initialize();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));

  // Background initialization after app starts
  _initBackgroundTasks(container);
}

Future<void> _initBackgroundTasks(ProviderContainer container) async {
  // Sync traditional festival notifications
  final eventRepo = container.read(eventRepositoryProvider);
  final settings = container.read(reminderSettingsProvider);

  if (settings.enableTraditionalReminders) {
    final allEvents = await eventRepo.getAllTraditionalEvents();
    final notificationRepo = container.read(notificationRepositoryProvider);
    await notificationRepo.scheduleTraditionalEvents(
      allEvents,
      true,
      NotificationSettings(
        enabled: true,
        daysBefore: settings.defaultDaysBefore,
        reminderTime: settings.reminderTimeStr,
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Lunar Calendar',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('id'), // Indonesian
        Locale('zh'), // Mandarin
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
