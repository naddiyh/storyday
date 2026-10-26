import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'package:lenote/features/settings/data/reminder_store.dart';
import 'package:lenote/features/notes/domain/note.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/search/presentation/archive_range.dart';
import 'package:lenote/features/search/presentation/search_screen.dart';
import 'package:lenote/features/memories/demo_memories.dart';
import 'foundation_test.dart' show MemoryPreferences;

void main() {
  test('archive range includes full end day and handles open bounds', () {
    final range = ArchiveRange(DateTime(2026, 10, 1), DateTime(2026, 10, 22));
    expect(range.contains(DateTime(2026, 10, 22, 23, 59)), isTrue);
    expect(range.contains(DateTime(2026, 10, 23)), isFalse);
    expect(const ArchiveRange(null, null).contains(DateTime(2000)), isTrue);
  });
  test('reminder changes restore quiet hours and independent flags', () async {
    final prefs = MemoryPreferences();
    final store = PreferencesReminderStore(prefs);
    final controller = ReminderController(store, const ReminderPreferences());
    await controller.update('morning', true);
    await controller.update('quietStart', 1380);
    await controller.update('sunday', true);
    final restored = await PreferencesReminderStore(prefs).load();
    expect(restored.morning, isTrue);
    expect(restored.evening, isTrue);
    expect(restored.sunday, isTrue);
    expect(restored.quietStart, 1380);
    controller.dispose();
  });
  test('old notes remain readable; style stickers and categories round trip',
      () {
    final old = OrdinaryNote.fromMap({
      'id': 'old',
      'date': '2026-10-22',
      'createdAt': '2026-10-22',
      'updatedAt': '2026-10-22'
    });
    expect(old.stickers, isEmpty);
    expect(old.bold, isFalse);
    final note = OrdinaryNote(
        id: 'n',
        date: DateTime(2026),
        kind: NoteKind.mixed,
        title: 'A',
        body: 'B',
        checklist: const [ChecklistItem(text: 'Task')],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        bold: true,
        italic: true,
        fontSize: 20,
        stickers: const ['Jasmine', 'Star'],
        category: 'Shopping');
    final restored = OrdinaryNote.fromMap(note.toMap())
        .withChecklist(const [ChecklistItem(text: 'Task', done: true)]);
    expect(restored.bold, isTrue);
    expect(restored.fontSize, 20);
    expect(restored.stickers, ['Jasmine', 'Star']);
    expect(restored.category, 'Shopping');
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('new PDF routes fit 320px at text $scale', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = ProviderContainer(overrides: [
        appearanceStoreProvider
            .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: const LenoteApp()))));
      for (final route in [
        '/calendar',
        '/day',
        '/reminders',
        '/privacy',
        '/help',
        '/story',
        '/welcome',
        '/onboarding',
        '/account/login',
        '/account/signup',
        '/account/reset',
        '/account/password'
      ]) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
  testWidgets('journal format and stickers save and restore', (tester) async {
    final c = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LenoteApp()));
    c.read(routerProvider).go('/create');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'A saved thought');
    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sticker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Jasmine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    final note = c.read(ordinaryNotesProvider).single;
    expect(note.bold, isTrue);
    expect(note.stickers, ['Jasmine']);
    expect(note.title, 'A saved thought');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'month sheet changes year and selected month without changing date silently',
      (tester) async {
    final c = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 22))
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LenoteApp()));
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    expect(
        tester
            .getSemantics(find.byKey(const Key('month-jump-button')))
            .hasFlag(SemanticsFlag.isButton),
        isTrue);
    expect(
        tester.getSemantics(find.byKey(const Key('month-jump-button'))).label,
        'Jump to a month');
    semantics.dispose();
    await tester.tap(find.byKey(const Key('calendar-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feb'));
    await tester.pumpAndSettle();
    expect(c.read(selectedDateProvider), DateTime(2027, 2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('date filter applies to archive without modifying saved entries',
      (tester) async {
    final now = DateTime.now();
    final note = OrdinaryNote(
        id: 'n',
        date: now.subtract(const Duration(days: 40)),
        kind: NoteKind.journal,
        title: 'Earlier memory',
        body: '',
        checklist: const [],
        createdAt: now,
        updatedAt: now);
    final c = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
      ordinaryNotesRepositoryProvider
          .overrideWithValue(MemoryOrdinaryNoteRepository([note]))
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LenoteApp()));
    c.read(routerProvider).go('/search');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter by date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 0 memories'));
    await tester.pumpAndSettle();
    expect(find.text('Earlier memory'), findsNothing);
    expect(c.read(ordinaryNotesProvider), hasLength(1));
    expect(c.read(archiveRangeProvider).start, isNotNull);
  });
}
