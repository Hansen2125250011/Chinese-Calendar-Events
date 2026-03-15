import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:intl/intl.dart';

class CalendarYearViewWidget extends ConsumerWidget {
  const CalendarYearViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Year Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GestureDetector(
            onTap: () {
              ref
                  .read(calendarViewModeProvider.notifier)
                  .setMode(CalendarViewMode.decade);
            },
            child: Text(
              '${currentMonth.year}',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Months Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final date = DateTime(currentMonth.year, month, 1);
              final isSelected = currentMonth.month == month;

              return GestureDetector(
                onTap: () {
                  ref.read(currentMonthProvider.notifier).setMonth(date);
                  ref
                      .read(calendarViewModeProvider.notifier)
                      .setMode(CalendarViewMode.month);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
