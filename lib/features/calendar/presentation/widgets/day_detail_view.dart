import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chinese_calendar/features/events/presentation/providers/event_providers.dart';
import 'package:intl/intl.dart';

import 'package:chinese_calendar/features/events/presentation/widgets/add_event_dialog.dart';
import 'package:chinese_calendar/features/events/presentation/providers/custom_event_providers.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/l10n/app_localizations.dart';
import 'package:chinese_calendar/features/events/presentation/providers/event_notification_controller.dart';
import 'package:chinese_calendar/core/utils/ba_zi_helper.dart';

class DayDetailView extends ConsumerWidget {
  const DayDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final theme = Theme.of(context);
    final lunarAsync = ref.watch(currentLunarDateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            lunarAsync.when(
              data: (lunar) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lunar Date & Zodiac
                  Row(
                    children: [
                      Text(
                        '${lunar.month} Month ${lunar.day} Day',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                          label: Text(lunar.zodiac),
                          visualDensity: VisualDensity.compact),
                    ],
                  ),
                  if (lunar.solarTerm != null)
                    Text('${l10n.solarTerm}: ${lunar.solarTerm}',
                        style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic)),

                  const Divider(),

                  // Ba Zi (Four Pillars)
                  Text(l10n.baZi, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _BaZiColumn(
                            l10n.yearPillar,
                            BaZiHelper.localizePillar(lunar.yearPillar,
                                Localizations.localeOf(context).languageCode)),
                      ),
                      Expanded(
                        child: _BaZiColumn(
                            l10n.monthPillar,
                            BaZiHelper.localizePillar(lunar.monthPillar,
                                Localizations.localeOf(context).languageCode)),
                      ),
                      Expanded(
                        child: _BaZiColumn(
                            l10n.dayPillar,
                            BaZiHelper.localizePillar(lunar.dayPillar,
                                Localizations.localeOf(context).languageCode)),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Daily Fortune (Yi / Ji)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.yi,
                                style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold)),
                            Text(lunar.yi.join(', '),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.ji,
                                style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold)),
                            Text(lunar.ji.join(', '),
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.events}:',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) =>
                              AddEventDialog(initialDate: selectedDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Custom Events
                  Consumer(builder: (context, ref, _) {
                    final customEventsAsync = ref.watch(customEventsProvider);
                    return customEventsAsync.when(
                      data: (events) {
                        final customOnDay = events.where((e) {
                          if (e.isLunar) {
                            return e.month == lunar.month &&
                                e.day == lunar.day &&
                                (e.year == null || e.year == lunar.year);
                          } else {
                            return e.month == selectedDate.month &&
                                e.day == selectedDate.day &&
                                (e.year == null || e.year == selectedDate.year);
                          }
                        }).toList();

                        if (customOnDay.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: customOnDay
                              .map((e) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(e.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                    subtitle: Text(e.isLunar
                                        ? 'Lunar Event'
                                        : 'Gregorian Event'),
                                    leading: const Icon(Icons.person,
                                        color: Colors.blue),
                                    dense: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 16),
                                          onPressed: () => showDialog(
                                            context: context,
                                            builder: (_) =>
                                                AddEventDialog(event: e),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 16),
                                          onPressed: () => ref
                                              .read(
                                                  customEventRepositoryProvider)
                                              .deleteEvent(e.id)
                                              .then((_) => ref.invalidate(
                                                  customEventsProvider)),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                    );
                  }),

                  // Traditional Events
                  Consumer(builder: (context, ref, _) {
                    final eventsAsync =
                        ref.watch(eventsForLunarDateProvider(lunar));
                    final localeCode =
                        Localizations.localeOf(context).languageCode;

                    return eventsAsync.when(
                      data: (events) {
                        if (events.isEmpty) {
                          // Only show "No festivities" if NO custom events either?
                          // For now check logic is separated.
                          return Text(l10n.traditionalEvents,
                              style: const TextStyle(color: Colors.grey));
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: events
                              .map((e) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(e.getName(localeCode),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle:
                                        Text(e.getDescription(localeCode)),
                                    leading: Icon(
                                        e.isMajor
                                            ? Icons.celebration
                                            : Icons.temple_buddhist,
                                        color: e.isMajor
                                            ? Colors.red
                                            : theme.colorScheme.secondary),
                                    dense: true,
                                    trailing: IconButton(
                                      icon: Icon(
                                        e.notificationsEnabled
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        size: 20,
                                        color: e.notificationsEnabled
                                            ? theme.colorScheme.primary
                                            : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        await ref
                                            .read(
                                                eventNotificationControllerProvider
                                                    .notifier)
                                            .toggleNotification(
                                                e.id, !e.notificationsEnabled);
                                      },
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading events: $err'),
                    );
                  }),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading lunar date: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaZiColumn extends StatelessWidget {
  final String label;
  final String value;
  const _BaZiColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
