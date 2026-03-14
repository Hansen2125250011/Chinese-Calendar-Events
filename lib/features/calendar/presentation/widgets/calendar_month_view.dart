import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chinese_calendar/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chinese_calendar/core/di/providers.dart';
import 'package:chinese_calendar/features/calendar/domain/entities/lunar_date.dart';
import 'package:intl/intl.dart';
import 'package:chinese_calendar/core/utils/lunar_helper.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/calendar_year_view_widget.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/calendar_decade_view_widget.dart';

class CalendarMonthView extends ConsumerStatefulWidget {
  const CalendarMonthView({super.key});

  @override
  ConsumerState<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends ConsumerState<CalendarMonthView> {
  late PageController _pageController;
  // Base date for page index calculation (Index 0 = Jan 1900)
  // Using a far past date ensures most usage is positive index
  final DateTime _baseDate = DateTime(1900, 1, 1);

  @override
  void initState() {
    super.initState();
    // Initialize controller based on current provider state
    final currentMonth = ref.read(currentMonthProvider);
    final initialPage = _monthDifference(currentMonth, _baseDate);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _monthDifference(DateTime a, DateTime b) {
    return (a.year - b.year) * 12 + a.month - b.month;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(currentMonthProvider);
    final theme = Theme.of(context);

    // Listen to provider changes to update page controller if needed
    // This handles arrow button navigation or other external updates
    ref.listen(currentMonthProvider, (prev, next) {
      if (_pageController.hasClients) {
        final targetPage = _monthDifference(next, _baseDate);
        if ((_pageController.page?.round() ?? -1) != targetPage) {
          _pageController.jumpToPage(targetPage);
        }
      }
    });

    final viewMode = ref.watch(calendarViewModeNotifierProvider);

    return Column(
      children: [
        if (viewMode == CalendarViewMode.month) ...[
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
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(calendarViewModeNotifierProvider.notifier)
                        .setMode(CalendarViewMode.year);
                  },
                  child: Text(
                    DateFormat('MMMM yyyy').format(currentMonth),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: day == 'Sun' ? Colors.red : null,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: _pageController,
              onPageChanged: (index) {
                final newMonth =
                    DateTime(_baseDate.year, _baseDate.month + index, 1);
                // Avoid redundant updates if already same (though provider handles it)
                if (!DateUtils.isSameMonth(
                    ref.read(currentMonthProvider), newMonth)) {
                  ref.read(currentMonthProvider.notifier).setMonth(newMonth);
                }
              },
              itemBuilder: (context, index) {
                final monthDate =
                    DateTime(_baseDate.year, _baseDate.month + index, 1);
                return _MonthGrid(currentMonth: monthDate);
              },
            ),
          ),
        ] else if (viewMode == CalendarViewMode.year) ...[
          const Expanded(child: CalendarYearViewWidget()),
        ] else ...[
          const Expanded(child: CalendarDecadeViewWidget()),
        ],
      ],
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  final DateTime currentMonth;
  const _MonthGrid({required this.currentMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysInMonth =
        DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final int weekdayOffset = firstDay.weekday % 7;

    final totalSlots = daysInMonth + weekdayOffset;

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      physics: const NeverScrollableScrollPhysics(), // Handled by PageView
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < weekdayOffset) {
          return const SizedBox.shrink();
        }
        final day = index - weekdayOffset + 1;
        final date = DateTime(currentMonth.year, currentMonth.month, day);

        return _CalendarDayCell(date: date);
      },
    );
  }
}

class _CalendarDayCell extends ConsumerWidget {
  final DateTime date;

  const _CalendarDayCell({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final isSelected = DateUtils.isSameDay(date, selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isSunday = date.weekday == DateTime.sunday;

    // Asynchronously fetch lunar date
    final lunarRepo = ref.watch(lunarRepositoryProvider);

    return GestureDetector(
      onTap: () {
        ref.read(selectedDateProvider.notifier).setDate(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : null,
          border: isToday ? Border.all(color: theme.colorScheme.primary) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: isSunday ? Colors.red : null,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal)),
            FutureBuilder<LunarDate>(
                future: lunarRepo.getLunarDate(date),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final lunar = snapshot.data!;
                    return Column(
                      children: [
                        Text(
                          lunar.day == 1
                              ? LunarHelper.getLunarMonthName(lunar.month.abs())
                              : LunarHelper.getLunarDayName(lunar.day),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: lunar.day == 1
                                  ? theme.colorScheme.primary
                                  : Colors.grey),
                        ),
                        // Event Dot
                        Consumer(builder: (context, ref, _) {
                          final hasEventsAsync =
                              ref.watch(hasEventsForDateProvider(date));
                          return hasEventsAsync.maybeWhen(
                            data: (hasEvents) {
                              if (hasEvents) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error, // Red dot
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            orElse: () => const SizedBox.shrink(),
                          );
                        }),
                      ],
                    );
                  }
                  return const SizedBox(height: 10);
                }),
          ],
        ),
      ),
    );
  }
}
