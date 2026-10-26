import 'archive_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/design/scrapbook_palette.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/note_detail_page.dart';
import '../../planner/data/planner_store.dart';
import '../../planner/presentation/schedule_symbols.dart';

final archiveRangeProvider =
    StateProvider<ArchiveRange>((ref) => const ArchiveRange(null, null));

final searchQueryProvider = StateProvider<String>((ref) => '');
final archiveFilterProvider = StateProvider<String>((ref) => 'All');

class _ArchiveItem {
  const _ArchiveItem(
      this.date, this.title, this.preview, this.label, this.icon, this.onTap);
  final DateTime date;
  final String title, preview, label;
  final IconData icon;
  final VoidCallback onTap;
}

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim().toLowerCase();
    final filter = ref.watch(archiveFilterProvider);
    final notes = ref.watch(ordinaryNotesProvider).where((n) =>
        (filter == 'All' ||
            filter == 'Journal' && n.kind != NoteKind.checklist ||
            filter == 'Lists' && n.hasChecklist) &&
        [n.title, n.body, ...n.checklist.map((t) => t.text)]
            .join(' ')
            .toLowerCase()
            .contains(query));
    final schedules = ref.watch(plannerProvider).schedules.where((s) =>
        (filter == 'All' || filter == 'Schedule') &&
        '${s.title} ${s.location} ${s.notes}'.toLowerCase().contains(query));
    final items = <_ArchiveItem>[
      for (final note in notes)
        _ArchiveItem(
            note.date,
            note.title,
            note.hasChecklist
                ? '${note.checklist.where((t) => t.done).length} of ${note.checklist.length} done'
                : note.body,
            note.hasChecklist ? 'List' : 'Journal',
            note.hasChecklist ? Icons.checklist : Icons.menu_book_outlined,
            () => Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)))),
      for (final s in schedules)
        _ArchiveItem(
            s.date,
            s.title,
            '${s.timeRange}${s.location.isEmpty ? '' : ' · ${s.location}'}',
            'Schedule',
            scheduleSymbols[s.symbol] ?? Icons.event_outlined,
            () => context.push('/schedule?id=${s.id}')),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final range = ref.watch(archiveRangeProvider);
    final allDates = items.map((n) => n.date).toList();
    items.removeWhere((item) => !range.contains(item.date));
    final dates = items.map((n) => DateUtils.dateOnly(n.date)).toSet();
    return PageContent(children: [
      const ScrapbookHeader(
          title: 'Memories', subtitle: 'Every day you showed up, in one place'),
      Row(children: [
        Expanded(
            child: TextFormField(
                initialValue: ref.read(searchQueryProvider),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search your memories...',
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerLowest))),
        const SizedBox(width: 8),
        IconButton.filledTonal(
            tooltip: 'Filter by date',
            onPressed: () async {
              final next = await showArchiveRange(context, range, allDates);
              if (next != null) {
                ref.read(archiveRangeProvider.notifier).state = next;
              }
            },
            style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerLowest),
            icon: const Icon(Icons.calendar_today_outlined)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        for (final name in ['All', 'Journal', 'Lists', 'Schedule'])
          ChoiceChip(
              label: Text(name),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLowest,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                  color: filter == name
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700),
              selected: filter == name,
              onSelected: (_) =>
                  ref.read(archiveFilterProvider.notifier).state = name)
      ]),
      const SizedBox(height: 12),
      if (items.isEmpty)
        const EmptyPanel(
            icon: Icons.book_outlined,
            title: 'A fresh start',
            message: 'Your memories and plans will appear here.'),
      for (final date in dates) ...[
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(DateFormat('EEE, d MMM').format(date).toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall)),
        for (final item
            in items.where((n) => DateUtils.isSameDay(n.date, date)))
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                  child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).extension<ScrapbookPalette>()!.colors[
                                            item.label == 'List'
                                                ? 1
                                                : item.label == 'Schedule'
                                                    ? 2
                                                    : 4],
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(item.icon, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(item.preview,
                                      maxLines: MediaQuery.textScalerOf(context)
                                                  .scale(14) >
                                              20
                                          ? 2
                                          : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  if (MediaQuery.textScalerOf(context)
                                          .scale(14) >
                                      20) ...[
                                    const SizedBox(height: 6),
                                    _TypeBadge(label: item.label)
                                  ],
                                ])),
                            if (MediaQuery.textScalerOf(context).scale(14) <=
                                20) ...[
                              const SizedBox(width: 8),
                              _TypeBadge(label: item.label)
                            ],
                          ]))))),
      ],
    ]);
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Theme.of(context).extension<ScrapbookPalette>()!.colors[
              label == 'List'
                  ? 1
                  : label == 'Schedule'
                      ? 2
                      : 0],
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w800)));
}
