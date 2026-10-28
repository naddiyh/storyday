import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lenote/app/app.dart';
import 'package:lenote/app/router.dart';
import 'package:lenote/core/cloud/cloud_connection.dart';
import 'package:lenote/features/notes/data/note_repository.dart';
import 'package:lenote/features/notes/presentation/note_detail_page.dart';
import 'package:lenote/features/themes/data/appearance_store.dart';
import 'foundation_test.dart' show MemoryPreferences;
import 'journal_sync_test.dart' show note;

User user(String id) => User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-28T00:00:00Z');

void main() {
  testWidgets(
      'switching accounts or logging out closes stale note pages and isolates notes',
      (tester) async {
    final identity = StateProvider<User?>((ref) => user('a'));
    final a = MemoryOrdinaryNoteRepository([note('private-A')]);
    final b = MemoryOrdinaryNoteRepository([note('private-B')]);
    final guest = MemoryOrdinaryNoteRepository([note('guest')]);
    final c = ProviderContainer(overrides: [
      cloudUserProvider.overrideWith((ref) => ref.watch(identity)),
      ordinaryNotesRepositoryProvider
          .overrideWith((ref) => switch (ref.watch(cloudUserProvider)?.id) {
                'a' => a,
                'b' => b,
                _ => guest,
              }),
      appearanceStoreProvider
          .overrideWithValue(PreferencesAppearanceStore(MemoryPreferences())),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LenoteApp()));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => NoteDetailPage(note: note('private-A'))));
    await tester.pumpAndSettle();
    expect(find.text('private-A'), findsOneWidget);
    c.read(identity.notifier).state = user('b');
    await tester.pumpAndSettle();
    expect(find.text('private-A'), findsNothing);
    expect(c.read(ordinaryNotesProvider).single.id, 'private-B');
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/calendar');
    c.read(identity.notifier).state = null;
    await tester.pumpAndSettle();
    expect(c.read(ordinaryNotesProvider).single.id, 'guest');
    expect(find.text('private-B'), findsNothing);
  });
}
