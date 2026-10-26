import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/page_content.dart';
import '../../../app/create_navigation.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/domain/note.dart';
import '../domain/day_activity.dart';

class SelectedDayPanel extends ConsumerWidget {
  const SelectedDayPanel(
      {super.key,
      required this.date,
      required this.today,
      required this.activity});
  final DateTime date, today;
  final DayActivity activity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = ref
        .watch(ordinaryNotesProvider)
        .where((n) => DateUtils.isSameDay(n.date, date));
    final tasks = <({OrdinaryNote note, int index})>[
      for (final note
          in notes.where((_) => activity.entries.any((e) => e.checklist)))
        for (var i = 0; i < note.checklist.length; i++) (note: note, index: i)
    ].take(3).toList();
    final done = tasks.where((t) => t.note.checklist[t.index].done).length;
    return ScrapbookPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
          onTap: () => context.push('/day'),
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                  DateUtils.isSameDay(date, today)
                      ? 'TODAY - ${DateFormat('EEE d').format(date).toUpperCase()}'
                      : DateFormat.MMMMEEEEd().format(date),
                  key: const Key('selected-date'),
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant)))),
      const SizedBox(height: 12),
      for (final entry
          in activity.entries.where((e) => !e.checklist && !e.scheduled))
        ActivityTile(
            icon: Icons.photo_outlined,
            title: entry.title,
            subtitle: entry.preview),
      if (activity.entries.any((e) => e.checklist || e.scheduled)) ...[
        const Divider(height: 20),
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                  tasks.isEmpty
                      ? "Today's lists"
                      : 'Top 3 - $done of ${tasks.length}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              TextButton.icon(
                  onPressed: () => openCreatePage(context),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Break down')),
            ]),
        if (tasks.isEmpty)
          for (final entry in activity.entries.where((e) => e.checklist))
            ActivityTile(
                icon: Icons.checklist,
                title: entry.title,
                subtitle: entry.preview),
        for (final task in tasks)
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(task.note.checklist[task.index].text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: task.note.checklist[task.index].done
                          ? TextDecoration.lineThrough
                          : null)),
              value: task.note.checklist[task.index].done,
              onChanged: (value) async {
                final old = task.note;
                final updated = [...old.checklist];
                updated[task.index] = ChecklistItem(
                    text: updated[task.index].text, done: value ?? false);
                try {
                  await ref
                      .read(ordinaryNotesProvider.notifier)
                      .save(old.withChecklist(updated));
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Could not update this task. Please try again.')));
                  }
                }
              }),
        for (final entry in activity.entries.where((e) => e.scheduled))
          ActivityTile(
              icon: Icons.event_outlined,
              title: entry.title,
              subtitle: entry.preview,
              onTap: () => context.push('/schedule?id=${entry.scheduleId}')),
      ],
      if (activity.empty)
        const EmptyPanel(
            icon: Icons.edit_note,
            title: 'A fresh page awaits',
            message: 'A little thought, a small plan, a moment to remember.'),
    ]));
  }
}
