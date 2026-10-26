import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/journal_character.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../app/create_navigation.dart';
import '../../memories/demo_memories.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/presentation/note_detail_page.dart';
import '../../planner/data/planner_store.dart';
import '../../planner/domain/planner.dart';
import '../data/demo_calendar.dart';

class DayDetailPage extends ConsumerWidget {
  const DayDetailPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final t = Theme.of(context);
    final notes = ref
        .watch(ordinaryNotesProvider)
        .where((n) => DateUtils.isSameDay(n.date, date));
    final planner = ref.watch(plannerProvider);
    final sessions =
        planner.focusRecords.where((s) => DateUtils.isSameDay(s.date, date));
    final activities =
        ref.watch(calendarActivityProvider)[DateUtils.dateOnly(date)];
    void shift(int amount) => ref.read(selectedDateProvider.notifier).state =
        DateTime(date.year, date.month, date.day + amount);
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'Back to calendar',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/calendar'),
                icon: const Icon(Icons.chevron_left)),
            actions: [
              IconButton(
                  tooltip: 'Previous day',
                  onPressed: () => shift(-1),
                  icon: const Icon(Icons.chevron_left)),
              IconButton(
                  tooltip: 'Next day',
                  onPressed: () => shift(1),
                  icon: const Icon(Icons.chevron_right))
            ]),
        body: SafeArea(
            child: PageContent(children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: t.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                CircleAvatar(
                    radius: 24,
                    backgroundColor: t.colorScheme.primary,
                    foregroundColor: t.colorScheme.onPrimary,
                    child: Text('${date.day}',
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(DateFormat('EEEE, d MMM').format(date),
                          style: t.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('${notes.length} memories',
                          style: t.textTheme.bodySmall)
                    ])),
                const JournalCharacter(width: 48, height: 56)
              ])),
          const SizedBox(height: 12),
          for (final n in notes) ...[
            ScrapbookPanel(
                child: ActivityTile(
                    icon: n.hasChecklist
                        ? Icons.checklist
                        : Icons.menu_book_outlined,
                    title: n.title,
                    subtitle: n.hasChecklist
                        ? '${n.checklist.where((i) => i.done).length} of ${n.checklist.length} done'
                        : n.body,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => NoteDetailPage(note: n))))),
            const SizedBox(height: 8)
          ],
          if (sessions.isNotEmpty) ...[
            ScrapbookPanel(
                child: ActivityTile(
                    icon: Icons.timer_outlined,
                    title: 'Focus',
                    subtitle:
                        '${sessions.length} sessions - ${FocusRecord.durationLabel(sessions.fold(0, (sum, r) => sum + r.elapsedSeconds))}')),
            const SizedBox(height: 8)
          ],
          for (final s in planner.schedules.where((s) => s.occursOn(date))) ...[
            ScrapbookPanel(
                child: ActivityTile(
                    icon: Icons.event_outlined,
                    title: s.title,
                    subtitle: '${s.timeRange}\n${s.notes}',
                    onTap: () => context.push('/schedule?id=${s.id}'))),
            const SizedBox(height: 8)
          ],
          if (notes.isEmpty &&
              sessions.isEmpty &&
              !planner.schedules.any((s) => s.occursOn(date)))
            EmptyPanel(
                icon: Icons.auto_stories_outlined,
                title: 'A day of your own',
                message: activities?.entries.isNotEmpty == true
                    ? 'The calendar includes sample indicators. Add your own memory to begin.'
                    : 'Write a thought or plan one small thing.')
        ])),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: () => context.push('/story'),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('Share this day'))),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                      tooltip: 'Create for this day',
                      onPressed: () => openCreatePage(context),
                      icon: const Icon(Icons.add))
                ]))));
  }
}
