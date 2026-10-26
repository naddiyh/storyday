import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/design/scrapbook_palette.dart';
import '../../../core/utils/journal_stats.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/responsive_card_grid.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/domain/note.dart';
import '../../planner/data/planner_store.dart';
import '../../planner/domain/planner.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final notes = ref
        .watch(ordinaryNotesProvider)
        .where((n) => n.date.year == now.year && n.date.month == now.month)
        .toList();
    final planner = ref.watch(plannerProvider);
    final focus = planner.focusRecords
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();
    final seconds = focus.fold<int>(0, (sum, r) => sum + r.elapsedSeconds);
    final tasks = notes.expand((n) => n.checklist).where((t) => t.done).length;
    final journals = notes.where((n) => n.kind != NoteKind.checklist).length;
    final lists = notes.where((n) => n.hasChecklist).length;
    final streak =
        bestStreak([...notes.map((n) => n.date), ...focus.map((r) => r.date)]);
    final scheduledDays = List.generate(
            DateTime(now.year, now.month + 1, 0).day,
            (i) => DateTime(now.year, now.month, i + 1))
        .where((day) => planner.schedules.any((s) => s.occursOn(day)))
        .length;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PageContent(children: [
      ScrapbookHeader(
          title: '${DateFormat.MMMM().format(now)} Recap',
          subtitle: 'Look how much you did this month'),
      ResponsiveCardGrid(children: [
        _Stat(
            label: 'Tasks done',
            value: '$tasks',
            caption: 'From saved checklists',
            palette: 1),
        _Stat(
            label: 'Focus time',
            value: FocusRecord.durationLabel(seconds),
            caption: '${focus.length} sessions',
            palette: 3),
        _Stat(
            label: 'Journal entries',
            value: '$journals',
            caption: 'plus $lists lists',
            palette: 0),
        _Stat(
            label: 'Best streak',
            value: '$streak ${streak == 1 ? 'day' : 'days'}',
            caption: 'Days you showed up',
            palette: 2),
      ]),
      const SizedBox(height: 6),
      ScrapbookPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Your focus this month',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
            '${focus.length} completed ${focus.length == 1 ? 'session' : 'sessions'} · $scheduledDays scheduled days',
            style: theme.textTheme.bodySmall),
        for (final r in focus.reversed.take(3))
          ActivityTile(
              icon: Icons.timer_outlined,
              title: r.task,
              subtitle: FocusRecord.durationLabel(r.elapsedSeconds)),
        if (focus.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  'A small start counts. Your completed sessions will appear here.',
                  style: theme.textTheme.bodySmall)),
        if (notes.isNotEmpty) ...[
          const Divider(),
          Text('Selected memories', style: theme.textTheme.titleSmall),
          for (final note in notes.take(2))
            ActivityTile(
                icon: Icons.menu_book_outlined,
                title: note.title,
                subtitle: note.body.isEmpty ? 'Checklist' : note.body),
        ],
      ])),
      const SizedBox(height: 16),
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: colors.onSurface, borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 16, color: colors.inversePrimary),
              const SizedBox(width: 8),
              Text('YOUR MONTH',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.surface, fontWeight: FontWeight.w800))
            ]),
            const SizedBox(height: 8),
            Text(
                'You made room for $journals journal entries and ${focus.length} focus sessions. Every small step counts.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.surface)),
          ])),
      const SizedBox(height: 16),
      FilledButton.icon(
          icon: const Icon(Icons.ios_share, size: 20),
          label: const Text('Share to Status'),
          onPressed: () => context.push('/story')),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label,
      required this.value,
      required this.caption,
      required this.palette});
  final String label, value, caption;
  final int palette;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.extension<ScrapbookPalette>()!.colors[palette],
            borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.8)),
          const SizedBox(height: 4),
          Text(caption,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ]));
  }
}
