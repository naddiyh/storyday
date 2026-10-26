import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/features/calendar/presentation/calendar_day.dart';
import 'package:lenote/features/memories/demo_memories.dart';
import 'package:lenote/features/planner/data/planner_store.dart';
import 'package:lenote/features/planner/domain/focus_controller.dart';
import 'package:lenote/features/planner/domain/planner.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'foundation_test.dart' show MemoryPreferences;

Schedule sample({RepeatRule repeat = RepeatRule.once}) => Schedule(
    id: 'event-1',
    title: 'Watch a series',
    date: DateTime(2026, 10, 24),
    startMinute: 1200,
    endMinute: 1290,
    location: 'Home',
    repeat: repeat);

class FailingPlannerStore extends MemoryPlannerStore {
  @override
  Future<void> save(PlannerData next) async =>
      throw StateError('Test write failure');
}

void main() {
  test('schedule recurrence respects first date and weekly/weekend rules', () {
    expect(sample().occursOn(DateTime(2026, 10, 24, 22)), isTrue);
    expect(sample().occursOn(DateTime(2026, 10, 25)), isFalse);
    expect(sample(repeat: RepeatRule.daily).occursOn(DateTime(2026, 10, 23)),
        isFalse);
    expect(sample(repeat: RepeatRule.daily).occursOn(DateTime(2026, 11, 1)),
        isTrue);
    expect(sample(repeat: RepeatRule.weekends).occursOn(DateTime(2026, 10, 25)),
        isTrue);
    expect(sample(repeat: RepeatRule.weekends).occursOn(DateTime(2026, 10, 26)),
        isFalse);
    expect(sample(repeat: RepeatRule.weekly).occursOn(DateTime(2026, 10, 31)),
        isTrue);
    expect(sample(repeat: RepeatRule.weekly).occursOn(DateTime(2026, 10, 30)),
        isFalse);
  });
  test(
      'planner persists across restart and concurrent mutations retain both records',
      () async {
    final prefs = MemoryPreferences();
    final store = PreferencesPlannerStore(prefs);
    final controller = PlannerController(store, const PlannerData());
    addTearDown(controller.dispose);
    await Future.wait([
      controller.saveSchedule(sample()),
      controller.saveFocus(FocusRecord(
          id: 'session',
          task: 'Read',
          date: DateTime(2026, 10, 24),
          elapsedSeconds: 75,
          targetMinutes: 15))
    ]);
    final restored = await PreferencesPlannerStore(prefs).load();
    expect(restored.schedules.single.timeRange, '20:00 – 21:30');
    expect(restored.focusRecords.single.elapsedSeconds, 75);
    await controller.deleteSchedule('event-1');
    expect((await store.load()).schedules, isEmpty);
    expect((await store.load()).focusRecords, hasLength(1));
  });
  test('failed save does not publish a phantom schedule', () async {
    final controller =
        PlannerController(FailingPlannerStore(), const PlannerData());
    addTearDown(controller.dispose);
    await expectLater(controller.saveSchedule(sample()), throwsStateError);
    expect(controller.state.schedules, isEmpty);
  });
  test('focus pause, resume and completion count actual time once', () async {
    var now = DateTime(2026, 10, 24, 20);
    final records = <FocusRecord>[];
    final controller = FocusController(
        clock: () => now,
        save: (r) async => records.add(r),
        automaticTick: false);
    addTearDown(controller.dispose);
    controller.start('Read ten pages', 15);
    now = now.add(const Duration(seconds: 10));
    controller.tick();
    expect(controller.state!.clockLabel, '14:50');
    controller.pause();
    now = now.add(const Duration(minutes: 5));
    controller.tick();
    expect(controller.state!.elapsed.inSeconds, 10);
    controller.resume();
    now = now.add(const Duration(seconds: 20));
    controller.tick();
    expect(controller.state!.clockLabel, '14:30');
    await Future.wait([controller.finish(), controller.finish()]);
    expect(records.single.elapsedSeconds, 30);
    expect(controller.state!.saved, isTrue);
  });
  test('focus deadline catches up after backgrounding and records exact target',
      () async {
    var now = DateTime(2026, 10, 24);
    final records = <FocusRecord>[];
    final controller = FocusController(
        clock: () => now,
        save: (r) async => records.add(r),
        automaticTick: false);
    addTearDown(controller.dispose);
    controller.start('Read', 1);
    now = now.add(const Duration(minutes: 5));
    controller.tick();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state!.completed, isTrue);
    expect(records.single.elapsedSeconds, 60);
  });
  testWidgets(
      'four creation formats; schedule save reaches calendar and archive',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 24))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/create');
    await tester.pumpAndSettle();
    expect(find.text('Secret Note'), findsNothing);
    expect(find.text('Quick Mood'), findsNothing);
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('New schedule'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Add a title'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Watch a series');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).schedules.single.date,
        DateTime(2026, 10, 24));
    container.read(routerProvider).go('/calendar');
    await tester.pumpAndSettle();
    expect(find.text('Watch a series'), findsOneWidget);
    final day = tester
        .widgetList<CalendarDay>(find.byType(CalendarDay))
        .singleWhere((d) => d.date.day == 24);
    expect(day.activity.entries.any((e) => e.scheduled), isTrue);
    expect(find.text('Mood'), findsNothing);
    expect(find.text('Secret'), findsNothing);
    container.read(routerProvider).go('/search');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schedule').first);
    await tester.pumpAndSettle();
    expect(find.text('Watch a series'), findsOneWidget);
    await tester.tap(find.text('Watch a series'));
    await tester.pumpAndSettle();
    expect(find.text('Edit schedule'), findsOneWidget);
    await tester.ensureVisible(find.text('Delete schedule'));
    await tester.tap(find.text('Delete schedule'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).schedules, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'focus creation starts timer, pauses, resumes, completes and returns',
      (tester) async {
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/create');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Focus session'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Start 25 min with your buddy'));
    await tester.tap(find.text('Start 25 min with your buddy'));
    await tester.pumpAndSettle();
    expect(find.text('Pause focus'), findsOneWidget);
    await tester.ensureVisible(find.text('Pause focus'));
    await tester.tap(find.text('Pause focus'));
    await tester.pumpAndSettle();
    expect(find.text('Resume focus'), findsOneWidget);
    await tester.tap(find.text('Resume focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Step done'));
    await tester.pumpAndSettle();
    expect(container.read(plannerProvider).focusRecords, hasLength(1));
    expect(find.text('Choose the next small step'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final route in ['/schedule', '/focus/setup', '/focus']) {
    testWidgets('$route fits narrow 200 percent text', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = ProviderContainer(overrides: [
        appearanceStoreProvider
            .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
      ]);
      addTearDown(container.dispose);
      if (route == '/focus') {
        container.read(focusProvider.notifier).start('Read ten pages', 25);
        container.read(focusProvider.notifier).pause();
      }
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const LenoteApp()));
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
