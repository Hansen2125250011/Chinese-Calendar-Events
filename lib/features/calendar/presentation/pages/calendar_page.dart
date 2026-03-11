import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/day_detail_view.dart';
import 'package:chinese_calendar/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height:
                  400, // Fixed height for calendar to ensure it's not cramped
              child: CalendarMonthView(),
            ),
            const Divider(),
            const DayDetailView(),
          ],
        ),
      ),
    );
  }
}
