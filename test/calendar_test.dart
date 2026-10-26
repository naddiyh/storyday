import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/design/app_theme.dart';
import 'package:lenote/features/calendar/data/demo_calendar.dart';
import 'package:lenote/features/calendar/domain/calendar_month.dart';
import 'package:lenote/features/calendar/domain/day_activity.dart';
import 'package:lenote/features/calendar/presentation/calendar_day.dart';
import 'package:lenote/features/memories/demo_memories.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'package:lenote/features/themes/domain/appearance.dart';
import 'foundation_test.dart' show MemoryPreferences;

void main() {
  test('month shifts clamp days, handle leap years and year boundaries', () {
    expect(
        CalendarMonth.shift(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
    expect(
        CalendarMonth.shift(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
    expect(
        CalendarMonth.shift(DateTime(2026, 12, 25), 1), DateTime(2027, 1, 25));
    expect(
        CalendarMonth.shift(DateTime(2027, 1, 25), -1), DateTime(2026, 12, 25));
    expect(CalendarMonth(2026, 6).leadingDays(1), 0);
  });
  testWidgets(
      'dated fixtures, removed indicators, decoration edits and creation date',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
      calendarClockProvider.overrideWithValue(() => DateTime(2026, 10, 22)),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Week'), findsNothing);
    expect(find.byType(CalendarDay), findsNWidgets(31));

    expect(find.text('A fresh page awaits'), findsOneWidget);
    expect(find.text('An evening walk'), findsNothing);
    final locked = tester
        .widgetList<CalendarDay>(find.byType(CalendarDay))
        .singleWhere((d) => d.date.day == 16);
    expect(locked.activity.entries, isEmpty);
    await tester.tap(find.text('22'));
    await tester.pumpAndSettle();
    expect(find.text('An evening walk'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    await tester.ensureVisible(find.text('Flower'));
    await tester.tap(find.text('Flower'));
    await tester.pumpAndSettle();
    expect(container.read(decorationOverridesProvider)[DateTime(2026, 10, 22)],
        CalendarDecoration.flower);
    await tester.ensureVisible(find.text('Create for this day'));
    await tester.tap(find.text('Create for this day'));
    await tester.pumpAndSettle();
    expect(find.text('October 22, 2026'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    container.read(routerProvider).go('/calendar');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Next month'));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(container.read(selectedDateProvider), DateTime(2026, 11, 22));
    expect(find.text('An evening walk'), findsNothing);
    expect(find.text('A fresh page awaits'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('calendar-month')));
    await tester.tap(find.byKey(const Key('calendar-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to today'));
    await tester.pumpAndSettle();
    expect(container.read(selectedDateProvider), DateTime(2026, 10, 22));
    expect(tester.takeException(), isNull);
  });
  for (final theme in JournalTheme.values) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('narrow large-text calendar: ${theme.id} ${mode.name}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = ProviderContainer(overrides: [
          appearanceStoreProvider.overrideWithValue(
              PreferencesAppearanceStore(MemoryPreferences())),
          initialAppearanceProvider
              .overrideWithValue(Appearance(theme: theme, mode: mode))
        ]);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container, child: const LenoteApp()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
