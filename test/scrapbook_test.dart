import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenote/features/notes/presentation/create_screen.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/notes/domain/note.dart';
import 'package:lenote/features/memories/demo_memories.dart';
import 'package:lenote/core/design/app_theme.dart';

void main() {
  testWidgets(
      'editing preserves completed checklist state; delete requires confirmation',
      (tester) async {
    final date = DateTime(2026, 10, 22);
    final container = ProviderContainer(
        overrides: [selectedDateProvider.overrideWith((ref) => date)]);
    addTearDown(container.dispose);
    final controller = container.read(ordinaryNotesProvider.notifier);
    await controller.load();
    await controller.save(OrdinaryNote(
        id: 'checked',
        date: date,
        kind: NoteKind.checklist,
        title: 'Packing',
        body: '',
        checklist: const [ChecklistItem(text: 'Passport', done: true)],
        createdAt: date,
        updatedAt: date));
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: JournalTheme.lavender.build(),
            home: const Scaffold(body: CreateScreen()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Packing'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, true);
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(container.read(ordinaryNotesProvider).single.checklist.single.done,
        true);
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(container.read(ordinaryNotesProvider), hasLength(1));
    await tester.tap(find.byTooltip('Delete note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(container.read(ordinaryNotesProvider), isEmpty);
    expect(find.text('Secret Note'), findsNothing);
    expect(find.text('Quick Mood'), findsNothing);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Focus session'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
