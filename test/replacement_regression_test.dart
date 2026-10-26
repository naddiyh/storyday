import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'foundation_test.dart' show MemoryPreferences;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/core/design/app_theme.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/notes/domain/note.dart';
import 'package:lenote/features/notes/presentation/note_editor_page.dart';
import 'package:lenote/features/search/presentation/search_screen.dart';

class FailingRepository extends MemoryOrdinaryNoteRepository {
  @override
  Future<void> saveAll(List<OrdinaryNote> notes) async =>
      throw StateError('Test storage failure');
}

void main() {
  testWidgets('editor opens above the tab shell and returns to Create',
      (tester) async {
    final container = ProviderContainer(overrides: [
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences()))
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const LenoteApp()));
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/themes');
    await tester.pumpAndSettle();
    expect(find.text('Themes & Appearance'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    container.read(routerProvider).go('/create');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();
    expect(find.text('New journal'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create a moment'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets(
      'archive groups latest dates first and filters ordinary lists and search',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(ordinaryNotesProvider.notifier);
    await controller.load();
    for (final day in [21, 22]) {
      final date = DateTime(2026, 10, day);
      await controller.save(OrdinaryNote(
          id: '$day',
          date: date,
          kind: day == 22 ? NoteKind.checklist : NoteKind.journal,
          title: day == 22 ? 'Packing' : 'Coffee',
          body: day == 21 ? 'A good day' : '',
          checklist: day == 22
              ? const [ChecklistItem(text: 'Passport', done: true)]
              : [],
          createdAt: date,
          updatedAt: date));
    }
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: JournalTheme.lavender.build(),
            home: const Scaffold(body: SearchScreen()))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Packing')).dy,
        lessThan(tester.getTopLeft(find.text('Coffee')).dy));
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('1 of 1 done'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.enterText(find.byType(TextFormField), 'coffee');
    await tester.pumpAndSettle();
    expect(find.text('Packing'), findsNothing);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Secret'), findsNothing);
  });
  testWidgets(
      'save failure retains editor draft and does not publish unsaved memory',
      (tester) async {
    final container = ProviderContainer(overrides: [
      ordinaryNotesRepositoryProvider.overrideWithValue(FailingRepository())
    ]);
    addTearDown(container.dispose);
    await container.read(ordinaryNotesProvider.notifier).load();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: JournalTheme.lavender.build(),
            home: NoteEditorPage(
                date: DateTime(2026, 10, 22), kind: NoteKind.journal))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Retain this draft');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.text('Retain this draft'), findsOneWidget);
    expect(
        find.text(
            'Could not save. Your draft is still here. Please try again.'),
        findsOneWidget);
    expect(container.read(ordinaryNotesProvider), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('full page checklist editor works at 320px with 200 percent text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: JournalTheme.midnight.build(),
            home: NoteEditorPage(
                date: DateTime(2026, 10, 22), kind: NoteKind.checklist))));
    await tester.pumpAndSettle();
    expect(find.text('New checklist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
