import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/utils/journal_stats.dart';
import 'package:lenote/features/settings/data/profile_store.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/planner/domain/focus_controller.dart';
import 'package:lenote/features/notes/presentation/step_planner.dart';
import 'foundation_test.dart' show MemoryPreferences;

void main() {
  test(
      'best streak uses unique calendar dates across leap days and month boundaries',
      () {
    expect(bestStreak([]), 0);
    expect(
        bestStreak([
          DateTime(2024, 2, 28),
          DateTime(2024, 2, 29),
          DateTime(2024, 3, 1),
          DateTime(2024, 3, 1, 20),
          DateTime(2024, 3, 3)
        ]),
        3);
  });
  testWidgets(
      'profile cancel retains data, save restores name bio email and avatar after restart',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = MemoryPreferences();
    final store = PreferencesProfileStore(prefs);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(prefs)),
      profileStoreProvider.overrideWithValue(store)
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Discard me');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(profileProvider).name, 'Journal keeper');
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Nade');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'Small steps each day');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'nade@example.com');
    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use buddy illustration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final restored = (await PreferencesProfileStore(prefs).load())!;
    expect(restored.name, 'Nade');
    expect(restored.bio, 'Small steps each day');
    expect(restored.email, 'nade@example.com');
    expect(restored.buddyAvatar, isTrue);
    expect(find.text('Nade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'manual step planning saves only entered tasks and starts one five-minute focus session',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    container.read(routerProvider).go('/create');
    await tester.pumpAndSettle();
    final fields = find.descendant(
        of: find.byType(StepPlanner), matching: find.byType(TextField));
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(fields.at(i));
      await tester.enterText(
          fields.at(i),
          [
            'Prepare demo',
            'Open the project',
            'Review the calendar',
            'Write release notes'
          ][i]);
    }
    await tester.pump();
    await tester.ensureVisible(find.text('Save checklist & start step 1'));
    await tester.tap(find.text('Save checklist & start step 1'));
    await tester.pumpAndSettle();
    final note = container.read(ordinaryNotesProvider).single;
    expect(note.title, 'Prepare demo');
    expect(note.checklist.map((s) => s.text),
        ['Open the project', 'Review the calendar', 'Write release notes']);
    expect(container.read(focusProvider)!.minutes, 5);
    expect(container.read(focusProvider)!.task, 'Open the project');
    container.read(focusProvider.notifier).pause();
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('raised plus responds at its top edge and opens one Create page',
      (tester) async {
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    await tester.pumpAndSettle();
    final bounds = tester.getRect(find.byKey(const ValueKey('nav-create')));
    await tester.tapAt(Offset(bounds.center.dx, bounds.top + 8));
    await tester.pumpAndSettle();
    expect(find.text('Create a moment'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
