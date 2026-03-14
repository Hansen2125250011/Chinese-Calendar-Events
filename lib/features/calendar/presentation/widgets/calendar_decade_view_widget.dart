import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/features/calendar/presentation/providers/calendar_providers.dart';

class CalendarDecadeViewWidget extends ConsumerStatefulWidget {
  const CalendarDecadeViewWidget({super.key});

  @override
  ConsumerState<CalendarDecadeViewWidget> createState() =>
      _CalendarDecadeViewWidgetState();
}

class _CalendarDecadeViewWidgetState
    extends ConsumerState<CalendarDecadeViewWidget> {
  late PageController _pageController;
  final int _baseYear = 1900;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final currentMonth = ref.read(currentMonthProvider);
    _currentPage = (currentMonth.year - _baseYear) ~/ 10;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header with Arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            Builder(
              builder: (context) {
                final decadeStart = _baseYear + (_currentPage * 10);
                return Text(
                  '$decadeStart - ${decadeStart + 9}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
        // Years Grid in PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              final decadeStart = _baseYear + (pageIndex * 10);

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 12, // Show 1 قبل, 10 in decade, 1 after
                itemBuilder: (context, index) {
                  final year = decadeStart - 1 + index;
                  final isSelected = currentMonth.year == year;
                  final inDecade =
                      year >= decadeStart && year < decadeStart + 10;

                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(currentMonthProvider.notifier)
                          .setMonth(DateTime(year, currentMonth.month, 1));
                      ref
                          .read(calendarViewModeNotifierProvider.notifier)
                          .setMode(CalendarViewMode.year);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : (inDecade
                                ? theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.primary)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$year',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : (inDecade
                                    ? null
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3)),
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
