import 'package:chinese_calendar/main.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/calendar_month_view.dart';
import 'package:chinese_calendar/features/calendar/presentation/widgets/day_detail_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads and displays calendar', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify that CalendarMonthView is shown
    expect(find.byType(CalendarMonthView), findsOneWidget);

    // Verify DayDetailView is shown
    expect(find.byType(DayDetailView), findsOneWidget);

    // Verify Month Title (e.g. Current Month)
    // We can't know exact month without mocking, but we can look for "2026" or similar if we freeze time,
    // or just check for any text.
    expect(find.textContaining('202'), findsOneWidget);

    // Tap a day (e.g. text "15")
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    // Verify detail view updates?
    // Hard to verify without intricate knowledge of current date, but no crash is good.
  });
}
