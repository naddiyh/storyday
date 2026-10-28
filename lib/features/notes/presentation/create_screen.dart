import 'note_editor_page.dart';
import 'step_planner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/scrapbook_palette.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../memories/demo_memories.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';

class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final notes = ref
        .watch(ordinaryNotesProvider)
        .where((note) => DateUtils.isSameDay(note.date, selectedDate))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final entries = const {
      'Journal / Note': Icons.edit_note,
      'Checklist / To-do': Icons.checklist,
      'Schedule': Icons.event_outlined,
      'Focus session': Icons.timer_outlined,
    }.entries.toList();

    return PageContent(children: [
      const SizedBox(height: 36),
      ScrapbookHeader(
          title: const bool.fromEnvironment('UI_REFERENCE_REVIEW')
              ? 'Create'
              : 'Create a moment',
          subtitle: 'What would you like to add today?',
          action: IconButton.filledTonal(
              style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest),
              tooltip: 'Close Create',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/calendar'),
              icon: const Icon(Icons.close, size: 20))),
      const SizedBox(height: 8),
      if (!const bool.fromEnvironment('UI_REFERENCE_REVIEW'))
        Text(DateFormat.yMMMMd().format(selectedDate),
            key: const Key('selected-date')),
      if (!const bool.fromEnvironment('UI_REFERENCE_REVIEW'))
        const SizedBox(height: 20),
      if (notes.isNotEmpty) ...[
        Text('Saved for this day',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final note in notes)
          Card(
            child: ListTile(
              title: Text(note.title),
              subtitle: note.body.isEmpty
                  ? (note.checklist.isEmpty
                      ? const Text('No content saved yet')
                      : Text(
                          note.checklist.map((item) => item.text).join(' • ')))
                  : Text(note.body),
              trailing: IconButton(
                tooltip: 'Delete note',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                              title: const Text('Delete this memory?'),
                              content: const Text(
                                  'This removes the note from this device.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Keep')),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'))
                              ]));
                  if (confirmed == true) {
                    try {
                      await ref
                          .read(ordinaryNotesProvider.notifier)
                          .delete(note.id);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Could not delete. Your note is still here.')));
                      }
                    }
                  }
                },
              ),
              onTap: () => Navigator.of(context, rootNavigator: true)
                  .push<void>(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => NoteEditorPage(
                            date: selectedDate,
                            kind: note.kind,
                            initial: note,
                          ))),
            ),
          ),
        const SizedBox(height: 20),
      ],
      if (!const bool.fromEnvironment('UI_REFERENCE_REVIEW'))
        Text('Choose a format', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ResponsiveCardGrid(children: [
        for (final item in entries)
          Card(
              key: ValueKey('format-${item.key}'),
              color: Theme.of(context)
                  .extension<ScrapbookPalette>()!
                  .colors[entries.indexOf(item)],
              child: _FormatTile(
                icon: item.value,
                title: item.key,
                onTap: () => switch (item.key) {
                  'Journal / Note' => Navigator.of(context, rootNavigator: true)
                      .push<void>(MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => NoteEditorPage(
                              date: selectedDate, kind: NoteKind.journal))),
                  'Checklist / To-do' =>
                    Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => NoteEditorPage(
                                date: selectedDate, kind: NoteKind.checklist))),
                  'Schedule' => context.push<void>('/schedule'),
                  _ => context.push<void>('/focus/setup'),
                },
              ))
      ]),
      const SizedBox(height: 4),
      const StepPlanner(),
    ]);
  }
}

class _FormatTile extends StatefulWidget {
  const _FormatTile(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final Future<dynamic> Function() onTap;
  @override
  State<_FormatTile> createState() => _FormatTileState();
}

class _FormatTileState extends State<_FormatTile> {
  bool busy = false;
  Future<void> open() async {
    if (busy) return;
    busy = true;
    try {
      await widget.onTap();
    } finally {
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final title = widget.title;
    return InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon,
                      size: 22, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Text(
                  switch (title) {
                    'Journal / Note' => 'Journal',
                    'Checklist / To-do' => 'Checklist',
                    _ => title
                  },
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  switch (title) {
                    'Journal / Note' => 'Thoughts & memories',
                    'Checklist / To-do' => 'To-do, shopping, packing',
                    'Schedule' => 'Plan a time & place',
                    _ => 'Timer with your buddy'
                  },
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11, height: 1.2))
            ])));
  }
}
