import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chinese_calendar/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:chinese_calendar/core/theme/app_theme.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/core/providers/locale_provider.dart';
import 'package:chinese_calendar/core/providers/theme_provider.dart';
import 'package:chinese_calendar/core/router/app_router.dart';

import 'package:chinese_calendar/core/services/background_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Tasks early
  await BackgroundTasks.init();

  final container = ProviderContainer();

  // 1. Initialize Essential Non-Blocking Services
  await container.read(notificationServiceProvider).init();
  
  // 2. Event Seeding (Keep it separate from UI startup)
  final eventRepo = container.read(eventRepositoryProvider);
  
  // ignore: unawaited_futures
  eventRepo.initialize().then((_) {
    debugPrint('Main: Event repository initialized in background.');
    // Trigger notification sync after database is ready
    BackgroundTasks.scheduleSync();
  }).catchError((e) {
    debugPrint('Main: Event repo init error: $e');
  });

  debugPrint('Main: Starting app...');
  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
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
