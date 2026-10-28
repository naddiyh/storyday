import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/journal_navigation_bar.dart';
import 'create_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notes/data/note_repository.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notesLoadStatusProvider);
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        if (status.isLoading) const LinearProgressIndicator(),
        if (status.hasError)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                const Text(
                    'Saved notes could not be opened. Original data is kept; saving is blocked until it can be read.'),
                TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(ordinaryNotesProvider.notifier).load();
                      } catch (_) {/* Banner stays visible. */}
                    },
                    child: const Text('Retry loading notes')),
              ])),
        Expanded(child: navigationShell),
      ])),
      bottomNavigationBar: JournalNavigationBar(
          selectedIndex: navigationShell.currentIndex >= 2
              ? navigationShell.currentIndex + 1
              : navigationShell.currentIndex,
          onSelect: (i) => i == 2
              ? openCreatePage(context)
              : navigationShell.goBranch(i > 2 ? i - 1 : i)),
    );
  }
}
